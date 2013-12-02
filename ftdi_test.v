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

module ftdi_testbench;

	// Inputs
	reg sim_clk;
	reg in_reset_n;

	// Outputs
    reg rx_enabled;
    wire [7:0]  data_rx;
    wire [7:0] data_tx;
    wire [7:0] io_ftdi_data;
    wire rx_req;
    reg  rx_ack;
    reg  tx_req;
    wire tx_ack;

///////////////////////////////////////////////////////////////////
    // FTDI Wires for logic conversion to FTDI modules.
    wire in_ftdi_txe_p;
    wire in_ftdi_rxf_p;
    wire in_reset_p;
    wire out_ftdi_wr_p;
    wire out_ftdi_rd_p;

    //FTDI Wires conversion logic.
    assign in_ftdi_txe_p = !in_ftdi_txe_n;
    assign in_ftdi_rxf_p = !in_ftdi_rxf_n;
    assign in_reset_p    = !in_reset_n;

    assign out_ftdi_wr_n = !out_ftdi_wr_p;
    assign out_ftdi_rd_n = !out_ftdi_rd_p;
    
	// Instantiate the Implementation Under Test (IUT)
    ftdiController iut (.in_clk(sim_clk),
                      .in_rst(in_reset_p),
                      .in_ftdi_txe(in_ftdi_txe_p), 
                      .in_ftdi_rxf(in_ftdi_rxf_p),
                      .io_ftdi_data(io_ftdi_data), 
                      .out_ftdi_wr(out_ftdi_wr_p), 
                      .out_ftdi_rd(out_ftdi_rd_p),
                      .in_rx_en(rx_enabled),
                      .in_tx_hsk_req(tx_req),
                      .out_tx_hsk_ack(tx_ack),
                      .in_tx_data(data_tx),
                      .out_rx_data(data_rx),
                      .out_rx_hsk_req(rx_req),
                      .in_rx_hsk_ack(rx_ack));

///////////////////////////////////////////////////////////////////
    parameter FT2232H_FIFO_SIZE = 128;

    reg [(FT2232H_FIFO_SIZE * 8) - 1 : 0]  lt_ft2232h_usb_tx_data;
    wire [(FT2232H_FIFO_SIZE * 8) - 1 : 0] lt_ft2232h_usb_rx_data;
    reg [$clog2(FT2232H_FIFO_SIZE) - 1 : 0]  lt_ft2232h_usb_tx_size;
    reg [$clog2(FT2232H_FIFO_SIZE) - 1 : 0] lt_ft2232h_usb_rx_size;
    reg lt_ft2232h_usb_tx_start;
    reg lt_ft2232h_usb_rx_start;
    wire lt_ft2232h_usb_rx_done;

    /* FT2232H: lower tester */
    ft2232h_device #(.FIFO_SIZE(FT2232H_FIFO_SIZE))
            lt_ft2232h (
                 .in_rd_n (out_ftdi_rd_n),
                 .in_wr_n (out_ftdi_wr_n),
                 .out_txe_n (in_ftdi_txe_n),
                 .out_rxf_n (in_ftdi_rxf_n),
                 .io_data   (io_ftdi_data),
                 .usb_tx_data (lt_ft2232h_usb_tx_data),
                 .usb_rx_data (lt_ft2232h_usb_rx_data),
                 .usb_tx_size (lt_ft2232h_usb_tx_size),
                 .usb_rx_size (lt_ft2232h_usb_rx_size),
                 .usb_tx_start (lt_ft2232h_usb_tx_start),
                 .usb_rx_start (lt_ft2232h_usb_rx_start),
                 .usb_rx_done (lt_ft2232h_usb_rx_done));

///////////////////////////////////////////////////////////////////
	initial begin
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


/////////////////////////////////////////////////////////////////////////////////////////////
//
module ft2232h_device #(parameter FIFO_SIZE = 128)
                     (input in_rd_n,
                      input in_wr_n,
                      output reg out_txe_n,
                      output reg out_rxf_n,
                      inout  [7:0] io_data,
                      input  [(FIFO_SIZE * 8) - 1 : 0] usb_tx_data,
                      output reg  [(FIFO_SIZE * 8) - 1 : 0] usb_rx_data,
                      input  [$clog2(FIFO_SIZE) - 1 : 0]     usb_tx_size,
                      input [$clog2(FIFO_SIZE) - 1 : 0]      usb_rx_size,
                      input  usb_tx_start,
                      input  usb_rx_start,
                      output reg  usb_rx_done);

    wire [7:0] in_data;
    reg  [7:0] out_data;
    reg        io_out_enable;
    reg [15:0] rcvd_data;

    assign in_data   = io_data;
    assign io_data   = io_out_enable ? out_data : 8'bz;

    reg usb_tx_in_progress;
    reg usb_rx_in_progress;

    reg [$clog2(FIFO_SIZE) - 1 : 0] usb_tx_counter;
    reg [$clog2(FIFO_SIZE) - 1 : 0] usb_rx_counter;

    // HERE we are emulating the FT2332H!
	always 
    begin : usb_to_fpga_ctrl
        // Set io to input
        io_out_enable = 0;
        
        //Disable USB -> FPGA
        out_rxf_n         = 1;

        usb_tx_in_progress = 0;
        
        wait (usb_tx_start);
        usb_tx_in_progress = 0;

        /* Make it half-duplex */
        wait (!usb_rx_in_progress)
        begin
            usb_tx_in_progress = 1;
            
            // So we dont tx twice.
            wait(usb_tx_start == 0);
            //Enable USB -> FPGA
            out_rxf_n         = 0;
            
            for (usb_tx_counter = 0; 
                 usb_tx_counter < usb_tx_size; 
                 usb_tx_counter = usb_tx_counter + 1)
            begin
                // TX char
                @(negedge in_rd_n)
                begin
                    io_out_enable = 1;
                    out_data    = usb_tx_data >> (usb_tx_counter*8);
                end
                @(posedge in_rd_n)  io_out_enable = 0;
            end
        end
	end

    always 
    begin : fpga_to_usb_ctrl

        // Set io to input
		io_out_enable = 0;

        // Disable FPGA -> USB 
        out_txe_n         = 1;
       
        usb_rx_in_progress = 0;
        
        wait(usb_rx_start);
        usb_rx_done = 0;

        usb_rx_data = 0;

        /* Make it half-duplex */
        wait (!usb_tx_in_progress)
        begin
            usb_rx_in_progress = 1;

            // Enable FPGA -> USB 
            out_txe_n         = 0;

            for (usb_rx_counter = 0; 
                 usb_rx_counter < usb_rx_size; 
                 usb_rx_counter = usb_rx_counter + 1)
            begin
                // RX char
                @ (negedge in_wr_n) usb_rx_data = usb_rx_data | (in_data << (usb_rx_counter * 8));
            end

            usb_rx_done = 1;
        end
    end
endmodule


