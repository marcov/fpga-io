/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

`timescale 1ns / 1ps

module threewire_testbench;

    `include "builtins_redefined.v"
    `include "project_config.v"

    reg sim_clk;
    reg rst;
    reg iut_start;
    reg iut_mode_wr;
   
    parameter IUT_3W_MAX_ADDRESS_BITS = `THREEWIRE_MAX_ADDRESS_BITS;
    parameter IUT_3W_MAX_DATA_BITS    = `THREEWIRE_MAX_DATA_BITS;
    parameter IUT_3W_MIN_ADDRESS_BITS = `THREEWIRE_MIN_ADDRESS_BITS;
    parameter IUT_3W_MIN_DATA_BITS    = `THREEWIRE_MIN_DATA_BITS;
    parameter IUT_3W_CLK_DIV_EXP2_MIN = `_clog2(`THREEWIRE_MIN_CLK_DIV);
    parameter IUT_3W_CLK_DIV_EXP2_MAX = `_clog2(`THREEWIRE_MAX_CLK_DIV);
    parameter IUT_3W_CLK_DIV_EXP2_WIDTH = `_clog2(IUT_3W_CLK_DIV_EXP2_MAX);
    parameter IUT_3W_BURST_MAX  = 127;
    localparam IUT_3W_BURST_WIDTH = `_clog2(IUT_3W_BURST_MAX);
    localparam IUT_3W_DATA_BITS_WIDTH = `_clog2(IUT_3W_MAX_DATA_BITS);
    localparam IUT_3W_ADDR_BITS_WIDTH = `_clog2(IUT_3W_MAX_ADDRESS_BITS);
`ifndef SIMULATION_SEED_INITIAL
    localparam TOP_TEST_SEED = 123;
`else
    localparam TOP_TEST_SEED = `SIMULATION_SEED_INITIAL;
`endif
    /////////////////////////////////////////////////////////////////////////////////

    reg  [IUT_3W_MAX_ADDRESS_BITS - 1 : 0] iut_address;
    
    wire [IUT_3W_MAX_ADDRESS_BITS - 1 : 0] lt_tw_slave_addr;
    wire                            lt_tw_slave_mode_wr;

    wire [IUT_3W_BURST_WIDTH - 1:0] mem_addr_a;
    wire [IUT_3W_MAX_DATA_BITS - 1 : 0] mem_din_a;
    wire [IUT_3W_MAX_DATA_BITS - 1 : 0] mem_dout_a;
    wire mem_wr_a;
    reg  [IUT_3W_BURST_WIDTH - 1:0] mem_addr_b;
    wire [IUT_3W_MAX_DATA_BITS - 1 : 0] mem_din_b;
    wire [IUT_3W_MAX_DATA_BITS - 1 : 0] mem_dout_b;
    reg  mem_wr_b;
    reg [IUT_3W_BURST_WIDTH - 1:0] iut_burst_reps;
    reg [IUT_3W_ADDR_BITS_WIDTH : 0] tw_test_addr_bits;
    reg [IUT_3W_DATA_BITS_WIDTH : 0] tw_test_data_bits;
    reg [IUT_3W_CLK_DIV_EXP2_WIDTH : 0] tw_test_clk_div_exp2;
    /////////////////////////////////////////////////////////////////////////////////


    /* Threewire master: implementation under test */
    threewire_master_ctrl #(
                .TWM_ADDRESS_BITS(IUT_3W_MAX_ADDRESS_BITS),
                .TWM_DATA_BITS(IUT_3W_MAX_DATA_BITS),
                .TWM_ADDRESS_BITS_WIDTH(IUT_3W_ADDR_BITS_WIDTH),
                .TWM_DATA_BITS_WIDTH(IUT_3W_DATA_BITS_WIDTH),
                .TWM_CLK_DIV_EXP2_WIDTH(IUT_3W_CLK_DIV_EXP2_WIDTH),
                .TWM_BURST_WIDTH(IUT_3W_BURST_WIDTH))
            iut_3w_master ( 
                .in_clk(sim_clk),
                .in_rst(rst),
                .in_mode_wr(iut_mode_wr),
                .in_addr(iut_address),
                .in_burst_reps(iut_burst_reps),
                .out_mem_addr(mem_addr_a),
                .out_mem_data(mem_din_a),
                .in_mem_data (mem_dout_a),
                .out_mem_wr  (mem_wr_a),
                .addr_bits(tw_test_addr_bits),
                .data_bits(tw_test_data_bits),
                .in_clk_div_exp2(tw_test_clk_div_exp2),
                .in_start(iut_start),
                .out_io_in_progress(active),
                .out_tw_clock(tw_bus_clock),
                .out_tw_cs(tw_bus_chipselect),
                .io_tw_data(tw_bus_data),
                .out_tw_dir(tw_bus_dir));
    
    ram_dualport #(.RAM_ADDR_WIDTH(IUT_3W_BURST_WIDTH),
                   .RAM_DATA_WIDTH(IUT_3W_MAX_DATA_BITS))
                 mem_3w      (.in_clk(sim_clk),
                              .in_addr_a(mem_addr_a),
                              .in_addr_b(mem_addr_b),
                              .out_data_a(mem_dout_a),
                              .out_data_b(mem_dout_b),
                              .in_data_a(mem_din_a),
                              .in_data_b(mem_din_b),
                              .in_wr_a  (mem_wr_a),
                              .in_wr_b  (mem_wr_b));

    /* Threewire slave: lower tester */
    tw_slave  #(.TWS_ADDRESS_BITS(IUT_3W_MAX_ADDRESS_BITS),
                .TWS_DATA_BITS(IUT_3W_MAX_DATA_BITS))
             lt_3w_slave(
                .in_clk(sim_clk),
                .tw_bus_clock(tw_bus_clock),
                .tw_bus_chipselect(tw_bus_chipselect),
                .tw_bus_data(tw_bus_data),
                .addr_bits(tw_test_addr_bits),
                .data_bits(tw_test_data_bits),
                .address(lt_tw_slave_addr),
                .mode_wr(lt_slave_mode_wr));

    reg  [IUT_3W_MAX_ADDRESS_BITS - 1 : 0] t_addr;
    reg  [IUT_3W_MAX_DATA_BITS - 1 : 0] t_data;
    initial begin : main_block
        integer seed;
        #0
        $dumpfile("test.lxt");
        $dumpvars(0, threewire_testbench);
        sim_clk = 0;
        rst = 0;
        iut_start = 0;
        mem_wr_b = 0; 
        iut_burst_reps = 0;
        tw_test_data_bits = 0;
        tw_test_addr_bits = 0;
        //////////////////////////
        #25
        rst = 1;
        #25
        rst = 0;

        tw_test_clk_div_exp2 = 4; 

        $display("================ SIMULATION STARTED ================");
        seed = TOP_TEST_SEED;
        
`ifdef SIM_RUN_ALL_ADDR_DATA_BITS
        begin : rd_wr_test_all_addr_data_bits 
            
            for (iut_burst_reps = 0;
                 iut_burst_reps < IUT_3W_BURST_MAX;
                 iut_burst_reps = iut_burst_reps + 1)
            begin
                for (tw_test_data_bits = THREEWIRE_MIN_DATA_BITS; 
                     tw_test_data_bits <= IUT_3W_MAX_DATA_BITS;   
                     tw_test_data_bits = tw_test_data_bits + 1)
                begin
                    for (tw_test_addr_bits = IUT_3W_MIN_ADDRESS_BITS; 
                         tw_test_addr_bits <= IUT_3W_MAX_ADDRESS_BITS;   
                         tw_test_addr_bits = tw_test_addr_bits + 1)
                    begin
                       $display(">>>> RUN: burst=%d addr=%d data=%d", 
                                iut_burst_reps,
                                tw_test_addr_bits, 
                                tw_test_data_bits);
                       t_addr = $random(seed) & ((1<<tw_test_addr_bits) - 1);
                       seed = seed + 1;
                       seed = seed + 1;

                       Iut_3wm_Read(t_addr, iut_burst_reps, seed);
                       $display("====================================================");
                       Iut_3wm_Write(t_addr, iut_burst_reps, seed);
                       $display("====================================================");
                    end
                end
            end
        end
`else
         // Run just for well known cases
        for (iut_burst_reps = 0;
             iut_burst_reps < 8;
             iut_burst_reps = iut_burst_reps + 1)
        begin
            tw_test_addr_bits = `THREEWIRE_FM_ADDRESS_BITS;
            tw_test_data_bits = `THREEWIRE_FM_DATA_BITS;
            t_addr = $random(seed) & ((1<<tw_test_addr_bits) - 1);

            Iut_3wm_Read(t_addr, iut_burst_reps, seed);
            $display("====================================================");
            Iut_3wm_Write(t_addr, iut_burst_reps, seed);
            $display("====================================================");

            tw_test_addr_bits = `THREEWIRE_NFC_ADDRESS_BITS;
            tw_test_data_bits = `THREEWIRE_NFC_DATA_BITS;
            t_addr = $random(seed) & ((1<<tw_test_addr_bits) - 1);

            Iut_3wm_Read(t_addr, iut_burst_reps, seed);
            $display("====================================================");
            Iut_3wm_Write(t_addr, iut_burst_reps, seed);
            $display("====================================================");
        end
`endif
           
        for (tw_test_clk_div_exp2 = IUT_3W_CLK_DIV_EXP2_MIN; 
             tw_test_clk_div_exp2 <= IUT_3W_CLK_DIV_EXP2_MAX; 
             tw_test_clk_div_exp2  = tw_test_clk_div_exp2 + 1)
        begin
            $display("=== Running with CLK_DIV_EXP2 = %d ===", tw_test_clk_div_exp2);
            tw_test_addr_bits = `THREEWIRE_FM_ADDRESS_BITS;
            tw_test_data_bits = `THREEWIRE_FM_DATA_BITS;
            t_addr = $random(seed) & ((1<<tw_test_addr_bits) - 1);

            Iut_3wm_Read(t_addr, iut_burst_reps, seed);
            $display("====================================================");
            Iut_3wm_Write(t_addr, iut_burst_reps, seed);
            $display("====================================================");

            tw_test_addr_bits = `THREEWIRE_NFC_ADDRESS_BITS;
            tw_test_data_bits = `THREEWIRE_NFC_DATA_BITS;
            t_addr = $random(seed) & ((1<<tw_test_addr_bits) - 1);

            Iut_3wm_Read(t_addr, iut_burst_reps, seed);
            $display("====================================================");
            Iut_3wm_Write(t_addr, iut_burst_reps, seed);
            $display("====================================================");
        end

        t_data = 'h0;
        t_addr = 'h0;

        //////////////////////////
        #100000
        $finish;
    end

    task Iut_3wm_Read;
        input [IUT_3W_MAX_ADDRESS_BITS -1 : 0] addr;
        input integer burst_size;
        input integer seed;
    begin : read_test
        integer i;
        reg [IUT_3W_MAX_DATA_BITS - 1 : 0] lt_test_vector [0 : IUT_3W_BURST_MAX - 1];
        reg [63:0] address_mask;
        reg [63:0] data_mask;
        
        address_mask = ((1<<tw_test_addr_bits) - 1);
        data_mask    = ((1<<tw_test_data_bits) - 1);
        
        seed = $random(seed);
        
        // Check for also address bits -> otherwise LT would wrap address data 
        for (i = 0 ; i <= burst_size && (i < (1<<tw_test_addr_bits)); i = i + 1)
        begin
            // Fill test vector
            lt_test_vector[i] = ($random(seed)|$random(seed)<<32) & data_mask;
            lt_3w_slave.mem_3w.data_RAM[(addr + i) & address_mask] = lt_test_vector[i];
            /* 
            $display("Filling mem_3w slave addr=%x data=%x",
                     (addr + i) & address_mask,
                     lt_3w_slave.mem_3w.data_RAM[(addr + i) & address_mask]);
            */ 
        end
        
        $display("Trying RD with @ addr=%x", addr); 
        iut_address    = addr;
        iut_mode_wr = 0;
        iut_start   = 1;
        
        wait(active); 
        iut_start = 0;  
        wait(!active); 
       

        if (lt_slave_mode_wr !== 0 || 
            (iut_address&address_mask) !== lt_tw_slave_addr)
        begin
            $display(">>>> FAILED on 3W-RD");
            $display(">>>> ADDR IUT: %x LT : %x", 
                     (iut_address & address_mask), 
                     lt_tw_slave_addr);
            $display(">>>> MODE LT : %b", lt_slave_mode_wr);
            $finish;
        end
       
        for (i = 0; i <= burst_size && (i < (1<<tw_test_addr_bits)); i = i + 1)
        begin
            //$display("RCVD i=%d  data=%x", i, mem_3w.data_RAM[i]);

            if (mem_3w.data_RAM[i] !==
                lt_3w_slave.mem_3w.data_RAM[(iut_address + i) & address_mask])
            begin
                $display(">>>> FAILED on 3W-RD");
                $display(">>>> DATA IUT: %x LT : %x",
                         mem_3w.data_RAM[i], 
                         lt_3w_slave.mem_3w.data_RAM[(iut_address + i) & address_mask]);
                $display(">>>> ADDR IUT: %x LT : %x", iut_address, lt_tw_slave_addr);
                $display(">>>> MODE IUT: %b LT : %b", iut_mode_wr, lt_slave_mode_wr);
                $finish;
            end
            /* 
            else
                //$display("OK ");
                $display("OK burst_idx=%d, RD_DATA=%x", i, mem_3w.data_RAM[i]);
            */ 
        end 
    end
    endtask

    task Iut_3wm_Write;
        input [IUT_3W_MAX_ADDRESS_BITS -1 : 0] addr;
        input integer burst_size;
        input integer seed;
    begin: write_test
        reg [IUT_3W_MAX_DATA_BITS - 1 : 0]    iut_test_vector [0 : IUT_3W_BURST_MAX - 1];
        reg [63:0] address_mask;
        reg [63:0] data_mask;
        integer i;

        address_mask = ((1<<tw_test_addr_bits) - 1);
        data_mask    = ((1<<tw_test_data_bits) - 1);
        
        seed = $random(seed);
       
        // Check for also address bits -> otherwise LT would overwrite data
        for (i = 0 ; (i <= burst_size) && (i < (1<<tw_test_addr_bits)); i = i + 1)
        begin
            // Fill test vector
            iut_test_vector[i] = ($random(seed)|$random(seed)<<32) & data_mask;
            mem_3w.data_RAM[i] = iut_test_vector[i];
            /* 
            $display("Filling mem_3w iut addr=%x data=%x",
                     (addr + i) & address_mask,
                     mem_3w.data_RAM[i]);
            */
        end
        
        $display("Trying WR @ addr=%x", addr); 
        iut_address    = addr;
        iut_mode_wr = 1;
        iut_start   = 1;
        wait(active); 
        iut_start = 0;
        wait(!active);

        if (lt_slave_mode_wr !== 1 || 
            (iut_address&address_mask) !== lt_tw_slave_addr)
        begin
            $display(">>>> FAILED on 3W-WR");
            $display(">>>> ADDR IUT: %x LT : %x", 
                     (iut_address & address_mask), 
                     lt_tw_slave_addr);
            $display(">>>> MODE LT : %b", lt_slave_mode_wr);
            $finish;
        end

         
        for (i = 0; i <= burst_size && (i < (1<<tw_test_addr_bits)); i = i + 1)
        begin
            if (mem_3w.data_RAM[i] !== 
                lt_3w_slave.mem_3w.data_RAM[(iut_address + i) & address_mask])
            begin
                $display(">>>> FAILED on 3W-WR");
                $display(">>>> DATA IUT: %x LT : %x", 
                mem_3w.data_RAM[i], 
                lt_3w_slave.mem_3w.data_RAM[(iut_address + i) & address_mask]);
                $display(">>>> ADDR IUT: %x LT : %x", iut_address, lt_tw_slave_addr);
                $display(">>>> MODE IUT: %b LT : %b", iut_mode_wr, lt_slave_mode_wr);
                $finish;
            end
            /*
            else
                //$display("OK");
                $display("OK burst_idx=%d, WR_DATA=%x", 
                         i, 
                         lt_3w_slave.mem_3w.data_RAM[(iut_address + i) & address_mask]);
            */
        end
        
    end
    endtask


    //66MHz
	always #7.5 sim_clk = !sim_clk;
endmodule

