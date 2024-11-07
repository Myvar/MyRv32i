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
    input wire [4:0] i_rs1,
    input wire [4:0] i_rs2,
    input wire [4:0] i_rd,
    input wire [31:0] i_imm,


    // LSU Read Port
    output wire i_lsu_read,
    output wire [AW-1:0] i_r_lsu_addr,
    input reg [DW-1:0] o_r_lsu_data,
    input reg o_lsu_ack,

    // LSU Write Port
    output wire i_lsu_write,
    output wire [AW-1:0] i_w_lsu_addr,
    output wire [3:0] i_w_lsu_byte_en,
    output wire [DW-1:0] i_w_lsu_data
);

  wire stall = i_stall | i_wait;


endmodule
