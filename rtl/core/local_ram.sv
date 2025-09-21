`timescale 1ns / 1ps
//
`default_nettype none

module local_ram #(
    parameter int ADDR_WIDTH = 32,
    parameter int DATA_WIDTH = 32,
    parameter int ADDR_COUNT = 1024
) (
    bus_if.slave bus
);

  localparam int WORD_ADDR_WIDTH = $clog2(ADDR_COUNT);

  (* ram_style = "block" *) logic [7:0] mem_a[ADDR_COUNT-1:0];
  (* ram_style = "block" *) logic [7:0] mem_b[ADDR_COUNT-1:0];
  (* ram_style = "block" *) logic [7:0] mem_c[ADDR_COUNT-1:0];
  (* ram_style = "block" *) logic [7:0] mem_d[ADDR_COUNT-1:0];

  logic [WORD_ADDR_WIDTH-1:0] word_addr;
  assign word_addr = bus.address[WORD_ADDR_WIDTH+1:2];

  always_ff @(posedge bus.clk) begin
    if (bus.write && bus.byteenable[0]) begin
      mem_a[word_addr] <= bus.writedata[7:0];
    end
  end

  always_ff @(posedge bus.clk) begin
    if (bus.write && bus.byteenable[1]) begin
      mem_b[word_addr] <= bus.writedata[15:8];
    end
  end

  always_ff @(posedge bus.clk) begin
    if (bus.write && bus.byteenable[2]) begin
      mem_c[word_addr] <= bus.writedata[23:16];
    end
  end

  always_ff @(posedge bus.clk) begin
    if (bus.write && bus.byteenable[3]) begin
      mem_d[word_addr] <= bus.writedata[31:24];

      $display("SIM INFO @ %0t: Writing %d to address %d in ram", $time, bus.writedata[31:24],
               bus.address);
    end
  end

  always_ff @(posedge bus.clk) begin
    bus.readdata <= {mem_d[word_addr], mem_c[word_addr], mem_b[word_addr], mem_a[word_addr]};

  end

  assign bus.waitrequest = 1'b0;

endmodule
