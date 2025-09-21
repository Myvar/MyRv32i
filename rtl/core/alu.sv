`timescale 1ns / 1ps
//
`default_nettype none
`include "opcode.svh"


module alu #(
    parameter int AW = 32,
    parameter int DW = 32
) (
    domain_if domain,
    input wire i_stall,

    input Opcode          i_opcode,
    input wire   [  31:0] i_imm,
    input wire   [DW-1:0] i_rs1,
    input wire   [DW-1:0] i_rs2,

    output reg          o_rd_write,
    output reg [DW-1:0] o_rd
);

  always_ff @(posedge domain.i_clk) begin
    o_rd_write <= 1'b0;
    o_rd <= 32'b0;

    case (i_opcode)
      OP_ADD: begin
        o_rd <= i_rs1 + i_rs2;
        o_rd_write <= 1'b1;
      end
      OP_SUB: begin
        o_rd <= i_rs1 - i_rs2;
        o_rd_write <= 1'b1;
      end
      OP_SLL: begin
        o_rd <= i_rs1 << i_rs2[4:0];
        o_rd_write <= 1'b1;
      end
      OP_SLT: begin
        o_rd <= ($signed(i_rs1) < $signed(i_rs2)) ? 32'd1 : 32'd0;
        o_rd_write <= 1'b1;
      end
      OP_SLTU: begin
        o_rd <= (i_rs1 < i_rs2) ? 32'd1 : 32'd0;
        o_rd_write <= 1'b1;
      end
      OP_XOR: begin
        o_rd <= i_rs1 ^ i_rs2;
        o_rd_write <= 1'b1;
      end
      OP_SRL: begin
        o_rd <= i_rs1 >> i_rs2[4:0];
        o_rd_write <= 1'b1;
      end
      OP_SRA: begin
        o_rd <= $signed(i_rs1) >>> i_rs2[4:0];
        o_rd_write <= 1'b1;
      end
      OP_OR: begin
        o_rd <= i_rs1 | i_rs2;
        o_rd_write <= 1'b1;
      end
      OP_AND: begin
        o_rd <= i_rs1 & i_rs2;
        o_rd_write <= 1'b1;
      end

      OP_ADDI: begin
        o_rd <= i_rs1 + i_imm;
        o_rd_write <= 1'b1;
      end
      OP_SLTI: begin
        o_rd <= ($signed(i_rs1) < $signed(i_imm)) ? 32'd1 : 32'd0;
        o_rd_write <= 1'b1;
      end
      OP_SLTIU: begin
        o_rd <= (i_rs1 < i_imm) ? 32'd1 : 32'd0;
        o_rd_write <= 1'b1;
      end
      OP_XORI: begin
        o_rd <= i_rs1 ^ i_imm;
        o_rd_write <= 1'b1;
      end
      OP_ORI: begin
        o_rd <= i_rs1 | i_imm;
        o_rd_write <= 1'b1;
      end
      OP_ANDI: begin
        o_rd <= i_rs1 & i_imm;
        o_rd_write <= 1'b1;
      end
      OP_SLLI: begin
        o_rd <= i_rs1 << i_imm[4:0];
        o_rd_write <= 1'b1;
      end
      OP_SRLI: begin
        o_rd <= i_rs1 >> i_imm[4:0];
        o_rd_write <= 1'b1;
      end
      OP_SRAI: begin
        o_rd <= $signed(i_rs1) >>> i_imm[4:0];
        o_rd_write <= 1'b1;
      end

      OP_LUI: begin
        o_rd <= i_imm;
        o_rd_write <= 1'b1;
      end

      default: begin
        o_rd_write <= 1'b0;
        o_rd <= 32'b0;
      end
    endcase
  end

endmodule
