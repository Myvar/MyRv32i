`timescale 1ns / 1ps
//
`default_nettype none
//
`include "opcode.svh"


module execute #(
    parameter int AW = 32,
    parameter int DW = 32
) (

    input wire i_clk,
    input wire i_clk_en,
    input wire i_rst,

    //line from stall unit
    input wire i_stall,
    input wire i_wait,

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

  wire lsu_rd_write;
  wire [DW-1:0] lsu_rd;

  wire stall = i_stall | i_wait;
  // so we can OR gate future execute modules
  assign o_rd_write = lsu_rd_write;
  assign o_rd = lsu_rd;

  lsu #(
      .AW(AW),
      .DW(DW)
  ) u_lsu (
      .i_clk(i_clk),
      .i_clk_en(i_clk_en),
      .i_rst(i_rst),

      //line from stall unit
      .i_stall(stall),

      .i_opcode(i_opcode),
      .i_imm(i_imm),

      .i_rs1(i_rs1),
      .i_rs2(i_rs2),

      .o_rd_write(lsu_rd_write),
      .o_rd(lsu_rd),

      // LSU Read Port
      .o_lsu_read(o_lsu_read),
      .o_r_lsu_addr(o_r_lsu_addr),
      .i_r_lsu_data(i_r_lsu_data),
      .i_lsu_ack(i_lsu_ack),

      // LSU Write Port
      .o_lsu_write(o_lsu_write),
      .o_w_lsu_addr(o_w_lsu_addr),
      .o_w_lsu_byte_en(o_w_lsu_byte_en),
      .o_w_lsu_data(o_w_lsu_data)
  );

endmodule
