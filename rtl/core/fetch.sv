/*
* This module will stall if need be,
* otherwise load a rv opcode form the rom
*
*/

`timescale 1ns / 1ps
//
`default_nettype none

module fetch #(
    parameter int AW = 32,
    parameter int DW = 32
) (

    input wire i_clk,
    input wire i_clk_en,
    input wire i_rst,

    //line from stall unit
    input wire i_stall,

    input reg [AW-1:0] i_pc,
    output reg o_pc_inc,

    output wire o_fetch_read,
    output wire [AW-1:0] o_fetch_addr,
    input reg [DW-1:0] i_fetch_data,
    input reg i_fetch_ack,

    // risc-v instructions are allways 32 bit unless compressed
    output reg [31:0] o_inst,
    output reg o_wait_next
);

  //stage 1
  // 1) check for stall condition
  // 2) ask for data
  // stage 2
  // 1) read data from bus

  always_ff @(posedge i_clk)
    if (i_clk_en)
      if (!i_stall && !i_fetch_ack) begin
        o_fetch_addr <= i_pc;
        o_fetch_read <= 1'b1;
      end else begin
        o_fetch_read <= 1'b0;
      end

  reg ack;

  always_ff @(posedge i_clk) ack <= i_fetch_ack;
  always_ff @(posedge i_clk)
    if (i_clk_en) begin
      o_wait_next <= 1'b1;
      if (!i_fetch_ack && ack) begin
        o_wait_next <= 1'b1;
        o_inst <= i_fetch_data;
        o_pc_inc <= 1'b1;
      end else begin
        o_wait_next <= 1'b0;
        o_pc_inc <= 1'b0;
      end
    end







endmodule
