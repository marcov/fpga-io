/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

`timescale 1ns / 1ps

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
    `include "project_config.v"
    
    localparam TOP_TEST_3W_ADDRESS_BITS = `THREEWIRE_MAX_ADDRESS_BITS;
    localparam TOP_TEST_3W_DATA_BITS    = `THREEWIRE_MAX_DATA_BITS;
    localparam TOP_TEST_3W_CLK_DIV      = `THREEWIRE_MAX_CLK_DIV;
    localparam TOP_TEST_3W_ADDRESS_BITS_WIDTH = `_clog2(TOP_TEST_3W_ADDRESS_BITS);
    localparam TOP_TEST_3W_DATA_BITS_WIDTH    = `_clog2(TOP_TEST_3W_DATA_BITS);
    localparam TOP_TEST_3W_CLK_DIV_EXP2       = `_clog2(TOP_TEST_3W_CLK_DIV);
    localparam TOP_TEST_3W_CLK_DIV_EXP2_WIDTH = `_clog2(TOP_TEST_3W_CLK_DIV_EXP2);
`ifndef SIMULATION_SEED_INITIAL
    localparam TOP_TEST_SEED = 123;
`else
    localparam TOP_TEST_SEED = `SIMULATION_SEED_INITIAL;
`endif

    localparam TOP_TEST_3W_ADDR_BYTES  = `_cdiv(TOP_TEST_3W_ADDRESS_BITS, 8);
    localparam TOP_TEST_3W_DATA_BYTES  = `_cdiv(TOP_TEST_3W_DATA_BITS, 8);
///////////////////////////////////////////////////////////////////
    // Instantiate the Implementation Under Test (IUT)
	top #(.TOP_3W_ADDRESS_BITS(TOP_TEST_3W_ADDRESS_BITS),
          .TOP_3W_DATA_BITS   (TOP_TEST_3W_DATA_BITS),
          .TOP_3W_CLK_DIV     (TOP_TEST_3W_CLK_DIV))
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
    reg  [TOP_TEST_3W_ADDRESS_BITS_WIDTH : 0] top_test_addr_bits;
    reg  [TOP_TEST_3W_DATA_BITS_WIDTH    : 0] top_test_data_bits;
    reg  [TOP_TEST_3W_CLK_DIV_EXP2_WIDTH : 0] top_test_clk_div_exp2;

    /* Threewire slave: lower tester */
    tw_slave  #(.TWS_ADDRESS_BITS(TOP_TEST_3W_ADDRESS_BITS),
                .TWS_DATA_BITS(TOP_TEST_3W_DATA_BITS),
                .TWS_ADDRESS_BITS_WIDTH(TOP_TEST_3W_ADDRESS_BITS_WIDTH),
                .TWS_DATA_BITS_WIDTH(TOP_TEST_3W_DATA_BITS_WIDTH))
             lt_3w_slave(
                .in_clk(sim_clk),
                .tw_bus_clock(tw_bus_clock),
                .tw_bus_chipselect(tw_bus_chipselect),
                .tw_bus_data(tw_bus_data),
                .addr_bits(top_test_addr_bits),
                .data_bits(top_test_data_bits),
                .address(lt_tw_slave_addr),
                .mode_wr(lt_slave_mode_wr));

///////////////////////////////////////////////////////////////////
    initial
     begin : initial_block
        integer seed;
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
      
        top_test_addr_bits = 'd10;
        top_test_data_bits = 'd16;
        seed = TOP_TEST_SEED;
        top_test_clk_div_exp2 = 'h1;

`ifdef SIM_RUN_ALL_ADDR_DATA_BITS 
        begin : rd_test_all_addr_data_bits 
            
            for (top_test_data_bits = 'd1; 
                 top_test_data_bits <= TOP_TEST_3W_DATA_BITS;   
                 top_test_data_bits = top_test_data_bits + 1)
             begin
                 for (top_test_addr_bits = 'd1; 
                     top_test_addr_bits <= TOP_TEST_3W_ADDRESS_BITS;   
                     top_test_addr_bits = top_test_addr_bits + 1)
                 begin
                    Iut_Top_3w_Set_Io_Bits(top_test_addr_bits, 
                                           top_test_data_bits,
                                           top_test_clk_div_exp2);
                    $display("====================================================");
                   
                    Iut_Top_3w_Read($random(seed), 0, seed);
                    seed = seed + 1;
                    $display("====================================================");
                 end
             end
        end
`else
        // Run just for well known values.
        top_test_addr_bits = `THREEWIRE_FM_ADDRESS_BITS;
        top_test_data_bits = `THREEWIRE_FM_DATA_BITS;

        Iut_Top_3w_Set_Io_Bits(top_test_addr_bits,
                               top_test_data_bits,
                               top_test_clk_div_exp2);
        $display("====================================================");
       
        Iut_Top_3w_Read($random(seed), 0, seed);
        seed = seed + 1;
        $display("====================================================");
        
        top_test_addr_bits = `THREEWIRE_NFC_ADDRESS_BITS;
        top_test_data_bits = `THREEWIRE_NFC_DATA_BITS;

        Iut_Top_3w_Set_Io_Bits(top_test_addr_bits,
                               top_test_data_bits,
                               top_test_clk_div_exp2);
        $display("====================================================");
       
        Iut_Top_3w_Read($random(seed), 0, seed);
        seed = seed + 1;
        $display("====================================================");
`endif

`ifdef THREEWIRE_HAS_BURST
        top_test_addr_bits = 'd10;
        top_test_data_bits = 'd16;
        Iut_Top_3w_Set_Io_Bits(top_test_addr_bits,
                               top_test_data_bits,
                               top_test_clk_div_exp2);
        $display("====================================================");
        
        begin : rd_test_burst
            integer i;
            reg [63:0] address;
            
            address = $random(seed);
            
            for (i = 1; i < 10; i = i + 1)
            begin
                Iut_Top_3w_Read(address, i, seed);
                seed = seed + 1;
                address = address + 1;
                $display("====================================================");
            end
        end
`endif

`ifdef SIM_RUN_ALL_ADDR_DATA_BITS
        begin : wr_test_all_addr_data_bits 
            
            for (top_test_data_bits = 'd1; 
                 top_test_data_bits <= TOP_TEST_3W_DATA_BITS;   
                 top_test_data_bits = top_test_data_bits + 1)
             begin
                 for (top_test_addr_bits = 'd1; 
                     top_test_addr_bits <= TOP_TEST_3W_ADDRESS_BITS;   
                     top_test_addr_bits = top_test_addr_bits + 1)
                 begin
                    Iut_Top_3w_Set_Io_Bits(top_test_addr_bits,
                                           top_test_data_bits,
                                           top_test_clk_div_exp2);
                    $display("====================================================");
                   

                    Iut_Top_3w_Write($random(seed), 0, seed);
                    seed = seed + 1;
                    $display("====================================================");
                 end
             end
        end
`else
        // Run just for well known values.
        top_test_addr_bits = `THREEWIRE_FM_ADDRESS_BITS;
        top_test_data_bits = `THREEWIRE_FM_DATA_BITS;
        Iut_Top_3w_Set_Io_Bits(top_test_addr_bits,
                               top_test_data_bits,
                               top_test_clk_div_exp2);
        $display("====================================================");
       

        Iut_Top_3w_Write($random(seed), 0, seed);
        seed = seed + 1;
        $display("====================================================");
        
        top_test_addr_bits = `THREEWIRE_NFC_ADDRESS_BITS;
        top_test_data_bits = `THREEWIRE_NFC_DATA_BITS;
        Iut_Top_3w_Set_Io_Bits(top_test_addr_bits,
                               top_test_data_bits,
                               top_test_clk_div_exp2);
        $display("====================================================");
       

        Iut_Top_3w_Write($random(seed), 0, seed);
        seed = seed + 1;
        $display("====================================================");
`endif
        
`ifdef THREEWIRE_HAS_BURST
        begin : wr_test_burst
            integer i;
            integer seed;
            reg [63:0] address;
            
            top_test_addr_bits = 'd10;
            top_test_data_bits = 'd16;
            Iut_Top_3w_Set_Io_Bits(top_test_addr_bits,
                                   top_test_data_bits,
                                   top_test_clk_div_exp2);
            $display("====================================================");
            
            address = $random(seed);
            
            for (i = 1; i < 10; i = i + 1)
            begin
                Iut_Top_3w_Write(address, i, seed);
                seed = seed + 1;
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
        integer i;
        integer j;
        integer addr_offset;
        reg [63:0] lt_read_data;
        reg [TOP_TEST_3W_DATA_BITS - 1 : 0]    lt_test_vector [0 : 31];
        reg [63:0] addr_bytes;
        reg [63:0] data_bytes;
        reg [63:0] address_mask;
        reg [63:0] data_mask;
        
        addr_bytes = `_cdiv8(top_test_addr_bits);
        data_bytes = `_cdiv8(top_test_data_bits);
        address_mask = ((1<<top_test_addr_bits) - 1);
        data_mask    = ((1<<top_test_data_bits) - 1);

        addr_offset = 1 + (burst_size > 0 ? 1 : 0);
       
        seed = $random(seed);

        //since iut is reading, we have to feed the slave lt with a value.
        for (i = 0 ; i < burst_size + 1; i= i + 1)
        begin
            // Fill test vector
            lt_test_vector[i] = ($random(seed)|$random(seed)<<32) & data_mask;
            lt_3w_slave.mem_3w.data_RAM[(address + i) & address_mask] = lt_test_vector[i];
            /*
            $display("Filling mem_3w slave addr=%x data=%x",
                     (address + i) & address_mask,
                     lt_3w_slave.mem_3w.data_RAM[(address + i) & address_mask]);
            */
        end
        
        lt_ft2232h_usb_tx_size = addr_offset + addr_bytes;
        lt_ft2232h_usb_rx_size = (1 + burst_size) * data_bytes;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = (burst_size > 0 ? 8'h80 : 8'h00) | iut_top.pcl_3wm.CMD_READ;
      
        if (burst_size > 0)
        begin
            txbuffer_ram.data_RAM[1] = burst_size;
        end
        
        //send big endian mode
        for (i = 0; i < addr_bytes; i= i + 1)
        begin
            txbuffer_ram.data_RAM[i + addr_offset] = 
                (address&address_mask) >> ((addr_bytes - 1 - i) * 8);
        end
        
        $display(">>>> TX CMD 3W RD BURST=%d N_ADDR_BITS=%d N_DATA_BITS=%d", 
                 burst_size,
                top_test_addr_bits,
                top_test_data_bits);
        dump_usb_tx();

        lt_ft2232h_usb_tx_start = 1;
        #1
        lt_ft2232h_usb_rx_start = 1;
        lt_ft2232h_usb_tx_start = 0;
        #1
        lt_ft2232h_usb_rx_start = 0;
        wait(lt_ft2232h_usb_rx_done);
        
        dump_usb_rx(); 
       
        
        if (lt_slave_mode_wr !== 0 || (address&address_mask) !== lt_tw_slave_addr)
        begin
            $display(">>>> FAILED on USB-3W-RD");
            $display(">>>> ADDR IUT: %x LT : %x", 
                     (address & address_mask), 
                     lt_tw_slave_addr);
            $display(">>>> MODE LT : %b", lt_slave_mode_wr);
            $finish;
        end

        for (j = 0; j <= burst_size; j = j + 1)
        begin
            lt_read_data = lt_3w_slave.mem_3w.data_RAM[(address + j) & address_mask];

            for (i = 0; i < data_bytes; i = i + 1)
            begin : rx_byte_check
                reg [7:0] rxbyte;
                rxbyte = (lt_read_data >> (8 * (data_bytes - 1 - i)));
               
                if (rxbuffer_ram.data_RAM[data_bytes*j + i] !== rxbyte)
                begin
                    $display(">>>> FAILED on USB-3W-RD");
                    $display(">>>> DATA IUT: %x LT : %x", 
                             rxbuffer_ram.data_RAM[TOP_TEST_3W_DATA_BYTES*j + i], rxbyte);
                    $display(">>>> ADDR IUT: %x LT : %x", (address&address_mask), lt_tw_slave_addr);
                    $display(">>>> MODE LT : %b", lt_slave_mode_wr);
                    $finish;
                end
                else
                begin
                    //$display("OK byte idx=%d, burst idx=%d, LT RD DATA=%x", i, j, rxbyte);
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
        integer i, j;
        integer wr_data_offset;
        reg [63:0] lt_written_data;
        reg [TOP_TEST_3W_DATA_BITS - 1 : 0]    iut_test_vector [0 : 31];
        reg [63:0] addr_bytes;
        reg [63:0] data_bytes;
        reg [63:0] address_mask;
        reg [63:0] data_mask;
        
        addr_bytes = `_cdiv8(top_test_addr_bits);
        data_bytes = `_cdiv8(top_test_data_bits);
        address_mask = ((1<<top_test_addr_bits) - 1);
        data_mask    = ((1<<top_test_data_bits) - 1);
        
        wr_data_offset = 1 + (burst_size > 0 ? 1 : 0) + addr_bytes;
        
        seed = $random(seed);
        
        for (i = 0 ; i < burst_size + 1; i= i + 1)
        begin
            // Fill test vector
            iut_test_vector[i] = ($random(seed)|($random(seed)<<32))& data_mask;
            /*
            $display("Filling iut test vector addr=%x data=%x",
                     (address + i) & address_mask,
                     iut_test_vector[i]);
            */
        end

        lt_ft2232h_usb_tx_size = wr_data_offset + (1 + burst_size) * data_bytes;
        lt_ft2232h_usb_rx_size = 1;
        
        // write like a boss.
        txbuffer_ram.data_RAM[0] = (burst_size > 0 ? 8'h80 : 8'h00) | iut_top.pcl_3wm.CMD_WRITE;
      
        if (burst_size > 0)
        begin
            txbuffer_ram.data_RAM[1] = burst_size;
        end

        //send big endian mode
        for (i = 0; i < addr_bytes; i = i+1)
        begin
           txbuffer_ram.data_RAM[i + 1 + (burst_size > 0 ? 1 : 0)] = 
                (address&address_mask) >> ((addr_bytes - 1 - i) * 8);
        end

        for (j = 0; j <= burst_size; j = j + 1)
        begin
            // Should fill all buffer here with burst data! 
            for (i = 0; i < data_bytes; i = i+1)
            begin
                txbuffer_ram.data_RAM[(wr_data_offset + i + data_bytes*j)] = 
                            iut_test_vector[j] >> ((data_bytes - 1 - i) * 8);
                
            end 
        end 
        
        $display(">>>> TX CMD 3W WR BURST=%d N_ADDR_BITS=%d N_DATA_BITS=%d", 
                 burst_size,
                top_test_addr_bits,
                top_test_data_bits);
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
            $display(">>>> LT WRITTEN addr=%x data=%x",
                ((address + i) & address_mask),
                lt_3w_slave.mem_3w.data_RAM[(address + i) & address_mask]);
        end
        dump_usb_rx(); 
        
        if (lt_slave_mode_wr !== 1 || (address&address_mask) !== lt_tw_slave_addr)
        begin
            $display(">>>> FAILED on USB-3W-WR");
            $display(">>>> ADDR IUT: %x LT : %x", (address&address_mask), lt_tw_slave_addr);
            $display(">>>> MODE LT : %b", lt_slave_mode_wr);
            $finish;
        end

        for (j = 0; j <= burst_size; j = j + 1)
        begin
            lt_written_data = lt_3w_slave.mem_3w.data_RAM[(address + j) & address_mask];

            for (i = 0; i < data_bytes; i = i + 1)
            begin : tx_byte_check
                reg [7:0] txbyte;
                txbyte = (lt_written_data >> (8 * (data_bytes - 1 - i)));
               
                if (txbuffer_ram.data_RAM[wr_data_offset + data_bytes*j + i] !== txbyte)
                begin
                    $display(">>>> FAILED on USB-3W-WR");
                    $display(">>>> DATA IUT: %x LT : %x",
                             txbuffer_ram.data_RAM[TOP_TEST_3W_DATA_BYTES*j + i], txbyte);
                    $display(">>>> ADDR IUT: %x LT : %x", (address&address_mask), lt_tw_slave_addr);
                    $display(">>>> MODE LT : %b", lt_slave_mode_wr);
                    $finish;
                end
                else
                begin
                    //$display("OK byte idx=%d, burst idx=%d, LT WR DATA=%x", i, j, txbyte);
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


    task Iut_Top_3w_Set_Io_Bits;
        input integer address_bits;
        input integer data_bits;
        input integer clk_div_exp2;
    begin
        /// Set Address and Data bits
        lt_ft2232h_usb_tx_size = 4;
        lt_ft2232h_usb_rx_size = 1;

        // write like a boss.
        txbuffer_ram.data_RAM[0] = iut_top.pcl_3wm.CMD_SET_IO_BITS;
        txbuffer_ram.data_RAM[1] = address_bits;
        txbuffer_ram.data_RAM[2] = data_bits;
        txbuffer_ram.data_RAM[3] = clk_div_exp2;
        
        $display(">>>> TX CMD SET IO BITS: addr=%x data=%x", address_bits, data_bits);
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
            $display(">>>> FAILED on USB-CMD_SET_IO_BITS rxdata=%x", rxbuffer_ram.data_RAM[0]);
            $finish;
        end
        
        if (iut_top.pcl_3wm.addr_bits !== address_bits ||
            iut_top.pcl_3wm.data_bits !== data_bits)
        begin
            $display(">>>> FAILED on USB-CMD_SET_IO_BITS");
            $display("Txed addr=%s, data=%x - Rcved addr=%x data=%x",
                     address_bits, data_bits, 
                     iut_top.pcl_3wm.addr_bits, iut_top.pcl_3wm.data_bits);
            $finish;
        end
    
    end
    endtask
    //66MHz
	always #7.5 sim_clk = !sim_clk; 
endmodule

////////////////////////////////////////////////////////
