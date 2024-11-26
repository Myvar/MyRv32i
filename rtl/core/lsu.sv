
/*
* The goal of this module is to do all the load and store operations from mem
* and regs, this modules does not handel any of the word alignment code
* that will be handel by a seprate module
*/

`timescale 1ns / 1ps
//
`default_nettype none
//
`include "opcode.svh"


module lsu #(
    parameter int AW = 32,
    parameter int DW = 32
) (

    input wire i_clk,
    input wire i_clk_en,
    input wire i_rst,

    input wire i_pc_inc,

    //line from stall unit
    input wire i_stall,

    input Opcode i_opcode,
    input wire [31:0] i_imm,

    input wire [DW-1:0] i_rs1,
    input wire [DW-1:0] i_rs2,

    output o_rd_write,
    output wire [DW-1:0] o_rd,

    // LSU Read Port
    output wire o_lsu_read,
    output wire [AW-1:0] o_r_lsu_addr,
    input reg [DW-1:0] i_r_lsu_data,
    input reg i_lsu_ack,

    // LSU Write Port
    output wire o_lsu_write,
    output wire [AW-1:0] o_w_lsu_addr,
    output wire [3:0] o_w_lsu_byte_en,
    output wire [DW-1:0] o_w_lsu_data
);

  reg done;

  //Stage one read
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      //todo reset state
      done <= 1'b0;

    end else if (i_clk_en && !done) begin
      case (i_opcode)
        //rd = M[rs1+imm][0:7]
        OP_LB: begin
          if (i_lsu_ack) begin
            done <= 1'b1;
            o_rd_write <= 1'b1;
            o_rd <= {{24{i_r_lsu_data[7]}}, i_r_lsu_data[7:0]};
            o_lsu_read <= 1'b0;
          end else begin
            o_rd_write   <= 1'b0;
            o_r_lsu_addr <= i_rs1 + i_imm;
            o_lsu_read   <= 1'b1;
          end
        end
        OP_LH:  ;
        OP_LW:  ;
        OP_LBU: ;
        OP_LHU: ;
        OP_SB:  ;
        OP_SH:  ;
        OP_SW:  ;
      endcase
    end

    if (i_pc_inc) done <= 1'b0;
  end

  //stage 2 write
  always_ff @(posedge i_clk) begin
    if (i_clk_en) begin

    end
  end

endmodule
