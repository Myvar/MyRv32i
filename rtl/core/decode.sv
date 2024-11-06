
`timescale 1ns / 1ps
//
`default_nettype none

module decode #(
    parameter int AW = 32,
    parameter int DW = 32
) (

    input wire i_clk,
    input wire i_clk_en,
    input wire i_rst,

    //line from stall unit
    input wire i_stall,

    input wire [31:0] i_inst,

    output bit [ 6:0] o_opcode,
    output bit [ 4:0] o_rs1,
    output bit [ 4:0] o_rs2,
    output bit [ 4:0] o_rd,
    output bit [31:0] o_imm
);

  wire [6:0] opcode = i_instruction[6:0];

  wire [6:0] funct7 = i_instruction[31:25];
  wire [2:0] funct3 = i_instruction[14:12];
  wire [4:0] rs2 = i_instruction[24:20];
  wire [4:0] rs1 = i_instruction[19:15];
  // first combine the opcode and func3/7
  always_ff @(posedge i_clk)
    if (i_clk_en) begin

    end


endmodule
