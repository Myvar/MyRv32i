
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

    //line from stall unit
    input wire i_stall,

    input Opcode i_opcode,
    input wire [31:0] i_imm,

    input wire [DW-1:0] i_rs1,
    input wire [DW-1:0] i_rs2,

    output o_rd_write,
    input wire [DW-1:0] o_rd,

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



endmodule
