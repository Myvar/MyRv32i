`timescale 1ns / 1ps
//
`default_nettype none
//
`include "opcode.svh"

`include "if/if.svh"

module core #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    domain_if domain,
    output o_booted
);

  // general stall lines
  wire stall_line;

  // regs
  wire [DW-1:0] data_rs1;
  wire [DW-1:0] data_rs2;

  wire rd_write;
  wire [DW-1:0] data_rd;

  //tmp
  reg [AW-1:0] pc;
  wire pc_inc;

  reg [31:0] inst;
  always_ff @(posedge domain.i_clk)
    if (domain.i_rst) pc <= -4;
    else if (domain.i_clk_en)
      if (pc_inc) begin
        pc <= pc + 4;
      end


  assign o_booted = pc_inc || inst > 0;

  bus_if #(
      .AW(AW),
      .DW(DW)
  ) fetch_bus ();


  bus_if #(
      .AW(AW),
      .DW(DW)
  ) lsu_bus ();

  bus_if #(
      .AW(AW),
      .DW(DW)
  ) rom_bus ();

  bus_if #(
      .AW(AW),
      .DW(DW)
  ) ram_bus ();


  bus_if #(
      .AW(AW),
      .DW(DW)
  ) foo_bus ();


  bus_if #(
      .AW(AW),
      .DW(DW)
  ) bar_bus ();

  bus_if #(
      .AW(AW),
      .DW(DW)
  ) arbiter_bus ();

  arbiter_2_to_1 arbiter (
      .m0_bus(fetch_bus.slave),
      .m1_bus(lsu_bus.slave),
      .s0_bus(arbiter_bus.master)
  );

  interconnect_1_to_4 inter (
      .m0_bus(arbiter_bus.slave),
      .s0_bus(rom_bus.master),
      .s1_bus(ram_bus.master),
      .s2_bus(foo_bus.master),
      .s3_bus(bar_bus.master)
  );

  assign arbiter_bus.clk = domain.i_clk;
  assign arbiter_bus.reset = domain.i_rst;

  assign rom_bus.clk = domain.i_clk;
  assign rom_bus.reset = domain.i_rst;

  assign ram_bus.clk = domain.i_clk;
  assign ram_bus.reset = domain.i_rst;

  assign fetch_bus.clk = domain.i_clk;
  assign fetch_bus.reset = domain.i_rst;

  assign lsu_bus.clk = domain.i_clk;
  assign lsu_bus.reset = domain.i_rst;

  assign foo_bus.clk = domain.i_clk;
  assign foo_bus.reset = domain.i_rst;

  assign bar_bus.clk = domain.i_clk;
  assign bar_bus.reset = domain.i_rst;

  local_rom #(
      .AW(AW),
      .DW(DW)
  ) rom (
      .bus(rom_bus.slave)
  );


  local_ram ram (.bus(ram_bus.slave));

  fetch #(
      .AW(AW),
      .DW(DW)
  ) u_fetch (
      .bus(fetch_bus.master),

      .i_stall(stall_line),

      .i_pc(pc),
      .o_pc_inc(pc_inc),

      .o_inst(inst)
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
      .i_clk(domain.i_clk),
      .i_clk_en(domain.i_clk_en),
      .i_rst(domain.i_rst),

      .i_stall(stall_line),

      .i_inst(inst),

      .o_opcode(opcode),
      .o_rs1(rs1),
      .o_rs2(rs2),
      .o_rd(rd),
      .o_imm(imm)
  );



  regs u_regs (
      .i_clk(domain.i_clk),
      .i_clk_en(domain.i_clk_en),
      .i_rst(domain.i_rst),

      .i_rd_addr (rd),
      .i_rd_data (data_rd),
      .i_rd_write(rd_write),

      .i_rs1_addr(rs1),
      .o_rs1_data(data_rs1),

      .i_rs2_addr(rs2),
      .o_rs2_data(data_rs2)
  );

  execute #(
      .AW(AW),
      .DW(DW)
  ) u_execute (
      .domain,

      .i_pc_inc(pc_inc),

      .i_stall(stall_line),

      .i_opcode(opcode),
      .i_imm(imm),

      .i_rs1(data_rs1),
      .i_rs2(data_rs2),

      .o_rd_write(rd_write),
      .o_rd(data_rd),

      .o_busy(stall_line),

      .bus(lsu_bus.master)
  );

endmodule
