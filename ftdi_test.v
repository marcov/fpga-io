`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:50:49 10/09/2013
// Design Name:   ftdiController
// Module Name:   C:/Documents and Settings/Administrator/Desktop/helloworld/ftdi_test.v
// Project Name:  helloworld
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ftdiController
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module ftdi_test;

	// Inputs
	reg clk;
	reg rst;
	reg in_wr_allowed;
	reg in_data_available;

	// Outputs
	wire out_wr_strobe;
	wire out_rd_strobe;

	// Bidirs
	wire [7:0] io_data;

	// Instantiate the Unit Under Test (UUT)
	ftdiController uut (
		.clk(clk), 
		.rst(rst), 
		.in_wr_allowed(in_wr_allowed), 
		.in_data_available(in_data_available), 
		.io_data(io_data), 
		.out_wr_strobe(out_wr_strobe), 
		.out_rd_strobe(out_rd_strobe)
	);

	initial begin
		// Initialize Inputs
		clk = 0;
		rst = 0;
		in_wr_allowed = 0;
		in_data_available = 0;

		// Wait 100 ns for global reset to finish
		#100;
        
		// Add stimulus here

	end
      
endmodule

