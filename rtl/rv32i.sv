`timescale 1ns / 1ps
`default_nettype none

module rv32i (
    input i_clk,
    input i_clk_en,
    input i_rst,

    //UART
    input i_rx,
    output o_tx,

    //Booted
    output o_booted
);
  core u_core (
    .clk(clk),
    .clk_en(booted),
    .rst(rstrst)
  );




`ifdef TESTING
  always @(posedge clk) begin
    //$display("CPU");
  end
`endif

endmodule
