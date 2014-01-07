/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */
`timescale 1ns / 1ps

module rom_lookup_table 
#(
    parameter ROM_ADDR_WIDTH = 8,
    parameter ROM_DATA_WIDTH = 8
)
(
    input                       in_clk,
    input      [ROM_ADDR_WIDTH-1:0] in_addr,
    output reg [ROM_DATA_WIDTH-1:0] out_data 
);

(* ram_style = "block" *) reg [ (ROM_DATA_WIDTH - 1) : 0] mem [ 0 : (2**ROM_ADDR_WIDTH - 1) ];

initial begin
    $readmemh("mem_init_vlog.mif", mem, 0, ((2**ROM_ADDR_WIDTH) - 1)); 
end

always @(posedge in_clk)
    out_data <= mem[in_addr];
    
endmodule
