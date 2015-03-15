/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

`timescale 1ns / 1ps

module ram_singleport
#(
    parameter RAM_ADDR_WIDTH = 8,
    parameter RAM_DATA_WIDTH = 8
)
(
    input                           in_clk,
    input      [RAM_ADDR_WIDTH-1:0] in_addr,
    output reg [RAM_DATA_WIDTH-1:0] out_data, 
    input      [RAM_DATA_WIDTH-1:0] in_data,
    input  in_wr
);

(* ram_style = "block" *) reg [ (RAM_DATA_WIDTH - 1) : 0] data_RAM [ 0 : (2**RAM_ADDR_WIDTH - 1) ];

`ifdef BUILD_FOR_SIMULATION
reg ram_wr_fb;
initial
begin
    ram_wr_fb = 0;
end
`endif

always @(posedge in_clk)
begin
    if (in_wr)
    begin
        data_RAM[in_addr] <= in_data;
        out_data <= in_data;
`ifdef BUILD_FOR_SIMULATION
        ram_wr_fb = 1;
        #1
        ram_wr_fb = 0;
`endif
    end
    else
    begin
        out_data <= data_RAM[in_addr];
    end
end
endmodule

