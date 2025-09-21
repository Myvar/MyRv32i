interface bus_if #(
    parameter int AW = 32,
    parameter int DW = 32,
    parameter int BW = 8
);
  //we do not use domain clock so that bus can happen at its own clock speed
  logic               clk;
  logic               reset;

  logic [     AW-1:0] address;
  logic               write;
  logic               read;
  logic [     DW-1:0] writedata;
  logic [     DW-1:0] readdata;
  logic [(DW/BW)-1:0] byteenable;
  logic               chipselect;
  logic               waitrequest;

  modport master(
      input clk,
      input reset,
      output address,
      output write,
      output read,
      output writedata,
      output byteenable,
      output chipselect,
      input readdata,
      input waitrequest
  );

  // Defines signal directions from the Slave's point of view
  modport slave(
      input clk,
      input reset,
      input address,
      input write,
      input read,
      input writedata,
      input byteenable,
      input chipselect,
      output readdata,
      output waitrequest
  );

endinterface
