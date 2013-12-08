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

`include "project_config.v"

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
    
    localparam TOP_TEST_3W_ADDRESS_BITS = `THREEWIRE_ADDRESS_BITS;
    localparam TOP_TEST_3W_DATA_BITS    = `THREEWIRE_DATA_BITS;
    localparam TOP_TEST_3W_CLK_DIV_2N = `THREEWIRE_CLK_DIV_2N;

    
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
        .io_tw_data   (tw_bus_data),
        .out_tw_dir   (tw_bus_dir)
	);

///////////////////////////////////////////////////////////////////
    localparam FT2232H_BUFFER_SIZE = 128;
    localparam BUFFERS_WIDTH = _clog2(FT2232H_BUFFER_SIZE);

    reg [(FT2232H_BUFFER_SIZE * 8) - 1 : 0]  lt_ft2232h_usb_tx_data;
    wire [(FT2232H_BUFFER_SIZE * 8) - 1 : 0] lt_ft2232h_usb_rx_data;
    reg [BUFFERS_WIDTH - 1 : 0] lt_ft2232h_usb_tx_size;
    reg [BUFFERS_WIDTH - 1 : 0] lt_ft2232h_usb_rx_size;
    reg lt_ft2232h_usb_tx_start;
    reg lt_ft2232h_usb_rx_start;
    wire lt_ft2232h_usb_rx_done;

    wire [BUFFERS_WIDTH - 1 : 0] txbuffer_addr_a;
    reg  [BUFFERS_WIDTH - 1 : 0] txbuffer_addr_b;
    wire [7 : 0] txbuffer_din_a;
    reg  [7 : 0] txbuffer_din_b;
    wire [7 : 0] txbuffer_dout_a;
    wire [7 : 0] txbuffer_dout_b;
    wire txbuffer_wr_a;
    reg  txbuffer_wr_b;
    
    wire [BUFFERS_WIDTH - 1 : 0] rxbuffer_addr_a;
    wire [BUFFERS_WIDTH - 1 : 0] rxbuffer_addr_b;
    wire [7 : 0] rxbuffer_din_a;
    wire [7 : 0] rxbuffer_din_b;
    wire [7 : 0] rxbuffer_dout_a;
    wire [7 : 0] rxbuffer_dout_b;
    wire rxbuffer_wr_a;
    wire rxbuffer_wr_b;
    
    /* FT2232H: lower tester */
    ft2232h_device #(.BUFFERS_WIDTH(BUFFERS_WIDTH))
            lt_ft2232h (
                 .in_clk (sim_clk),
                 .in_rd_n (out_ftdi_rd_n),
                 .in_wr_n (out_ftdi_wr_n),
                 .out_txe_n (in_ftdi_txe_n),
                 .out_rxf_n (in_ftdi_rxf_n),
                 .io_data   (io_ftdi_data),
                 .usb_tx_size (lt_ft2232h_usb_tx_size),
                 .usb_txbuffer_addr(txbuffer_addr_a),
                 .usb_txbuffer_data(txbuffer_dout_a),
                 .usb_rx_size (lt_ft2232h_usb_rx_size),
                 .usb_rxbuffer_addr(rxbuffer_addr_a),
                 .usb_rxbuffer_data(rxbuffer_din_a),
                 .usb_rxbuffer_wr(rxbuffer_wr_a),
                 .usb_tx_start (lt_ft2232h_usb_tx_start),
                 .usb_rx_start (lt_ft2232h_usb_rx_start),
                 .usb_rx_done (lt_ft2232h_usb_rx_done));

    /* TX and RX BUFFERS */
    assign txbuffer_wr_a = 0;
    assign txbuffer_din_a = 0;
    ram_dualport #(.RAM_ADDR_WIDTH(BUFFERS_WIDTH),
                   .RAM_DATA_WIDTH(8))
                 txbuffer_ram (.in_clk(sim_clk),
                              .in_addr_a(txbuffer_addr_a),
                              .in_addr_b(txbuffer_addr_b),
                              .out_data_a(txbuffer_dout_a),
                              .out_data_b(txbuffer_dout_b),
                              .in_data_a(txbuffer_din_a),
                              .in_data_b(txbuffer_din_b),
                              .in_wr_a  (txbuffer_wr_a),
                              .in_wr_b  (txbuffer_wr_b));
    
    assign rxbuffer_wr_b = 0;
    assign rxbuffer_din_b = 0;
    ram_dualport #(.RAM_ADDR_WIDTH(BUFFERS_WIDTH),
                   .RAM_DATA_WIDTH(8))
                 rxbuffer_ram (.in_clk(sim_clk),
                              .in_addr_a(rxbuffer_addr_a),
                              .in_addr_b(rxbuffer_addr_b),
                              .out_data_a(rxbuffer_dout_a),
                              .out_data_b(rxbuffer_dout_b),
                              .in_data_a(rxbuffer_din_a),
                              .in_data_b(rxbuffer_din_b),
                              .in_wr_a  (rxbuffer_wr_a),
                              .in_wr_b  (rxbuffer_wr_b));
///////////////////////////////////////////////////////////////////

     
    wire [TOP_TEST_3W_ADDRESS_BITS - 1 : 0] lt_tw_slave_addr;
    reg  [TOP_TEST_3W_DATA_BITS - 1 : 0]    lt_tw_slave_rd_data;
    wire [TOP_TEST_3W_DATA_BITS - 1 : 0]    lt_tw_slave_wr_data;
    wire                                    lt_tw_slave_mode_wr;
    
    /* Threewire slave: lower tester */
    tw_slave  #(.TWS_ADDRESS_BITS(TOP_TEST_3W_ADDRESS_BITS),
                .TWS_DATA_BITS(TOP_TEST_3W_DATA_BITS))
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
        txbuffer_addr_b = 'h00;
        txbuffer_wr_b = 0;
        txbuffer_din_b = 'h00;
        lt_ft2232h_usb_tx_start = 0;
        lt_ft2232h_usb_rx_start = 0;


		#10
		in_reset_n = 0;
		
		#50
		in_reset_n = 1;
       
        /////////////////////////////////////
        //
        Iut_Top_3w_Read('h01AA);

        Iut_Top_3w_Write('h01BB, 'hEFBEADDE);
        
        Iut_Top_3w_Ping();
       
        Iut_Top_3w_Echo('hAA);
        
        ////////////////////////////////////
        lt_ft2232h_usb_rx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 0;
        // Wait 100 ns for global reset to finish
		#10000;
     end

     
    task Iut_Top_3w_Read;
        input [TOP_TEST_3W_ADDRESS_BITS - 1 : 0] address;
    begin : read_proc
        integer i;
        lt_tw_slave_rd_data = 'hAABBCCDD;
        
        lt_ft2232h_usb_tx_size = 1 + TOP_TEST_3W_ADDR_BYTES;
        lt_ft2232h_usb_rx_size = TOP_TEST_3W_DATA_BYTES;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = iut_top.pcl_3wm.CMD_READ;
       
        //send big endian mode
        for (i = 0; i < TOP_TEST_3W_ADDR_BYTES; i= i + 1)
        begin
            txbuffer_ram.data_RAM[i + 1] = 
                address >> ((TOP_TEST_3W_ADDR_BYTES - 1 - i) * 8);
        end

        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
    end
    endtask


    task Iut_Top_3w_Write;
        input [TOP_TEST_3W_ADDRESS_BITS - 1 : 0] address;
        input [TOP_TEST_3W_DATA_BITS - 1 : 0]    wr_data;
    begin : write_proc
        integer i;
        lt_ft2232h_usb_tx_size = 1 + TOP_TEST_3W_ADDR_BYTES + TOP_TEST_3W_DATA_BYTES;
        lt_ft2232h_usb_rx_size = 1;
        
        // write like a boss.
        txbuffer_ram.data_RAM[0] = iut_top.pcl_3wm.CMD_WRITE;
       
        //send big endian mode
        for (i = 0; i < TOP_TEST_3W_ADDR_BYTES; i = i+1)
        begin
            txbuffer_ram.data_RAM[i + 1] = 
                address >> ((TOP_TEST_3W_ADDR_BYTES - 1 - i) * 8);
        end

        for (i = 0; i < TOP_TEST_3W_DATA_BYTES; i = i+1)
        begin
            txbuffer_ram.data_RAM[i + 1 + TOP_TEST_3W_ADDR_BYTES] = 
                        wr_data >> ((TOP_TEST_3W_DATA_BYTES - 1 - i) * 8);
        end 
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
    end
    endtask

    task Iut_Top_3w_Ping;
    begin
        lt_ft2232h_usb_tx_size = 1;
        lt_ft2232h_usb_rx_size = 1;

        lt_ft2232h_usb_tx_data = lt_ft2232h_usb_tx_data & 
                                 ~(('h1 << (lt_ft2232h_usb_tx_size * 8)) - 1);
        lt_ft2232h_usb_tx_data [7:0]    = iut_top.pcl_3wm.CMD_PING;

        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
    end
    endtask

    task Iut_Top_3w_Echo;
        input [7:0] echo_char;
    begin
        /// TEST ECHO.
        lt_ft2232h_usb_tx_size = 2;
        lt_ft2232h_usb_rx_size = 1;

        lt_ft2232h_usb_tx_data = lt_ft2232h_usb_tx_data & 
                                 ~(('h1 << (lt_ft2232h_usb_tx_size * 8)) - 1);
        lt_ft2232h_usb_tx_data [7:0]    = iut_top.pcl_3wm.CMD_ECHO;
        lt_ft2232h_usb_tx_data [15:8]   = echo_char;
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
    
    end
    endtask


    //66MHz
	always #7.5 sim_clk = !sim_clk; 
endmodule

////////////////////////////////////////////////////////
