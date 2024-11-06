`timescale 1ns / 1ps
//
`default_nettype none

module core #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    input i_clk,
    input i_clk_en,
    input i_rst
);

  // general stall lones
  wire stall_line;

  wire fetch_read;
  wire [AW-1:0] fetch_addr;
  reg [DW-1:0] fetch_data;
  reg fetch_ack;

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
      .o_fetch_ack (fetch_ack)

      /*
      // LSU Read Port
      .i_lsu_read(),
      .i_r_lsu_addr(),
      .o_r_lsu_data(),
      .o_lsu_ack(),

      // LSU Write Port
      .i_lsu_write(),
      .i_w_lsu_addr(),
      .i_w_lsu_byte_en(),
      .i_w_lsu_data(),

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
      .o_inst(inst)
  );

endmodule
