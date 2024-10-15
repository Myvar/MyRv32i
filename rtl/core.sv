`timescale 1ns / 1ps

`include "types.svh"

module core #(
    ADDR_WIDTH = 31,
    DATA_WIDTH = 31
) (
    input clk,
    input clk_en,
    input rst,

    // RAM
    output [ADDR_WIDTH:0] o_read_fetch_addr,
    input  [DATA_WIDTH:0] i_read_fetch_data,

    output bit o_read_req,
    output [ADDR_WIDTH:0] o_read_addr,
    input [DATA_WIDTH:0] i_read_data,
    //input  i_read_ready, // wait untill read is ready

    output bit o_write_enable,
    output bit [3:0] o_byte_enable,
    output [ADDR_WIDTH:0] o_write_addr,
    output bit [DATA_WIDTH:0] o_write_data,

    output logic o_ebreak
);

  reg [31:0] pc;

  wire [31:0] instruction;

  wire valid_decoder_output;

  wire  [ 6:0] opcode;
  wire  [ 7:0] funct7;
  wire  [ 2:0] funct3;
  wire  [ 4:0] rs1;
  wire  [ 4:0] rs2;
  wire  [ 4:0] rd;
  wire  [31:0] imm;

  logic [ 4:0] regs_write_addr;
  logic [DATA_WIDTH:0] regs_write_data;
  logic regs_write_en;


  wire  [ 4:0] regs_a_addr;
  wire  [DATA_WIDTH:0] regs_a_data;

  wire  [ 4:0] regs_b_addr;
  wire  [DATA_WIDTH:0] regs_b_data;

  wire [DATA_WIDTH:0] alu_out_data;

  bit [31:0] pc_jump;
  jump_mode_e jump_mode;

  wire invalid_instruction = ~(|instruction) | ~valid_decoder_output;

  always_comb begin
    case (opcode)
      7'b1100011: unique case (funct3)
        3'h0: jump_mode = regs_a_data == regs_b_data ? JM_RELATIVE : JM_NEXT; // BEQ
        3'h1: jump_mode = regs_a_data != regs_b_data ? JM_RELATIVE : JM_NEXT; // BNE
        3'h4: jump_mode = $signed(regs_a_data) < $signed(regs_b_data) ? JM_RELATIVE : JM_NEXT; // BLT
        3'h5: jump_mode = $signed(regs_a_data) >= $signed(regs_b_data) ? JM_RELATIVE : JM_NEXT; // BGE
        3'h6: jump_mode = regs_a_data < regs_b_data ? JM_RELATIVE : JM_NEXT; // BLTU
        3'h7: jump_mode = regs_a_data >= regs_b_data ? JM_RELATIVE : JM_NEXT; // BGEU
        
        default: jump_mode = JM_NEXT;
      endcase
      7'b1101111: jump_mode = JM_RELATIVE; // JAL
      7'b1100111: jump_mode = JM_ABSOLUTE; // JALR
      default: jump_mode = JM_NEXT;
    endcase

    unique case (jump_mode)
      JM_NEXT: pc_jump = 32'b1;
      JM_RELATIVE: pc_jump = ($signed(imm) >> 2);
      JM_ABSOLUTE: pc_jump = regs_a_data + (imm >> 2);
    endcase
  end

  always_ff @(posedge clk)
    if (rst) pc <= 0;
    else if (clk_en)
      if (~invalid_instruction)
        if (jump_mode == JM_ABSOLUTE)
          pc <= pc_jump;
        else 
          pc <= pc + pc_jump;
      else $finish();

  always_ff @(posedge clk)
    case(opcode)
      7'b1110011:
        o_ebreak <= 1;
      default:
        o_ebreak <= 0;
    endcase

  //STORE
  //TODO: move into module
  always_comb begin
    if (opcode == 7'b0100011) begin
      case (funct3)
        3'b000: begin
          o_write_data   = {24'd0, regs_b_data[7:0]};
          o_byte_enable  = 4'b0001;
          o_write_enable = 1;
        end
        3'b001: begin
          o_write_data   = {16'd0, regs_b_data[15:0]};
          o_byte_enable  = 4'b0011;
          o_write_enable = 1;
        end
        3'b010: begin
          o_write_data   = regs_b_data[31:0];
          o_byte_enable  = 4'b1111;
          o_write_enable = 1;
        end
        default: begin
          o_write_data   = 32'd0;
          o_byte_enable  = 4'b0000;
          o_write_enable = 0;
        end
      endcase
    end else begin
      o_write_data   = 32'd0;
      o_byte_enable  = 4'b0000;
      o_write_enable = 0;
    end
  end

  assign regs_a_addr = rs1;
  assign o_write_addr = regs_a_data + imm;

  assign regs_b_addr = rs2;
  assign o_read_addr= regs_a_data + imm;
  
  assign regs_write_addr  = rd;

  //LOAD
  always_comb begin
    case (opcode)
      7'b0000011: begin // Load
        o_read_req = 1;
        regs_write_en = 1;

        case (funct3)
          // Sign-extend byte to 32 bits 
          3'b000: regs_write_data = {{24{i_read_data[7]}}, i_read_data[7:0]}; // LB
          3'b001: regs_write_data = {{16{i_read_data[15]}}, i_read_data[15:0]}; // LH
          3'b010: regs_write_data = i_read_data; // LW
          3'b100: regs_write_data = {24'd0, i_read_data[7:0]}; // LBU
          3'b101: regs_write_data = {16'd0, i_read_data[15:0]}; // LHU
          default: begin
            regs_write_en = 0;
            regs_write_data = 32'd0;
          end
        endcase
      end
      7'b0110011: begin // from ALU
        o_read_req = 1;
        regs_write_en = 1;
        regs_write_data = alu_out_data;
        end
      7'b0010011: begin // from ALU i
        o_read_req = 1;
        regs_write_en = 1;
        regs_write_data = alu_out_data;
      end
      7'b0110111: begin // LUI
        o_read_req = 1;
        regs_write_en = 1;
        regs_write_data = imm;
      end
      7'b0010111: begin // AUIPC
        o_read_req = 1;
        regs_write_en = 1;
        regs_write_data = (pc << 2) + imm;
      end
      7'b1101111: begin // JAL
        o_read_req = 1;
        regs_write_en = 1;
        regs_write_data = (pc << 2);
      end
      7'b1100111: begin // JALR
        o_read_req = 1;
        regs_write_en = 1;
        regs_write_data = (pc << 2);
      end
      default: begin
        o_read_req = 0;
        regs_write_en = 0;
        regs_write_data = 32'd0;
		  end
    endcase
  end

  regs u_regs (
    .clk(clk),
    .clk_en(clk_en),
    .rst(rst),

    .i_write_addr(regs_write_addr),
    .i_write_data(regs_write_data),
    .i_write_en(regs_write_en),

    .i_a_addr(regs_a_addr),
    .o_a_data(regs_a_data),

    .i_b_addr(regs_b_addr),
    .o_b_data(regs_b_data)
  );

  fetch #(
    .ADDR_WIDTH(ADDR_WIDTH),
    .DATA_WIDTH(DATA_WIDTH)
  ) u_fetch (
    .clk(clk),
    .clk_en(clk_en),
    .rst(rst),

    .i_pc(pc),

    .o_read_fetch_addr(o_read_fetch_addr),
    .i_read_fetch_data(i_read_fetch_data),

    .o_instruction(instruction)
  );

  decode u_decode (
    .clk(clk),
    .clk_en(clk_en),
    .rst(rst),

    .i_instruction(instruction),
    
    .o_opcode(opcode),
    .o_funct7(funct7),
    .o_funct3(funct3),
    .o_rs1(rs1),
    .o_rs2(rs2),
    .o_rd(rd),
    .o_imm(imm),

    .o_valid(valid_decoder_output)
  );

  alu #(
    .DATA_WIDTH(DATA_WIDTH) 
  ) u_alu (
    .clk(clk),
    .clk_en(clk_en),
    .rst(rst),

    .i_opcode(opcode),
    .i_funct7(funct7),
    .i_funct3(funct3),
    .i_rs1_data(regs_a_data),
    .i_rs2_data(regs_b_data),
    .i_imm(imm),

    .o_rd_data(alu_out_data)
  );

endmodule
