
`timescale 1ns / 1ps
//
`default_nettype none
//
`include "opcode.svh"


module decode #(
    parameter int AW = 32,
    parameter int DW = 32
) (

    input wire i_clk,
    input wire i_clk_en,
    input wire i_rst,

    //line from stall unit
    input wire i_stall,
    input wire i_wait,

    input wire [31:0] i_inst,

    output Opcode o_opcode,
    output reg [4:0] o_rs1,
    output reg [4:0] o_rs2,
    output reg [4:0] o_rd,
    output reg [31:0] o_imm,
    output reg o_wait_next
);


  wire [4:0] rs2 = i_inst[24:20];
  wire [4:0] rs1 = i_inst[19:15];
  wire [4:0] rd = i_inst[11:7];
  wire [6:0] opcode = i_inst[6:0];

  always_ff @(posedge i_clk)
    if (i_rst) begin
      o_rs1 <= 5'd0;
      o_rs2 <= 5'd0;
      o_rd <= 5'd0;
      o_wait_next <= 1'b1;
    end else if (i_clk_en)
      if (!i_stall && !i_wait) begin
        o_rs1 <= rs1;
        o_rs2 <= rs2;
        o_rd <= rd;
        o_wait_next <= 1'b0;
      end else begin
        o_wait_next <= 1'b1;
      end

  always_ff @(posedge i_clk)
    if (i_rst) begin
      o_imm <= 32'd0;
    end else if (i_clk_en)
      if (!i_stall && !i_wait) begin
        case (opcode)
          7'b0110011: o_imm <= 32'b0;
          7'b0010011: o_imm <= {{20{i_inst[31]}}, i_inst[31:20]};
          7'b0000011: o_imm <= {{20{i_inst[31]}}, i_inst[31:20]};
          7'b0100011: o_imm <= {{20{i_inst[31]}}, i_inst[31:25], i_inst[11:7]};
          7'b1100011:
          o_imm <= {
            funct3 == 3'h6 || funct3 == 3'h7 ? 19'b0 : {19{i_inst[31]}},
            i_inst[31],
            i_inst[7],
            i_inst[30:25],
            i_inst[11:8],
            1'b0
          };
          7'b1101111:
          o_imm <= {{11{i_inst[31]}}, i_inst[31], i_inst[19:12], i_inst[20], i_inst[30:21], 1'b0};
          7'b1100111: o_imm <= {{20{i_inst[31]}}, i_inst[31:20]};
          7'b0110111: o_imm <= {i_inst[31:12], 12'b0};
          7'b0010111: o_imm <= {i_inst[31:12], 12'b0};
          7'b1110011: o_imm <= {{20{i_inst[31]}}, i_inst[31:20]};
          default: o_imm <= 32'd0;
        endcase
      end

  wire [6:0] funct7 = i_inst[31:25];
  wire [2:0] funct3 = i_inst[14:12];


  // first combine the opcode and func3/7
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      o_opcode <= OP_NO_OP;
    end else if (i_clk_en) begin
      if (!i_stall && !i_wait) begin
        case (opcode)
          7'b0110011:  // R-type instructions
          case (funct3)
            3'h0: o_opcode <= (funct7 == 7'h20) ? OP_SUB : OP_ADD;
            3'h4: o_opcode <= OP_XOR;
            3'h6: o_opcode <= OP_OR;
            3'h7: o_opcode <= OP_AND;
            3'h1: o_opcode <= OP_SLL;
            3'h5: o_opcode <= (funct7 == 7'h20) ? OP_SRA : OP_SRL;
            3'h2: o_opcode <= OP_SLT;
            3'h3: o_opcode <= OP_SLTU;
            default: o_opcode <= OP_NO_OP;
          endcase
          7'b0010011:  // I-type ALU instructions
          case (funct3)
            3'h0: o_opcode <= OP_ADDI;
            3'h4: o_opcode <= OP_XORI;
            3'h6: o_opcode <= OP_ORI;
            3'h7: o_opcode <= OP_ANDI;
            3'h1: o_opcode <= OP_SLLI;
            3'h5: o_opcode <= (funct7 == 7'h20) ? OP_SRAI : OP_SRLI;
            3'h2: o_opcode <= OP_SLTI;
            3'h3: o_opcode <= OP_SLTIU;
            default: o_opcode <= OP_NO_OP;
          endcase
          7'b0000011:  // Load instructions
          case (funct3)
            3'h0: o_opcode <= OP_LB;
            3'h1: o_opcode <= OP_LH;
            3'h2: o_opcode <= OP_LW;
            3'h4: o_opcode <= OP_LBU;
            3'h5: o_opcode <= OP_LHU;
            default: o_opcode <= OP_NO_OP;
          endcase
          7'b0100011:  // Store instructions
          case (funct3)
            3'h0: o_opcode <= OP_SB;
            3'h1: o_opcode <= OP_SH;
            3'h2: o_opcode <= OP_SW;
            default: o_opcode <= OP_NO_OP;
          endcase
          7'b1100011:  // Branch instructions
          case (funct3)
            3'h0: o_opcode <= OP_BEQ;
            3'h1: o_opcode <= OP_BNE;
            3'h4: o_opcode <= OP_BLT;
            3'h5: o_opcode <= OP_BGE;
            3'h6: o_opcode <= OP_BLTU;
            3'h7: o_opcode <= OP_BGEU;
            default: o_opcode <= OP_NO_OP;
          endcase
          7'b1101111: o_opcode <= OP_JAL;  // J-type jump
          7'b1100111: o_opcode <= OP_JALR;  // JALR instruction
          7'b0110111: o_opcode <= OP_LUI;  // U-type LUI
          7'b0010111: o_opcode <= OP_AUIPC;  // U-type AUIPC
          7'b1110011:  // System instructions
          case (funct3)
            3'h0:
            case (funct7)
              7'h0: o_opcode <= OP_ECALL;
              7'h1: o_opcode <= OP_EBREAK;
              default: o_opcode <= OP_NO_OP;
            endcase
            default: o_opcode <= OP_NO_OP;
          endcase
          default: o_opcode <= OP_NO_OP;
        endcase
      end
    end
  end


endmodule
