`timescale 1ns / 1ps

module ram_dualport
#(
    parameter RAM_ADDR_WIDTH = 8,
    parameter RAM_DATA_WIDTH = 8
)
(
    input                           in_clk,
    input      [RAM_ADDR_WIDTH-1:0] in_addr_a,
    input      [RAM_ADDR_WIDTH-1:0] in_addr_b,
    output reg [RAM_DATA_WIDTH-1:0] out_data_a, 
    output reg [RAM_DATA_WIDTH-1:0] out_data_b, 
    input      [RAM_DATA_WIDTH-1:0] in_data_a,
    input      [RAM_DATA_WIDTH-1:0] in_data_b,
    input  in_wr_a,
    input  in_wr_b
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
    if (in_wr_a)
    begin
        data_RAM[in_addr_a] <= in_data_a;
        out_data_a <= in_data_a;
`ifdef BUILD_FOR_SIMULATION
        ram_wr_fb = 1;
        #1
        ram_wr_fb = 0;
`endif
    end
    else
    begin
        out_data_a <= data_RAM[in_addr_a];
    end
    
    if (in_wr_b)
    begin
        data_RAM[in_addr_b] <= in_data_b;
        out_data_b <= in_data_b; 
`ifdef BUILD_FOR_SIMULATION
        ram_wr_fb = 1;
        #1
        ram_wr_fb = 0;
`endif
    end
    else
    begin
        out_data_b <= data_RAM[in_addr_b];
    end
end
endmodule

