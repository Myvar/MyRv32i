`timescale 1ns / 1ps
`default_nettype none

module fifo #(
    parameter int WD = 32'd32,
    parameter int DEPTH = 32'd8 //   Depth = (Writing Rate - Reading Rate)/Clock Frequency
)(
    input i_clk,
    input i_rst,

    input i_write_en,
    input wire [WD-1:-0] i_data,

    input i_read_en,
    output wire [WD-1:-0] o_data,

    output o_full,
    output o_empty
);

    reg [WD-1:0] mem[0:DEPTH-1];

    reg [$clog2(DEPTH)-1:0] write_ptr = 0;
    reg [$clog2(DEPTH)-1:0] read_ptr = 0;

    assign o_full = ((write_ptr+1'b1) == read_ptr);
    assign o_empty = read_ptr == write_ptr;
    assign o_data = mem[read_ptr];

    //writing data to ptr
    always_ff @(posedge i_clk)
        if (i_rst)
            write_ptr <= 0;
        else
            if(i_write_en && !o_full)
                write_ptr <= write_ptr + 1;
            else
                write_ptr <= write_ptr;
            

    //inc
    always_ff @(posedge i_clk)
            if(i_write_en)
                mem[write_ptr] <= i_data;
            else
                mem[write_ptr] <= mem[write_ptr];
          

    //inc
    always_ff @(posedge i_clk)
            if (i_rst)
                read_ptr <= 0;
            else
                if(i_read_en && !o_empty)
                    read_ptr <= read_ptr + 1;
                else
                    read_ptr <= read_ptr;


`ifdef FORMAL
    // assume inputs
    initial assume(i_write_en == 0);
    initial assume(o_data == 0);
    initial assume(i_data == 0);


    //assert internal state
    reg f_past_valid;
    initial f_past_valid = 1'b0;
    always @(posedge i_clk)
        f_past_valid <= 1'b1;

    always @(posedge i_clk)
        if(f_past_valid && $past(i_rst))
            assert(read_ptr == 0);
    
    always @(posedge i_clk)
        if (o_full || o_empty)
            assert(o_full != o_empty); //cant be full and empty at the same time

    always @(posedge i_clk)
        if(f_past_valid)
            if($past(i_rst))
                assert(write_ptr == 0);
            else
                if($past(i_write_en) && !$past(o_full) && !o_full)
                    assert($past(write_ptr) == write_ptr-1'b1);

    always @(posedge i_clk)
        if(f_past_valid)
            if($past(i_rst))
                assert(read_ptr == 0);
            else
                if($past(i_read_en))
                    if(!$past(o_full) && !o_full)
                        if(!$past(o_empty) && !o_empty)
                            assert($past(read_ptr) == read_ptr-1'b1);

    //assert output
    // o_empty
    always @(posedge i_clk)
        if(read_ptr == write_ptr)
            assert(o_empty);
        else
            assert(!o_empty);

    //o_full
    always @(posedge i_clk)
        if ((write_ptr+1'b1) == read_ptr)
            assert(o_full);
        else
            assert(!o_full);

    //o_data
    always @(*)
            assert(o_data == mem[read_ptr]);
    
    //make sure its switches over next clock
    always @(posedge i_clk)
        if (f_past_valid)
            if(!$past(i_rst))
                if($past(i_write_en) && !$past(o_full) && !o_full)
                    assert($past(i_data) == mem[write_ptr-1]);


`endif

endmodule: fifo