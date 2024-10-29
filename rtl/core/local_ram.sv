`timescale 1ns / 1ps
`default_nettype none

module local_ram #(
    ADDR_WIDTH = 32,
    DATA_WIDTH = 32,
    ADDR_COUNT = 1024 /* is devided by 4 for long encoding */
)(
    input i_clk,
    input i_clk_en,
    input i_rst,

    //Read
    input [ADDR_WIDTH-1:0] i_read_addr,
    output reg [DATA_WIDTH-1:0] o_read_data,


    // Write
    input i_write_en,
    input [3:0] i_byte_en,
    input [ADDR_WIDTH-1:0] i_write_addr,
    input [DATA_WIDTH-1:0] i_write_data
);

//2**ADDR_WIDTH - 1
(* ram_style = "block" *) logic [7:0] mem_a [ADDR_COUNT-1:0];
(* ram_style = "block" *) logic [7:0] mem_b [ADDR_COUNT-1:0];
(* ram_style = "block" *) logic [7:0] mem_c [ADDR_COUNT-1:0];
(* ram_style = "block" *) logic [7:0] mem_d [ADDR_COUNT-1:0];

assign o_write_uart = i_write_data[7:0];

always_ff @(posedge i_clk)
    if (i_clk_en)
        if (i_write_en)
            if (i_byte_en[0]) 
                mem_a[i_write_addr] <= i_write_data[7:0];
         

always_ff @(posedge i_clk)
    if (i_clk_en)
        if (i_write_en)
            if (i_byte_en[1])
                mem_b[i_write_addr] <= i_write_data[15:8];
 

always_ff @(posedge i_clk)
    if (i_clk_en)
        if (i_write_en)
            if (i_byte_en[2])
                mem_c[i_write_addr] <= i_write_data[23:16];


always_ff @(posedge i_clk)
    if (i_clk_en)
        if (i_write_en)
            if (i_byte_en[3])
                mem_d[i_write_addr] <= i_write_data[31:24];
 

always_ff @(posedge i_clk)
    o_read_data <= {mem_d[i_read_addr], mem_c[i_read_addr], mem_b[i_read_addr], mem_a[i_read_addr]};

always_ff @(posedge i_clk)
    o_read_fetch_data <= {mem_d[i_read_fetch_addr], mem_c[i_read_fetch_addr], mem_b[i_read_fetch_addr], mem_a[i_read_fetch_addr]};

endmodule