`timescale 1ns / 1ps
//
`default_nettype none
`include "opcode.svh"


module lsu #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    bus_if.master bus,

    // Line from stall unit
    input wire i_stall,

    // Inputs from decode stage
    input Opcode          i_opcode,
    input wire   [  31:0] i_imm,
    input wire   [DW-1:0] i_rs1,
    input wire   [DW-1:0] i_rs2,

    // Outputs to writeback stage
    output reg o_rd_write,
    output reg [DW-1:0] o_rd,

    // Output to stall unit
    output reg o_busy
);

  logic is_load, is_store;
  logic [AW-1:0] effective_address;
  logic transaction_active;
  reg transaction_active_reg;

  wire transaction_done = transaction_active_reg && !bus.waitrequest;

  assign is_load  = (i_opcode == OP_LB || i_opcode == OP_LH || i_opcode == OP_LW || i_opcode == OP_LBU || i_opcode == OP_LHU);
  assign is_store = (i_opcode == OP_SB || i_opcode == OP_SH || i_opcode == OP_SW);
  assign effective_address = i_rs1 + i_imm;

  assign transaction_active = (is_load || is_store) && !i_stall;

  always_ff @(posedge bus.clk or posedge bus.reset) begin
    if (bus.reset) begin
      transaction_active_reg <= 1'b0;
    end else begin
      if (transaction_active && !transaction_active_reg) begin
        transaction_active_reg <= 1'b1;  // Start of a new transaction
      end else if (transaction_done) begin
        transaction_active_reg <= 1'b0;  // End of the current transaction
      end
    end
  end

  reg o_busy_reg;

  always_ff @(posedge bus.clk or posedge bus.reset) begin
    if (bus.reset) begin
      o_busy_reg <= 1'b0;  // It's good practice to reset registers
    end else begin
      o_busy_reg <= transaction_active_reg;
    end
  end

  assign o_busy         = o_busy_reg;

  assign bus.address    = effective_address;
  assign bus.read       = transaction_active_reg && is_load;
  assign bus.chipselect = transaction_active_reg && (is_load || is_store);

  always_comb begin
    bus.writedata = 'x;
    bus.byteenable = '0;
    bus.write = 0;

    if (is_store) begin
      case (i_opcode)
        OP_SB: begin
          bus.writedata = i_rs2[7:0] << (effective_address[1:0] * 8);
          bus.byteenable = 4'b0001 << effective_address[1:0];
          bus.write = 1;
        end
        OP_SH: begin
          bus.writedata = i_rs2[15:0] << (effective_address[1] * 16);
          bus.byteenable = (effective_address[1]) ? 4'b1100 : 4'b0011;
          bus.write = 1;
        end
        OP_SW: begin
          bus.writedata = i_rs2;
          bus.byteenable = 4'b1111;
          bus.write = 1;
        end
      endcase
    end
  end

  always_comb begin
    o_rd = 'x;
    o_rd_write = 0;

    if (is_load) begin
      case (i_opcode)
        OP_LB: begin
          // Load Byte (sign-extended)
          logic [7:0] temp_byte;
          case (effective_address[1:0])
            2'b00:   temp_byte = bus.readdata[7:0];
            2'b01:   temp_byte = bus.readdata[15:8];
            2'b10:   temp_byte = bus.readdata[23:16];
            default: temp_byte = bus.readdata[31:24];
          endcase
          o_rd = {{24{temp_byte[7]}}, temp_byte};
          o_rd_write = bus.read;
        end
        OP_LH: begin  // Load Half-word (sign-extended)
          logic [15:0] temp_half;
          temp_half = (effective_address[1]) ? bus.readdata[31:16] : bus.readdata[15:0];
          o_rd = {{16{temp_half[15]}}, temp_half};
          o_rd_write = bus.read;
        end
        OP_LW: begin  // Load Word
          o_rd = bus.readdata;
          o_rd_write = bus.read;
        end
        OP_LBU: begin  // Load Byte Unsigned (zero-extended)
          case (effective_address[1:0])
            2'b00:   o_rd = {24'h0, bus.readdata[7:0]};
            2'b01:   o_rd = {24'h0, bus.readdata[15:8]};
            2'b10:   o_rd = {24'h0, bus.readdata[23:16]};
            default: o_rd = {24'h0, bus.readdata[31:24]};
          endcase
          o_rd_write = bus.read;
        end
        OP_LHU: begin  // Load Half-word Unsigned (zero-extended)
          logic [15:0] temp_half;
          temp_half = (effective_address[1]) ? bus.readdata[31:16] : bus.readdata[15:0];
          o_rd = {16'h0, temp_half};
          o_rd_write = bus.read;
        end
      endcase
    end
  end

endmodule
