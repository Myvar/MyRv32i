`timescale 1ns / 1ps
//
`default_nettype none
//
`include "opcode.svh"


module execute #(
    parameter int AW = 32,
    parameter int DW = 32
) (

    domain_if domain,
    input wire i_pc_inc,

    //line from stall unit
    input wire i_stall,

    input Opcode i_opcode,
    input wire [31:0] i_imm,

    input wire [DW-1:0] i_rs1,
    input wire [DW-1:0] i_rs2,

    output o_rd_write,
    output wire [DW-1:0] o_rd,
    output o_busy,

    bus_if.master bus
);

  wire lsu_rd_write;
  wire [DW-1:0] lsu_rd;


  wire alu_rd_write;
  wire [DW-1:0] alu_rd;

  wire stall = i_stall;
  // so we can OR gate future execute modules
  assign o_rd_write = lsu_rd_write | alu_rd_write;
  assign o_rd = lsu_rd | alu_rd;


  alu #(
      .AW(AW),
      .DW(DW)
  ) u_alu (
      .domain,
      //line from stall unit
      .i_stall(stall),

      .i_opcode(i_opcode),
      .i_imm(i_imm),

      .i_rs1(i_rs1),
      .i_rs2(i_rs2),

      .o_rd_write(alu_rd_write),
      .o_rd(alu_rd)
  );

  lsu #(
      .AW(AW),
      .DW(DW)
  ) u_lsu (
      //line from stall unit
      .i_stall(stall),

      .i_opcode(i_opcode),
      .i_imm(i_imm),

      .i_rs1(i_rs1),
      .i_rs2(i_rs2),

      .o_rd_write(lsu_rd_write),
      .o_rd(lsu_rd),
      .o_busy,
      .bus
  );

endmodule
