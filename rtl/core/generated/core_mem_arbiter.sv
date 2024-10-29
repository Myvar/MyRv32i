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
    input [AW-1:0] i_fetch_addr,
    output [DW-1:0] o_fetch_data,

    // LSU read
    input i_lsu_read,
    input [AW-1:0] i_r_lsu_addr,
    output [DW-1:0] o_r_lsu_data,

    // LSU write
    input i_lsu_write,
    input [AW-1:0] i_w_lsu_addr,
    input [3:0] i_w_lsu_byte_en,
    input [DW-1:0] i_w_lsu_data,

    // debug read
    input i_deubg_read,
    input [AW-1:0] i_r_debug_addr,
    output [DW-1:0] o_r_debug_data,

    // debug write
    input i_debug_write,
    input [AW-1:0] i_w_debug_addr,
    input [3:0] i_w_debug_byte_en,
    input [DW-1:0] i_w_debug_data
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


// Segments

// 1) a) Figure out what port has control
/*
    first is the LSU port
    second is the Fetch port
    third is the debug port
*/
typedef enum reg [2:0] {
    PORT_LSU,
    PORT_FETCH,
    PORT_DEBUG
} Port;

Port src_port;
reg [AW-1:0] src_addr;

// Segment 1
always_ff @(posedge i_clk)
    if (i_rst)
        src_port <= PORT_LSU;
    else
        if (i_clk_en)
            if(i_lsu_read) begin
                src_port <= PORT_LSU;
                src_addr <= i_r_lsu_addr;
            end
            else if(i_lsu_write) begin
                src_port <= PORT_LSU;
                src_addr <= i_w_lsu_addr;
            end
            else if(i_fetch_read) begin // fetch will only ever read
                src_port <= PORT_FETCH;
                src_addr <= i_fetch_addr;
            end
            else if(i_deubg_read) begin
                src_port <= PORT_DEBUG;
                src_addr <= i_r_debug_addr;
            end
            else if(i_debug_write) begin
                src_port <= PORT_DEBUG;
                src_addr <= i_w_debug_addr;
            end
            else begin
                src_port <= PORT_LSU;
                src_addr <= 0;
            end



// 1) b) calcualte offsets for every port

typedef enum reg [2:0] {
    T_PORT_ROM,
    T_PORT_LRAM
} TargetPort;

TargetPort target_port;
reg [AW-1:0] target_addr;

// Segment 1
always_ff @(posedge i_clk)
    if (i_rst) begin
        target_port <= 0;
        target_addr <= 0;
    end else
        if (i_clk_en)
            if(src_addr <= 512) begin
                target_port <= T_PORT_ROM;
                target_addr <= 512 - src_addr;
            end
            else if(src_addr <= 4096) begin
                target_port <= T_PORT_LRAM;
                target_addr <= 4096 - src_addr;
            end


// 2) (de)mux port to target

endmodule
