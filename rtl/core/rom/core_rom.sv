`timescale 1ns / 1ps
`default_nettype none

module local_rom #(
    ADDR_WIDTH = 32,
    DATA_WIDTH = 32
)(
    input i_clk,
    input i_clk_en,
    input i_rst,

    input [ADDR_WIDTH-1:0] i_read_addr,
    output reg [DATA_WIDTH-1:0] o_read_data
);


always_ff @(posedge i_clk)
    if (i_clk_en)
        case (i_read_addr)
            `include "rom.svh"
        endcase


endmodule