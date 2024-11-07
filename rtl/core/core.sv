`timescale 1ns / 1ps
//
`default_nettype none
//
`include "opcode.svh"


module core #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    input i_clk,
    input i_clk_en,
    input i_rst
);

  // general stall lines
  wire stall_line;

  // regs
  wire [DW-1:0] data_rs1;
  wire [DW-1:0] data_rs2;

  wire rd_write;
  wire [DW-1:0] data_rd;

  // arbiter
  wire fetch_read;
  wire [AW-1:0] fetch_addr;
  reg [DW-1:0] fetch_data;
  reg fetch_ack;


  // LSU Read Port
  wire lsu_read;
  wire [AW-1:0] r_lsu_addr;
  wire [DW-1:0] r_lsu_data;
  wire lsu_ack;

  // LSU Write Port
  wire lsu_write;
  wire [AW-1:0] w_lsu_addr;
  wire [3:0] w_lsu_byte_en;
  wire [DW-1:0] w_lsu_data;


  core_mem_arbiter #(
      .AW(AW),
      .DW(DW)
  ) u_core_mem_arbiter (
      .i_clk(i_clk),
      .i_clk_en(i_clk_en),
      .i_rst(i_rst),

      .o_stall(stall_line),

      // Fetch Read Port
      .i_fetch_read(fetch_read),
      .i_fetch_addr(fetch_addr),
      .o_fetch_data(fetch_data),
      .o_fetch_ack (fetch_ack),


      // LSU Read Port
      .i_lsu_read(lsu_read),
      .i_r_lsu_addr(r_lsu_addr),
      .o_r_lsu_data(r_lsu_data),
      .o_lsu_ack(lsu_ack),

      // LSU Write Port
      .i_lsu_write(lsu_write),
      .i_w_lsu_addr(w_lsu_addr),
      .i_w_lsu_byte_en(w_lsu_byte_en),
      .i_w_lsu_data(w_lsu_data)
      /*
      // Debug Read Port
      .i_debug_read(),
      .i_r_debug_addr(),
      .o_r_debug_data,
      .o_debug_ack(),

      // Debug Write Port
      .i_debug_write(),
      .i_w_debug_addr(),
      .i_w_debug_byte_en(),
      .i_w_debug_dat()*/
  );

  //tmp
  reg [AW-1:0] pc;
  wire pc_inc;

  reg [31:0] inst;
  always_ff @(posedge i_clk)
    if (i_clk_en)
      if (pc_inc) begin
        pc <= pc + 4;
      end

  wire decode_wait;
  wire execute_wait;

  fetch #(
      .AW(AW),
      .DW(DW)
  ) u_fetch (
      .i_clk(i_clk),
      .i_clk_en(i_clk_en),
      .i_rst(i_rst),

      //line from stall unit
      .i_stall(stall_line),

      .i_pc(pc),
      .o_pc_inc(pc_inc),

      .o_fetch_read(fetch_read),
      .o_fetch_addr(fetch_addr),
      .i_fetch_data(fetch_data),
      .i_fetch_ack (fetch_ack),

      // risc-v instructions are allways 32 bit unless compressed
      .o_inst(inst),
      .o_wait_next(decode_wait)
  );

  Opcode opcode;
  reg [4:0] rs1;
  reg [4:0] rs2;
  reg [4:0] rd;
  reg [31:0] imm;

  decode #(
      .AW(AW),
      .DW(DW)
  ) u_decode (
      .i_clk(i_clk),
      .i_clk_en(i_clk_en),
      .i_rst(i_rst),

      //line from stall unit
      .i_stall(stall_line),
      .i_wait (decode_wait),

      .i_inst(inst),

      .o_opcode(opcode),
      .o_rs1(rs1),
      .o_rs2(rs2),
      .o_rd(rd),
      .o_imm(imm),
      .o_wait_next(execute_wait)
  );


 regs u_regs (
   .i_clk(i_clk),
   .i_clk_en(i_clk_en),
   .i_rst(i_rst),

   .i_rd_addr(rs1),
   .i_rd_data(data_rd),
   .i_rd_write(rd_write),
    
   .i_rs1_addr(rs2),
   .o_rs1_data(data_rs1),
    
   .i_rs2_addr(rd),
   .o_rs2_data(data_rs2)
);


  execute #(
      .AW(AW),
      .DW(DW)
  ) u_execute (
      .i_clk(i_clk),
      .i_clk_en(i_clk_en),
      .i_rst(i_rst),

      //line from stall unit
      .i_stall(stall_line),
      .i_wait (execute_wait),

      .i_opcode(opcode),
      .i_imm(imm),

      .i_rs1(data_rs1),
      .i_rs2(data_rs2),

      .o_rd_write(rd_write),
      .o_rd(data_rd),

      // LSU Read Port
      .o_lsu_read(lsu_read),
      .o_r_lsu_addr(r_lsu_addr),
      .i_r_lsu_data(r_lsu_data),
      .i_lsu_ack(lsu_ack),

      // LSU Write Port
      .o_lsu_write(lsu_write),
      .o_w_lsu_addr(w_lsu_addr),
      .o_w_lsu_byte_en(w_lsu_byte_en),
      .o_w_lsu_data(w_lsu_data)
  );

endmodule
