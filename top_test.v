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
    
    // Include functions builtins redefinition for which XST is missing support.
    `include "builtins_redefined.v"
    
    localparam TOP_TEST_3W_ADDRESS_BITS = 10;
    localparam TOP_TEST_3W_DATA_BITS    = 32;
    localparam TOP_TEST_3W_CLK_DIV_2N = 4;

    
    localparam TOP_TEST_3W_ADDR_BYTES  = _cdiv(TOP_TEST_3W_ADDRESS_BITS, 8);
    localparam TOP_TEST_3W_DATA_BYTES  = _cdiv(TOP_TEST_3W_DATA_BITS, 8);
///////////////////////////////////////////////////////////////////
    // Instantiate the Implementation Under Test (IUT)
	top #(.TOP_3W_ADDRESS_BITS(TOP_TEST_3W_ADDRESS_BITS),
          .TOP_3W_DATA_BITS   (TOP_TEST_3W_DATA_BITS),
          .TOP_3W_CLK_DIV_2N  (TOP_TEST_3W_CLK_DIV_2N))
        iut_top (
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

     
    wire [TOP_TEST_3W_ADDRESS_BITS - 1 : 0] lt_tw_slave_addr;
    reg  [TOP_TEST_3W_DATA_BITS - 1 : 0]    lt_tw_slave_rd_data;
    wire [TOP_TEST_3W_DATA_BITS - 1 : 0]    lt_tw_slave_wr_data;
    wire                                    lt_tw_slave_mode_wr;
    
    /* Threewire slave: lower tester */
    tw_slave  #(.ADDR_BITS(TOP_TEST_3W_ADDRESS_BITS),
                .DATA_BITS(TOP_TEST_3W_DATA_BITS))
             lt_3w_slave(
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
        $dumpfile("top_testbench.lxt");
        $dumpvars(0, top_testbench);

		// Initialize Inputs
		#0
		sim_clk = 0;
		in_reset_n = 1;

		#10
		in_reset_n = 0;
		
		#50
		in_reset_n = 1;

        /// TEST READ.
		lt_tw_slave_rd_data = 'hAABBCCDD;

        lt_ft2232h_usb_tx_size = 1 + TOP_TEST_3W_ADDR_BYTES;
        lt_ft2232h_usb_rx_size = TOP_TEST_3W_DATA_BYTES;

        lt_ft2232h_usb_tx_data [7:0]   = 8'h00;
        lt_ft2232h_usb_tx_data [15:8]  = 8'h03;
        lt_ft2232h_usb_tx_data [23:16] = 8'hBB;
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);

        /// TEST WRITE.
        lt_ft2232h_usb_tx_size = 1 + TOP_TEST_3W_ADDR_BYTES + TOP_TEST_3W_DATA_BYTES;
        lt_ft2232h_usb_rx_size = 1;

        lt_ft2232h_usb_tx_data [7:0]    = 8'h01;
        lt_ft2232h_usb_tx_data [15:8]   = 8'h01;
        lt_ft2232h_usb_tx_data [23:16]  = 8'hBB;
        lt_ft2232h_usb_tx_data [31:24]  = 8'hCC;
        lt_ft2232h_usb_tx_data [39:32]  = 8'hDD;
        lt_ft2232h_usb_tx_data [47:40]  = 8'hEE;
        lt_ft2232h_usb_tx_data [55:48]  = 8'hFF;
        
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
