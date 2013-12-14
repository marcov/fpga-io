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

    
    localparam TOP_TEST_3W_ADDR_BYTES  = `_cdiv(TOP_TEST_3W_ADDRESS_BITS, 8);
    localparam TOP_TEST_3W_DATA_BYTES  = `_cdiv(TOP_TEST_3W_DATA_BITS, 8);
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

     
    wire [TOP_TEST_3W_ADDRESS_BITS - 1 : 0] lt_tw_slave_addr;
    wire                                    lt_tw_slave_mode_wr;
    
    /* Threewire slave: lower tester */
    tw_slave  #(.TWS_ADDRESS_BITS(TOP_TEST_3W_ADDRESS_BITS),
                .TWS_DATA_BITS(TOP_TEST_3W_DATA_BITS))
             lt_3w_slave(
                .in_clk(sim_clk),
                .tw_bus_clock(tw_bus_clock),
                .tw_bus_chipselect(tw_bus_chipselect),
                .tw_bus_data(tw_bus_data),
                .address(lt_tw_slave_addr),
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
        //
        $display("================ SIMULATION STARTED ================");
        
        Iut_Top_3w_Read('h01AA, 0, 1);
        $display("====================================================");
`ifdef THREEWIRE_HAS_BURST
        begin :extra_test_rd
            integer i;
            integer seed;
            integer address;
            
            address = 'h01BB;
            seed = 1;
            
            for (i = 1; i < 10; i = i + 1)
            begin
                Iut_Top_3w_Read(address, i, seed);
                address = address + 1;
                $display("====================================================");
            end
        end
`endif

        Iut_Top_3w_Write('h01BB, 0, 5);
        $display("====================================================");
`ifdef THREEWIRE_HAS_BURST
        begin :extra_test_wr
            integer i;
            integer seed;
            integer address;
            
            address = 'h01FA;
            seed = 2;
            
            for (i = 1; i < 10; i = i + 1)
            begin
                Iut_Top_3w_Write(address, i, seed);
                address = address + 1;
                $display("====================================================");
            end
        end
`endif
        
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

    task Iut_Top_3w_Read;
        input [TOP_TEST_3W_ADDRESS_BITS - 1 : 0] address;
        input [5 - 1 : 0] burst_size;
        input integer seed;
    begin : read_proc
        localparam ADDRESS_MASK = ((1<<TOP_TEST_3W_ADDRESS_BITS) - 1);
        integer i;
        integer j;
        integer addr_offset;
        integer lt_read_data;
        reg [TOP_TEST_3W_DATA_BITS - 1 : 0]    lt_test_vector [0 : 31];
        
        addr_offset = 1 + (burst_size > 0 ? 1 : 0);
        
        //since iut is reading, we have to feed the slave lt with a value.
        for (i = 0 ; i < burst_size + 1; i= i + 1)
        begin
            // Fill test vector
            $display("Filling mem_3w slave");
            lt_test_vector[i] = $random(seed) % ((1<<TOP_TEST_3W_DATA_BITS) - 1);
            lt_3w_slave.mem_3w.data_RAM[(address + i) & ADDRESS_MASK] = lt_test_vector[i];
        end
        
        lt_ft2232h_usb_tx_size = addr_offset + TOP_TEST_3W_ADDR_BYTES;
        lt_ft2232h_usb_rx_size = (1 + burst_size) * TOP_TEST_3W_DATA_BYTES;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = (burst_size > 0 ? 8'h80 : 8'h00) | iut_top.pcl_3wm.CMD_READ;
      
        if (burst_size > 0)
        begin
            txbuffer_ram.data_RAM[1] = burst_size;
        end
        
        //send big endian mode
        for (i = 0; i < TOP_TEST_3W_ADDR_BYTES; i= i + 1)
        begin
            txbuffer_ram.data_RAM[i + addr_offset] = 
                address >> ((TOP_TEST_3W_ADDR_BYTES - 1 - i) * 8);
        end
        
        $display(">>>> TX CMD 3W RD BURST=%d", burst_size);
        dump_usb_tx();

        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        for (i = 0 ; i < burst_size + 1; i= i + 1)
        begin
            $display(">>>> LT RD DATA: %x", lt_test_vector[i]);
        end
        dump_usb_rx(); 
       
        
        if (lt_slave_mode_wr !== 0 || address !== lt_tw_slave_addr)
        begin
            $display(">>>> FAILED on USB-3W-RD");
            $display(">>>> ADDR IUT: %x LT : %x", address, lt_tw_slave_addr);
            $display(">>>> MODE LT : %b", lt_slave_mode_wr);
        end

        for (j = 0; j <= burst_size; j = j + 1)
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
    end
    endtask


    task Iut_Top_3w_Write;
        input [TOP_TEST_3W_ADDRESS_BITS - 1 : 0] address;
        input [5 - 1 : 0] burst_size;
        input integer seed;
    begin : write_proc
        localparam ADDRESS_MASK = ((1<<TOP_TEST_3W_ADDRESS_BITS) - 1);
        integer i, j;
        integer wr_data_offset;
        integer lt_written_data;
        reg [TOP_TEST_3W_DATA_BITS - 1 : 0]    iut_test_vector [0 : 31];
        
        for (i = 0 ; i < burst_size + 1; i= i + 1)
        begin
            // Fill test vector
            $display("Filling iut test vector");
            iut_test_vector[i] = $random(seed) % ((1<<TOP_TEST_3W_DATA_BITS) - 1);
        end

        wr_data_offset = 1 + (burst_size > 0 ? 1 : 0) + TOP_TEST_3W_ADDR_BYTES;

        lt_ft2232h_usb_tx_size = wr_data_offset + (1 + burst_size) * TOP_TEST_3W_DATA_BYTES;
        lt_ft2232h_usb_rx_size = 1;
        
        // write like a boss.
        txbuffer_ram.data_RAM[0] = (burst_size > 0 ? 8'h80 : 8'h00) | iut_top.pcl_3wm.CMD_WRITE;
      
        if (burst_size > 0)
        begin
            txbuffer_ram.data_RAM[1] = burst_size;
        end

        //send big endian mode
        for (i = 0; i < TOP_TEST_3W_ADDR_BYTES; i = i+1)
        begin
           txbuffer_ram.data_RAM[i + 1 + (burst_size > 0 ? 1 : 0)] = 
                address >> ((TOP_TEST_3W_ADDR_BYTES - 1 - i) * 8);
        end

        for (j = 0; j <= burst_size; j = j + 1)
        begin
            // Should fill all buffer here with burst data! 
            for (i = 0; i < TOP_TEST_3W_DATA_BYTES; i = i+1)
            begin
                txbuffer_ram.data_RAM[wr_data_offset + i + TOP_TEST_3W_DATA_BYTES*j] = 
                            iut_test_vector[j] >> ((TOP_TEST_3W_DATA_BYTES - 1 - i) * 8);
            end 
        end 
        
        $display(">>>> TX CMD 3W WR BURST=%d", burst_size);
        dump_usb_tx();
        
        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);

        
        for (i = 0 ; i < burst_size + 1; i= i + 1)
        begin
            $display(">>>> LT WR DATA: %x", 
                lt_3w_slave.mem_3w.data_RAM[(address + i) & ADDRESS_MASK]);
        end
        dump_usb_rx(); 
        
        if (lt_slave_mode_wr !== 1 || address !== lt_tw_slave_addr)
        begin
            $display(">>>> FAILED on USB-3W-WR");
            $display(">>>> ADDR IUT: %x LT : %x", address, lt_tw_slave_addr);
            $display(">>>> MODE LT : %b", lt_slave_mode_wr);
        end

        for (j = 0; j <= burst_size; j = j + 1)
        begin
            lt_written_data = lt_3w_slave.mem_3w.data_RAM[(address + j) & ADDRESS_MASK];

            for (i = 0; i < TOP_TEST_3W_DATA_BYTES; i = i + 1)
            begin : tx_byte_check
                reg [7:0] txbyte;
                txbyte = (lt_written_data >> (8 * (TOP_TEST_3W_DATA_BYTES - 1 - i)));
               
                if (txbuffer_ram.data_RAM[wr_data_offset + TOP_TEST_3W_DATA_BYTES*j + i] !== txbyte)
                begin
                    $display(">>>> FAILED on USB-3W-WR");
                    $display(">>>> DATA IUT: %x LT : %x", txbuffer_ram.data_RAM[TOP_TEST_3W_DATA_BYTES*j + i], txbyte);
                    $display(">>>> ADDR IUT: %x LT : %x", address, lt_tw_slave_addr);
                    $display(">>>> MODE LT : %b", lt_slave_mode_wr);
                    $finish;
                end
                else
                begin
                    $display("OK byte idx=%d, burst idx=%d, LT WR DATA=%x", i, j, txbyte);
                end
            
            end
        end
    end
    endtask

    task Iut_Top_3w_Ping;
    begin
        lt_ft2232h_usb_tx_size = 1;
        lt_ft2232h_usb_rx_size = 1;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = iut_top.pcl_3wm.CMD_PING;
        
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

        if (rxbuffer_ram.data_RAM[0] !== iut_top.pcl_3wm.CMD_OK)
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
        txbuffer_ram.data_RAM[0] = iut_top.pcl_3wm.CMD_ECHO;
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


    //66MHz
	always #7.5 sim_clk = !sim_clk; 
endmodule

////////////////////////////////////////////////////////
