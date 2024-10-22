module fifo #(
    parameter DATA_WIDTH = 32,
    parameter DEPTH = 32,
    localparam DW = DATA_WIDTH
}(
    input i_clk,
    input i_rst,

    input i_write_en,
    input wire [WD-1:-0] i_data,
    
    input i_read_en,
    output wire [WD-1:-0] o_data,

    output o_full,
    output o_empty
);

    reg [WIDTH-1:0] mem[0:DEPTH-1];

    reg [$clog2(DEPTH)-1:0] write_ptr = 0;
    reg [$clog2(DEPTH)-1:0] read_ptr = 0;

    always_ff @(posedge i_clk) begin
        
    end

`ifdef FORMAL
    initial assume(i_write_en == 0);
    initial assume(i_read_en == 0);

    always @(posedge clk) begin
    end
`endif

endmodule : fifo