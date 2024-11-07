module regs (
    input wire i_clk,
    input wire i_clk_en,
    input wire i_rst,

    input wire [4:0] i_rd_addr,
    input wire [31:0] i_rd_data,
    input wire i_rd_write,

    input wire [4:0] i_rs1_addr,
    output wire [31:0] o_rs1_data,

    input wire [4:0] i_rs2_addr,
    output wire [31:0] o_rs2_data
);

  // Define 32 registers, each 32-bits wide
  reg [31:0] registers[31:0];

  // Synchronous reset and write operations
  always_ff @(posedge i_clk) begin
    if (i_rst) begin
      // Reset all registers to zero
      integer i;
      for (i = 0; i < 32; i = i + 1) begin
        registers[i] <= 32'd0;
      end
    end
    else if (i_rd_write && i_clk_en) begin
      // Write data to the specified register address
      registers[i_rd_addr] <= i_rd_data;
    end
  end

  // Read data from registers
  assign o_rs1_data = (i_rs1_addr != 0) ? registers[i_rs1_addr] : 32'd0;
  assign o_rs2_data = (i_rs2_addr != 0) ? registers[i_rs2_addr] : 32'd0;

endmodule
