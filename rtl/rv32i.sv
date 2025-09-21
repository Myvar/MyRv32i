`timescale 1ns / 1ps
//
`default_nettype none

module rv32i (
    input i_clk,
    input i_clk_en,
    input i_rst,

    //UART
    input  i_rx,
    output o_tx,

    //Booted
    output o_booted
);


  domain_if domain (
      .i_clk,
      .i_clk_en,
      .i_rst
  );

  core u_core (
      .domain,
      .o_booted
  );


`ifdef TESTING1
  always @(posedge i_clk) begin
    $display("rv32i");
  end
`endif

endmodule
