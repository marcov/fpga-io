`timescale 1ns / 1ps

////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer:
//
// Create Date:   21:51:26 10/09/2013
// Design Name:   top
// Module Name:   C:/Documents and Settings/Administrator/Desktop/helloworld/top_test.v
// Project Name:  helloworld
// Target Device:  
// Tool versions:  
// Description: 
//
// Verilog Test Fixture created by ISE for module: top
//
// Dependencies:
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
////////////////////////////////////////////////////////////////////////////////

module top_test;

	// Inputs
	reg sim_clk;
	reg in_reset_n;
	reg in_ftdi_rxf_n;
	reg in_ftdi_txe_n;

	// Outputs
	wire out_led;
	wire out_ftdi_wr_n;
	wire out_ftdi_rd_n;



    wire [7:0] t_ftdi_io_data;

    wire [7:0] _iobuffer_in;
    wire [7:0] _iobuffer_out;
    reg        t_ftdi_emu_out_enable;
    reg [7:0]  t_ftdi_emu_tx_data;
    reg [7:0]  t_reg_in_data;

    assign _iobuffer_in     = t_ftdi_io_data;
    assign t_ftdi_io_data   = t_ftdi_emu_out_enable ? _iobuffer_out : 8'bz;
    assign _iobuffer_out    = t_ftdi_emu_tx_data;
	 
	 
	// Instantiate the Unit Under Test (UUT)
	top uut (
		.in_ext_osc(sim_clk), 
		.in_reset_n(in_reset_n), 
		.out_led(out_led), 
		.io_ftdi_data(t_ftdi_io_data), 
		.in_ftdi_rxf_n(in_ftdi_rxf_n), 
		.in_ftdi_txe_n(in_ftdi_txe_n), 
		.out_ftdi_wr_n(out_ftdi_wr_n), 
		.out_ftdi_rd_n(out_ftdi_rd_n)
	);

    // HERE we are emulating the FT2332H!
	initial begin
		// Initialize Inputs
		#0
		sim_clk = 0;
		in_reset_n = 1;
		in_ftdi_rxf_n = 1;
		in_ftdi_txe_n = 1;
		t_ftdi_emu_out_enable = 0;

		#10
		in_reset_n = 0;
		
		#50
		in_reset_n = 1;

		#100
		t_ftdi_emu_out_enable = 1;
		t_ftdi_emu_tx_data   = 16'h00;
		in_ftdi_rxf_n   = 0;
		
		#150
		in_ftdi_txe_n = 0;
		
		// Wait 100 ns for global reset to finish
		#10000;
		
       
		// Add stimulus here 
	end
	
    //66MHz
	always #7.5 sim_clk = !sim_clk; 
	
	/*
	 always @ (posedge out_ftdi_rd_n)
    begin
        in_ftdi_rxf_n          <= 1;
        t_ftdi_emu_out_enable        <= 0;
    end

    always @ (posedge out_ftdi_wr_n)
    begin
        in_ftdi_txe_n <= 1;
    end
    */ 
	 
	 
	 
    always @ (negedge out_ftdi_rd_n)
    begin
        t_ftdi_emu_out_enable        <= 1;
    end
	 
	always @ (posedge out_ftdi_rd_n)
    begin
        t_ftdi_emu_out_enable        <= 0;
        t_ftdi_emu_tx_data <= t_ftdi_emu_tx_data + 1;
    end
	 
endmodule

