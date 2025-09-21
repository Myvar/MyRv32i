`timescale 1ns / 1ps
//
`default_nettype none
`include "if/if.svh"

module local_rom #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    bus_if.slave bus
);

  always @(posedge bus.clk)
    if (bus.chipselect && bus.read) begin
      case (bus.address)
        `define output bus.readdata
        `include "rom.svh"
        `undef output
      endcase
    end else begin
      bus.readdata = 0;  // High-impedance when not selected
    end

  /*always_ff @(posedge i_clk)
    if (i_clk_en)
        case (i_read_addr)
            `include "rom.svh"
        endcase*/


endmodule

