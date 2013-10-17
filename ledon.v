`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    12:50:21 10/06/2013 
// Design Name: 
// Module Name:    ledon 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module clk_divider_log2(clk, reset, div, out);
	input clk, reset;
	input [4:0] div;
	output reg out;
	reg [31:0] counter;
	
	always @ (posedge clk, posedge reset)
	begin
		if (reset)
		begin
			out     <= 0;
			counter <= 0;
		end
		else
		begin
			counter <= counter + 1;
			out     <= counter[div];
		end
	end
endmodule

module counter_n_bit(reset, pulse, top, out);
	parameter N_BITS = 9;

	input reset, pulse;
	input  wire [N_BITS - 1:0] top;
	output reg  [N_BITS - 1:0] out;
	
	always @ (posedge pulse, posedge reset)
	begin
		if (reset)
		begin
			out <= 0;
		end
		else
		begin
			if (out == top)
				out <= 0;
			else
				out <= out + 1;
		end
	end
endmodule
 
 
 
module ledon   (clk, 
                reset_n,
                out);
	input clk;
	input reset_n;
	output out;
	
	wire [8:0] c9val; 
	
	counter_n_bit c9b (.reset(!reset_n),
					       .pulse(out),
						    .top({5'd25, 4'b1111}),
						    .out(c9val));
						  
	clk_divider_log2  div2n(.clk(clk),
					            .reset(!reset_n),
					            .div(c9val[8:4]),
					            .out(out));
						
endmodule
