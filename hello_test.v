`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   20:14:02 10/06/2013
// Design Name:   ledon
// Module Name:   C:/Documents and Settings/Administrator/Desktop/helloworld/hello_test.v
// Project Name:  helloworld
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: ledon
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module hello_test; 

	// Inputs
	reg clock;
	reg reset;

	// Outputs
	wire led;

	// Instantiate the Unit Under Test (UUT)
	ledon uut (
		.clk(clock), 
		.reset_n(reset), 
		.out(led)
	);

	
	initial begin
		// Initialize Inputs
		clock = 0;
		reset = 1;

		// Wait 100 ns for global reset to finish
		#100;
      reset = 0;
		
		#200
		reset = 1;
		// Add stimulus here
	end
	
   always #1 clock = !clock;
		
		
   
endmodule

