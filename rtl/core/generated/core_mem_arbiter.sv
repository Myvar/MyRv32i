/*
 * This module has a 2 segmented pipeline
 */

`timescale 1ns / 1ps
//
`default_nettype none

module core_mem_arbiter #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    input wire i_clk,
    input wire i_clk_en,
    input wire i_rst,

    output wire o_stall,

    // Fetch Read Port
    input wire i_fetch_read,
    input wire [AW-1:0] i_fetch_addr,
    output reg [DW-1:0] o_fetch_data,
    output reg o_fetch_ack,

    // LSU Read Port
    input wire i_lsu_read,
    input wire [AW-1:0] i_r_lsu_addr,
    output reg [DW-1:0] o_r_lsu_data,
    output reg o_lsu_ack,

    // LSU Write Port
    input wire i_lsu_write,
    input wire [AW-1:0] i_w_lsu_addr,
    input wire [3:0] i_w_lsu_byte_en,
    input wire [DW-1:0] i_w_lsu_data,

    // Debug Read Port
    input wire i_debug_read,
    input wire [AW-1:0] i_r_debug_addr,
    output reg [DW-1:0] o_r_debug_data,
    output reg o_debug_ack,

    // Debug Write Port
    input wire i_debug_write,
    input wire [AW-1:0] i_w_debug_addr,
    input wire [3:0] i_w_debug_byte_en,
    input wire [DW-1:0] i_w_debug_data
);

  // Local parameters for memory sizes
  localparam ROM_SIZE = 512;
  localparam RAM_SIZE = 4096;

  // Local RAM signals
  reg [AW-1:0] local_read_addr;
  wire [DW-1:0] local_read_data;

  reg local_write_en;
  reg [3:0] local_byte_en;
  reg [AW-1:0] local_write_addr;
  reg [DW-1:0] local_write_data;

  // Local ROM signals
  reg [AW-1:0] rom_read_addr;
  wire [DW-1:0] rom_read_data;

  // Stall signal (Assuming no stalls for simplicity)
  assign o_stall = 1'b0;

  // Enumerations for ports and target memories
  typedef enum logic [1:0] {
    PORT_LSU   = 2'b00,
    PORT_FETCH = 2'b01,
    PORT_DEBUG = 2'b10
  } Port;

  typedef enum logic [1:0] {
    T_PORT_ROM  = 2'b00,
    T_PORT_LRAM = 2'b01
  } TargetPort;

  // Source port and address
  Port src_port;
  reg [AW-1:0] src_addr;
  reg src_read;
  reg src_write;

  // Target port and address
  TargetPort target_port;
  reg [AW-1:0] target_addr;

  // Stage 1: Determine which port has control
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      src_port  <= PORT_LSU;
      src_addr  <= {AW{1'b0}};
      src_read  <= 1'b0;
      src_write <= 1'b0;
    end else if (i_clk_en) begin
      if (i_lsu_read) begin
        src_port  <= PORT_LSU;
        src_addr  <= i_r_lsu_addr;
        src_read  <= 1'b1;
        src_write <= 1'b0;
      end else if (i_lsu_write) begin
        src_port  <= PORT_LSU;
        src_addr  <= i_w_lsu_addr;
        src_read  <= 1'b0;
        src_write <= 1'b1;
      end else if (i_fetch_read) begin
        src_port  <= PORT_FETCH;
        src_addr  <= i_fetch_addr;
        src_read  <= 1'b1;
        src_write <= 1'b0;
      end else if (i_debug_read) begin
        src_port  <= PORT_DEBUG;
        src_addr  <= i_r_debug_addr;
        src_read  <= 1'b1;
        src_write <= 1'b0;
      end else if (i_debug_write) begin
        src_port  <= PORT_DEBUG;
        src_addr  <= i_w_debug_addr;
        src_read  <= 1'b0;
        src_write <= 1'b1;
      end else begin
        src_port  <= PORT_LSU;
        src_addr  <= {AW{1'b0}};
        src_read  <= 1'b0;
        src_write <= 1'b0;
      end
    end
  end

  // Stage 1b: Calculate target port and address
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      target_port <= T_PORT_LRAM;
      target_addr <= {AW{1'b0}};
    end else if (i_clk_en) begin
      if (src_addr < ROM_SIZE) begin
        target_port <= T_PORT_ROM;
        //$display("Target Port", src_addr);
        target_addr <= src_addr;
      end else if (src_addr < ROM_SIZE + RAM_SIZE) begin
        target_port <= T_PORT_LRAM;
        target_addr <= src_addr - (ROM_SIZE + ROM_SIZE);
      end else begin
        target_port <= T_PORT_LRAM;
        target_addr <= {AW{1'b0}};
      end
    end
  end

  // Stage 2: Demux source port to target memory
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      // Reset outputs
      o_fetch_data <= {DW{1'b0}};
      o_fetch_ack <= 1'b0;
      o_r_lsu_data <= {DW{1'b0}};
      o_lsu_ack <= 1'b0;
      o_r_debug_data <= {DW{1'b0}};
      o_debug_ack <= 1'b0;
      local_write_en <= 1'b0;
      local_byte_en <= 4'b0;
      local_write_addr <= {AW{1'b0}};
      local_write_data <= {DW{1'b0}};
      local_read_addr <= {AW{1'b0}};
      rom_read_addr <= {AW{1'b0}};
    end else if (i_clk_en) begin
      // Default assignments
      o_fetch_ack <= 1'b0;
      o_lsu_ack <= 1'b0;
      o_debug_ack <= 1'b0;
      local_write_en <= 1'b0;
      local_byte_en <= 4'b0;
      local_write_addr <= {AW{1'b0}};
      local_write_data <= {DW{1'b0}};

      case (src_port)
        PORT_LSU: begin
          if (src_read) begin
            if (target_port == T_PORT_ROM) begin
              //$display("ROM READ", target_addr);
              rom_read_addr <= target_addr;
              o_r_lsu_data  <= rom_read_data;
            end else begin
              //$display("RAM READ", target_addr);
              local_read_addr <= target_addr;
              o_r_lsu_data <= local_read_data;
            end
            o_lsu_ack <= 1'b1;
          end else if (src_write) begin
            if (target_port == T_PORT_LRAM) begin
              local_write_en <= 1'b1;
              local_byte_en <= i_w_lsu_byte_en;
              local_write_addr <= target_addr;
              local_write_data <= i_w_lsu_data;
            end
            o_lsu_ack <= 1'b1;
          end
        end
        PORT_FETCH: begin
          if (src_read) begin
            if (target_port == T_PORT_ROM) begin
              rom_read_addr <= target_addr;
              o_fetch_data  <= rom_read_data;
            end else begin
              local_read_addr <= target_addr;
              o_fetch_data <= local_read_data;
            end
            o_fetch_ack <= 1'b1;
          end
        end
        PORT_DEBUG: begin
          if (src_read) begin
            if (target_port == T_PORT_ROM) begin
              rom_read_addr  <= target_addr;
              o_r_debug_data <= rom_read_data;
            end else begin
              local_read_addr <= target_addr;
              o_r_debug_data  <= local_read_data;
            end
            o_debug_ack <= 1'b1;
          end else if (src_write) begin
            if (target_port == T_PORT_LRAM) begin
              local_write_en <= 1'b1;
              local_byte_en <= i_w_debug_byte_en;
              local_write_addr <= target_addr;
              local_write_data <= i_w_debug_data;
            end
            o_debug_ack <= 1'b1;
          end
        end
        default: begin
          // Do nothing
        end
      endcase
    end
  end

  // Instantiate Local ROM
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

  // Instantiate Local RAM
  local_ram #(
      .ADDR_WIDTH(AW),
      .DATA_WIDTH(DW),
      .ADDR_COUNT(RAM_SIZE)
  ) u_local_ram (
      .i_clk(i_clk),
      .i_clk_en(i_clk_en),
      .i_rst(i_rst),
      // Read
      .i_read_addr(local_read_addr),
      .o_read_data(local_read_data),
      // Write
      .i_write_en(local_write_en),
      .i_byte_en(local_byte_en),
      .i_write_addr(local_write_addr),
      .i_write_data(local_write_data)
  );

endmodule
