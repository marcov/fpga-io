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

module top_testbench;

	// Inputs
	reg sim_clk;
	reg in_reset_n;

	// Outputs
	wire out_led;
	wire out_ftdi_wr_n;
	wire out_ftdi_rd_n;
    wire [7:0] io_ftdi_data;
    
///////////////////////////////////////////////////////////////////
    // Instantiate the Implementation Under Test (IUT)
	top iut_top (
		.in_ext_osc(sim_clk), 
		.in_reset_n(in_reset_n), 
		.out_led(out_led), 
		.io_ftdi_data(io_ftdi_data), 
		.in_ftdi_rxf_n(in_ftdi_rxf_n), 
		.in_ftdi_txe_n(in_ftdi_txe_n), 
		.out_ftdi_wr_n(out_ftdi_wr_n), 
		.out_ftdi_rd_n(out_ftdi_rd_n),
        .out_tw_clock (tw_bus_clock),
        .out_tw_cs    (tw_bus_chipselect),
        .io_tw_data   (tw_bus_data)
	);

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
    wire [8:0]  lt_tw_slave_addr;
    reg  [15:0] lt_tw_slave_rd_data;
    wire [15:0] lt_tw_slave_wr_data;
    wire        lt_tw_slave_mode_wr;

    /* Threewire slave: lower tester */
    tw_slave lt_3w_slave (
                .tw_bus_clock(tw_bus_clock),
                .tw_bus_chipselect(tw_bus_chipselect),
                .tw_bus_data(tw_bus_data),
                .address(lt_tw_slave_addr),
                .wr_data(lt_tw_slave_wr_data),
                .rd_data(lt_tw_slave_rd_data),
                .mode_wr(lt_slave_mode_wr));

///////////////////////////////////////////////////////////////////
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

        /// TEST READ.
		lt_tw_slave_rd_data = 16'hAABB;

        lt_ft2232h_usb_tx_size = 3;
        lt_ft2232h_usb_rx_size = 2;

        lt_ft2232h_usb_tx_data [7:0]   = 8'h00;
        lt_ft2232h_usb_tx_data [15:8]  = 8'h01;
        lt_ft2232h_usb_tx_data [23:16] = 8'hBB;
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);

        /// TEST WRITE.
        lt_ft2232h_usb_tx_size = 5;
        lt_ft2232h_usb_rx_size = 1;

        lt_ft2232h_usb_tx_data [7:0]    = 8'h01;
        lt_ft2232h_usb_tx_data [15:8]   = 8'h01;
        lt_ft2232h_usb_tx_data [23:16]  = 8'hBB;
        lt_ft2232h_usb_tx_data [31:24]  = 8'hCC;
        lt_ft2232h_usb_tx_data [39:32]  = 8'hDD;
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        /// TEST PING.
        lt_ft2232h_usb_tx_size = 1;
        lt_ft2232h_usb_rx_size = 1;

        lt_ft2232h_usb_tx_data [7:0]    = 8'hFF;
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        /// TEST ECHO.
        lt_ft2232h_usb_tx_size = 2;
        lt_ft2232h_usb_rx_size = 1;

        lt_ft2232h_usb_tx_data [7:0]    = 8'hAA;
        lt_ft2232h_usb_tx_data [15:8]   = 8'hF1;
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        
        lt_ft2232h_usb_rx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 0;
        // Wait 100 ns for global reset to finish
		#10000;
     end

    //66MHz
	always #7.5 sim_clk = !sim_clk; 
endmodule

////////////////////////////////////////////////////////

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
