`timescale 1ns / 1ps
//
`default_nettype none
//
`include "if/if.svh"

module fetch #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    bus_if.master bus,

    input wire i_stall,

    input wire [AW-1:0] i_pc,

    output logic o_pc_inc,

    output reg [31:0] o_inst
);

  typedef enum logic [1:0] {
    S_IDLE,  // Ready to start a new fetch.
    S_WAIT,  // Actively fetching, waiting for the bus slave to respond.
    S_DONE   // Instruction has been received and is waiting for the pipeline to accept it.
  } state_t;

  state_t state_reg, state_next;
  wire stall = bus.waitrequest && i_stall;

  always_comb begin
    state_next     = state_reg;
    o_pc_inc       = 1'b0;
    bus.read       = 1'b0;
    bus.chipselect = 1'b0;

    if (bus.reset) state_next = S_IDLE;

    unique case (state_reg)
      S_IDLE: begin
        if (!stall) begin
          state_next     = S_WAIT;
          bus.read       = 1'b1;
          bus.chipselect = 1'b1;
        end
      end
      S_WAIT: begin
        bus.read       = 1'b1;
        bus.chipselect = 1'b1;
        if (!stall) begin
          state_next = S_DONE;
        end
      end
      S_DONE: begin
        bus.read       = 1'b0;
        bus.chipselect = 1'b0;
        if (!stall) begin
          o_pc_inc   = 1'b1;
          state_next = S_IDLE;
        end
      end
      default: begin
        state_next     = S_IDLE;
        o_pc_inc       = 1'b0;
        bus.read       = 1'b0;
        bus.chipselect = 1'b0;
      end
    endcase
  end

  always_ff @(posedge bus.clk or posedge bus.reset) begin
    if (bus.reset) begin
      state_reg <= S_IDLE;
    end else begin
      state_reg <= state_next;
    end
  end


  assign bus.address    = i_pc;
  assign bus.byteenable = 4'b1111;

  reg debug;
  always_ff @(posedge bus.clk or posedge bus.reset) begin
    debug <= 0;
    if (bus.reset) begin
      o_inst <= 32'h00000000;
    end else if (state_reg == S_DONE && !stall) begin
      o_inst <= bus.readdata;
      debug  <= 1;
    end
  end

endmodule
