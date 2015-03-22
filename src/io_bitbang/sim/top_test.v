/**
 * Project: USB-3W FPGA interface  
 * Author:  Marco Vedovati 
 * Date:
 * File:
 *
 */

`timescale 1ns / 1ps

//`include "project_config.v"

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
    
    localparam TOP_TEST_BB_IO_NUM_OF = 8;
    
    localparam TOP_TEST_BB_IO_DATA_BYTES  = `_cdiv(TOP_TEST_BB_IO_NUM_OF, 8);
    localparam TOP_TEST_BB_IO_MASK = ((1 << TOP_TEST_BB_IO_NUM_OF) - 1);
    
    wire [TOP_TEST_BB_IO_NUM_OF - 1 : 0] iut_2_lt_bitbang_wires;

///////////////////////////////////////////////////////////////////
    // Instantiate the Implementation Under Test (IUT)
	top #(.TOP_BB_IO_NUM_OF(TOP_TEST_BB_IO_NUM_OF))
        iut_top (
		.in_ext_osc      (sim_clk), 
		.in_reset_n      (in_reset_n), 
		.out_led         (out_led), 
		.io_ftdi_data    (io_ftdi_data), 
		.in_ftdi_rxf_n   (in_ftdi_rxf_n), 
		.in_ftdi_txe_n   (in_ftdi_txe_n), 
		.out_ftdi_wr_n   (out_ftdi_wr_n), 
		.out_ftdi_rd_n   (out_ftdi_rd_n),
        .io_bitbang_pads (iut_2_lt_bitbang_wires)
	);

///////////////////////////////////////////////////////////////////
    localparam FT2232H_BUFFER_SIZE = 128;
    localparam BUFFERS_WIDTH = `_clog2(FT2232H_BUFFER_SIZE);

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

    reg [TOP_TEST_BB_IO_NUM_OF - 1 : 0] lt_direction;
    reg [TOP_TEST_BB_IO_NUM_OF - 1 : 0] lt_outval;

    pad_monitor pads_mon[TOP_TEST_BB_IO_NUM_OF - 1 : 0] (.dir(lt_direction), 
                                                         .outval(lt_outval), 
                                                         .pad(iut_2_lt_bitbang_wires));
    
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
        //
        $display("================ SIMULATION STARTED ================");
       
        ///
        //
        //
        // 
        //
        
        Iut_Top_Io_Read('b1111);
        $display("====================================================");

        Iut_Top_Io_Write(iut_top.pcl_bb.PARAM_DIRECTION, TOP_TEST_BB_IO_MASK);
        $display("====================================================");
        
        Iut_Top_Io_Write(iut_top.pcl_bb.PARAM_OUTVAL, TOP_TEST_BB_IO_MASK);
        $display("====================================================");
        
        Iut_Top_Io_Write(iut_top.pcl_bb.PARAM_OUTVAL, 'b0011);
        $display("====================================================");
        
        Iut_Top_Io_Write(iut_top.pcl_bb.PARAM_DIRECTION, 'b0011);
        $display("====================================================");
        
        Iut_Top_Io_Read('b1111);
        $display("====================================================");
        
        Iut_Top_Io_Write(iut_top.pcl_bb.PARAM_OUTVAL, 'b0000);
        $display("====================================================");
        
        Iut_Top_Io_Write(iut_top.pcl_bb.PARAM_DIRECTION, 'b1111);
        $display("====================================================");
        
        Iut_Top_3w_Ping();
        $display("====================================================");
       
        Iut_Top_3w_Echo('hAA);
        $display("====================================================");
        
        ////////////////////////////////////
        lt_ft2232h_usb_rx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 0;

        $display("=============== SIMULATION FINISHED ================");
		#1000000;
        $finish;
     end

    task dump_usb_tx;
    begin : dump
        integer i;
        $write(">>>> USB TX size=%d : ", lt_ft2232h_usb_tx_size);
        for (i = 0; i < lt_ft2232h_usb_tx_size; i = i + 1)
        begin
            $write("%x ", txbuffer_ram.data_RAM[i]);
        end
        $display("");
    end
    endtask

    task dump_usb_rx;
    begin : dump
        integer i;
        $write(">>>> USB RX size=%d : ", lt_ft2232h_usb_rx_size);
        for (i = 0; i < lt_ft2232h_usb_rx_size; i = i + 1)
        begin
            $write("%x ", rxbuffer_ram.data_RAM[i]);
        end
        $display("");
    end
    endtask

    /*
     *
     *
     *
     */
    task Iut_Top_Io_Read;
        input [TOP_TEST_BB_IO_NUM_OF - 1 : 0] lt_set_outval;
    begin : read_proc
        integer i;
        integer j;
        integer lt_read_data;
        
        //since iut is reading, we have to feed the slave lt with a value.
        $display("Setting lt monitor pads");
        lt_outval = lt_set_outval;
        
        lt_ft2232h_usb_tx_size = 1;
        lt_ft2232h_usb_rx_size = TOP_TEST_BB_IO_DATA_BYTES;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = iut_top.pcl_bb.CMD_READ;
      
        
        $display(">>>> TX CMD IO RD");
        dump_usb_tx();

        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        $display(">>>> LT RD DATA: %b", lt_outval);
        dump_usb_rx(); 
       /* 
        
        /////for (j = 0; j <= burst_size; j = j + 1)
        begin
            lt_read_data = lt_3w_slave.mem_3w.data_RAM[(address + j) & ADDRESS_MASK];

            for (i = 0; i < TOP_TEST_3W_DATA_BYTES; i = i + 1)
            begin : rx_byte_check
                reg [7:0] rxbyte;
                rxbyte = (lt_read_data >> (8 * (TOP_TEST_3W_DATA_BYTES - 1 - i)));
               
                if (rxbuffer_ram.data_RAM[TOP_TEST_3W_DATA_BYTES*j + i] !== rxbyte)
                begin
                    $display(">>>> FAILED on USB-3W-RD");
                    $display(">>>> DATA IUT: %x LT : %x", rxbuffer_ram.data_RAM[TOP_TEST_3W_DATA_BYTES*j + i], rxbyte);
                    $display(">>>> ADDR IUT: %x LT : %x", address, lt_tw_slave_addr);
                    $display(">>>> MODE LT : %b", lt_slave_mode_wr);
                    $finish;
                end
                else
                begin
                    $display("OK byte idx=%d, burst idx=%d, LT RD DATA=%x", i, j, rxbyte);
                end
            end
        end
        */
    end
    endtask
   
    /*
     *
     *
     *
     */
    task Iut_Top_Io_Write;
        input [7:0] param;
        input [TOP_TEST_BB_IO_NUM_OF - 1 : 0] data;
    begin : write_proc
        integer i;
        integer j;
        integer lt_read_data;
        
        
        lt_ft2232h_usb_tx_size = 2 + TOP_TEST_BB_IO_DATA_BYTES;
        lt_ft2232h_usb_rx_size = TOP_TEST_BB_IO_DATA_BYTES;

        txbuffer_ram.data_RAM[0] = iut_top.pcl_bb.CMD_WRITE;
        txbuffer_ram.data_RAM[1] = param;
      
        for (i = 0; i < TOP_TEST_BB_IO_DATA_BYTES; i = i + 1)
        begin
         txbuffer_ram.data_RAM[2 + i] = data >> ((TOP_TEST_BB_IO_DATA_BYTES - 1 - i) * 8);   
        end


        $display(">>>> TX CMD IO WR");
        dump_usb_tx();

        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        dump_usb_rx(); 
       /* 
        
        /////for (j = 0; j <= burst_size; j = j + 1)
        begin
            lt_read_data = lt_3w_slave.mem_3w.data_RAM[(address + j) & ADDRESS_MASK];

            for (i = 0; i < TOP_TEST_3W_DATA_BYTES; i = i + 1)
            begin : rx_byte_check
                reg [7:0] rxbyte;
                rxbyte = (lt_read_data >> (8 * (TOP_TEST_3W_DATA_BYTES - 1 - i)));
               
                if (rxbuffer_ram.data_RAM[TOP_TEST_3W_DATA_BYTES*j + i] !== rxbyte)
                begin
                    $display(">>>> FAILED on USB-3W-RD");
                    $display(">>>> DATA IUT: %x LT : %x", rxbuffer_ram.data_RAM[TOP_TEST_3W_DATA_BYTES*j + i], rxbyte);
                    $display(">>>> ADDR IUT: %x LT : %x", address, lt_tw_slave_addr);
                    $display(">>>> MODE LT : %b", lt_slave_mode_wr);
                    $finish;
                end
                else
                begin
                    $display("OK byte idx=%d, burst idx=%d, LT RD DATA=%x", i, j, rxbyte);
                end
            end
        end
        */
    end
    endtask
 
    task Iut_Top_3w_Ping;
    begin
        lt_ft2232h_usb_tx_size = 1;
        lt_ft2232h_usb_rx_size = 1;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = iut_top.pcl_bb.CMD_PING;
        
        $display(">>>> TX CMD PING");
        dump_usb_tx();
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        dump_usb_rx();

        if (rxbuffer_ram.data_RAM[0] !== iut_top.pcl_bb.CMD_OK)
        begin
            $display(">>>> FAILED on USB-CMD-PING rxdata=%x", rxbuffer_ram.data_RAM[0]);
            $finish;
        end
    end
    endtask

    task Iut_Top_3w_Echo;
        input [7:0] echo_char;
    begin
        /// TEST ECHO.
        lt_ft2232h_usb_tx_size = 2;
        lt_ft2232h_usb_rx_size = 1;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = iut_top.pcl_bb.CMD_ECHO;
        txbuffer_ram.data_RAM[1] = echo_char;
        
        $display(">>>> TX CMD ECHO CHAR=%x", echo_char);
        dump_usb_tx();
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);

        dump_usb_rx();

        if (rxbuffer_ram.data_RAM[0] !== echo_char)
        begin
            $display(">>>> FAILED on USB-CMD-ECHO expected=%x rxdata=%x", echo_char, rxbuffer_ram.data_RAM[0]);
            $finish;
        end
    
    end
    endtask

    always @(iut_top.pcl_bb.bb_direction)
    begin
        lt_direction = iut_top.pcl_bb.bb_direction ^ TOP_TEST_BB_IO_MASK;
    end

    //66MHz
	always #7.5 sim_clk = !sim_clk; 
endmodule

////////////////////////////////////////////////////////
