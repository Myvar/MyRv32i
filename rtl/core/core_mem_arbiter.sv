`timescale 1ns / 1ps
`default_nettype none

module core_mem_arbiter #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    input i_clk,
    input i_clk_en,
    input i_rst,

    output o_stall,

    // we have 3 ports
    // Fetch Read
    input i_fetch_read,
    output [AW-1:0] o_fetch_addr,
    output [DW-1:0] o_fetch_data,

    // LSU read
    input i_lsu_read,
    output [AW-1:0] o_r_lsu_addr,
    output [DW-1:0] o_r_lsu_data,

    // LSU write
    input i_lsu_write,
    output [AW-1:0] o_w_lsu_addr,
    output [3:0] o_w_lsu_byte_en,
    output [DW-1:0] o_w_lsu_data,

    // debug read
    input i_deubg_read,
    output [AW-1:0] o_r_debug_addr,
    output [DW-1:0] o_r_debug_data,

    // debug write
    input i_debug_write,
    output [AW-1:0] o_w_debug_addr,
    output [3:0] o_w_debug_byte_en,
    output [DW-1:0] o_w_debug_data
);

//local ram
wire [AW-1:0] local_read_addr;
wire [DW-1:0] local_read_data;

wire local_write_en;
wire [3:0] local_byte_en;
wire [AW-1:0] local_write_addr;
wire [DW-1:0] local_write_data;

//local rom
wire [AW-1:0] rom_read_addr;
wire [DW-1:0] rom_read_data;

assign o_stall = i_fetch_read || i_lsu_read || i_deubg_read;

// first lsu
// then fetch
// then debug

local_rom #(
    .ADDR_WIDTH(AW),
    .DATA_WIDTH(DW)
) u_local_rom (
    .i_clk(i_clk),
    .i_clk_en(i_clk_en),
    .i_rst(i_rst),

    .i_read_addr(rom_read_addr),
    .o_read_data(rom_read_data)
);


local_ram #(
    .ADDR_WIDTH(AW),
    .DATA_WIDTH(DW),
    .ADDR_COUNT(4096)
) u_local_ram (
    .i_clk(i_clk),
    .i_clk_en(i_clk_en),
    .i_rst(i_rst),

    //Read
    .i_read_addr(local_read_addr),
    .o_read_data(local_read_data),

    // Write
    .i_write_en(local_write_en),
    .i_byte_en(local_byte_en),
    .i_write_addr(local_write_addr),
    .i_write_data(local_write_data)
);

endmodule