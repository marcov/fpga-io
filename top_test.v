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

	// Outputs
	wire out_led;
	wire out_ftdi_wr_n;
	wire out_ftdi_rd_n;

    wire [7:0] io_ftdi_data;
	
    // Instantiate the Unit Under Test (UUT)
	top uut (
		.in_ext_osc(sim_clk), 
		.in_reset_n(in_reset_n), 
		.out_led(out_led), 
		.io_ftdi_data(io_ftdi_data), 
		.in_ftdi_rxf_n(in_ftdi_rxf_n), 
		.in_ftdi_txe_n(in_ftdi_txe_n), 
		.out_ftdi_wr_n(out_ftdi_wr_n), 
		.out_ftdi_rd_n(out_ftdi_rd_n)
	);

    ft2232h_device ft2232h_lt(
         .in_rd_n (out_ftdi_rd_n),
         .in_wr_n (out_ftdi_wr_n),
         .out_txe_n (in_ftdi_txe_n),
         .out_rxf_n (in_ftdi_rxf_n),
         .io_data   (io_ftdi_data));
          

     initial
     begin
		// Initialize Inputs
		#0
		sim_clk = 0;
		in_reset_n = 1;

		#10
		in_reset_n = 0;
		
		#50
		in_reset_n = 1;
		
        // Wait 100 ns for global reset to finish
		#10000;
     end

    //66MHz
	always #7.5 sim_clk = !sim_clk; 
endmodule

////////////////////////////////////////////////////////

module ft2232h_device(input in_rd_n,
                      input in_wr_n,
                      output reg out_txe_n,
                      output reg out_rxf_n,
                      inout  [7:0] io_data,
                      input  [7:0] usb_tx_data,
                      output reg [7:0] usb_rx_data);

    wire [7:0] in_data;
    reg  [7:0] out_data;
    reg        io_out_enable;

    reg [15:0] rcvd_data;

    assign in_data   = io_data;
    assign io_data   = io_out_enable ? out_data : 8'bz;
    
    // HERE we are emulating the FT2332H!
	always 
    begin : ft2232h_emulator

        // Set io to input
		io_out_enable = 0;
        
		// Disable FPGA -> USB 
        out_txe_n         = 1;

        //Enable USB -> FPGA
        out_rxf_n         = 0;

        // TX char
	    wait(in_rd_n == 0);
		io_out_enable = 1;
		out_data    = 8'h00;
	    wait(in_rd_n == 1);
		io_out_enable = 0;

        // TX char
	    wait(in_rd_n == 0);
		io_out_enable = 1;
		out_data    = 8'h01;
	    wait(in_rd_n == 1);
		io_out_enable = 0;

        // TX char
	    wait(in_rd_n == 0);
		io_out_enable = 1;
		out_data    = 8'h5A;
	    wait(in_rd_n == 1);
		io_out_enable = 0;
        
        //Disable USB -> FPGA
        out_rxf_n         = 1;
		
		// Enable FPGA -> USB 
        out_txe_n         = 0;
	    
        rcvd_data = 0;

        // RX char
        wait(in_wr_n == 0);
        rcvd_data = rcvd_data | (in_data << 8);
        wait(in_wr_n == 1);
		// Enable FPGA -> USB 
        out_txe_n         = 0;

        // RX char
        wait(in_wr_n == 0);
        rcvd_data = rcvd_data | in_data;
        wait(in_wr_n == 1);
		// Disable FPGA -> USB 
        out_txe_n         = 1;

	end
endmodule
