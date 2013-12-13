`timescale 1ns / 1ps

module threewire_testbench;

    `include "builtins_redefined.v"

    reg sim_clk;
    reg rst;
    reg iut_start;
    reg iut_mode_wr;
   
    parameter IUT_3W_ADDR_BITS  = 10;
    parameter IUT_3W_DATA_BITS  = 32;
    parameter IUT_3W_CLK_DIV_2N = 4;
     
    reg  [IUT_3W_ADDR_BITS - 1 : 0] iut_addr;
    reg  [IUT_3W_DATA_BITS - 1 : 0] iut_wr_data;
    wire [IUT_3W_DATA_BITS - 1 : 0] iut_rd_data;
    
    wire [IUT_3W_ADDR_BITS - 1 : 0]  lt_tw_slave_addr;
    reg  [IUT_3W_DATA_BITS - 1 : 0] lt_tw_slave_rd_data;
    wire [IUT_3W_DATA_BITS - 1 : 0] lt_tw_slave_wr_data;
    wire        lt_tw_slave_mode_wr;
    reg  [IUT_3W_ADDR_BITS - 1 : 0]  t_addr;
    reg  [IUT_3W_DATA_BITS - 1 : 0] t_data;

    /* Threewire master: implementation under test */
    threewire_master_ctrl #(
                .TWM_ADDRESS_BITS(IUT_3W_ADDR_BITS),
                .TWM_DATA_BITS(IUT_3W_DATA_BITS),
                .TWM_CLK_DIV_2N(IUT_3W_CLK_DIV_2N))
            iut_3w_master ( 
                .in_clk(sim_clk),
                .in_rst(rst),
                .in_mode_wr(iut_mode_wr),
                .in_addr(iut_addr),
                .in_wr_data(iut_wr_data),
                .out_rd_data(iut_rd_data),
                .in_start(iut_start),
                .out_io_in_progress(active),
                .out_tw_clock(tw_bus_clock),
                .out_tw_cs(tw_bus_chipselect),
                .io_tw_data(tw_bus_data),
                .out_tw_dir(tw_bus_dir));
    
    /* Threewire slave: lower tester */
    tw_slave  #(.TWS_ADDRESS_BITS(IUT_3W_ADDR_BITS),
                .TWS_DATA_BITS(IUT_3W_DATA_BITS))
             lt_3w_slave(
                .tw_bus_clock(tw_bus_clock),
                .tw_bus_chipselect(tw_bus_chipselect),
                .tw_bus_data(tw_bus_data),
                .address(lt_tw_slave_addr),
                .wr_data(lt_tw_slave_wr_data),
                .rd_data(lt_tw_slave_rd_data),
                .mode_wr(lt_slave_mode_wr));

    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0, threewire_testbench);
        sim_clk = 0;
        rst = 0;
        iut_start = 0;
        
        //////////////////////////
        #25
        rst = 1;
        #25
        rst = 0;
        
        t_data = 'h0;
        t_addr = 'h0;
        Iut_3wm_Read(t_addr, t_data);
        Iut_3wm_Write(t_addr, t_data);

        t_data = 32'hFFFFFFFF;
        t_addr = 10'h3FF;
        Iut_3wm_Read(t_addr, t_data);
        Iut_3wm_Write(t_addr, t_data);

        t_data = 32'hAABBCCDD;
        t_addr = 10'h333;
        Iut_3wm_Read(t_addr, t_data);
        Iut_3wm_Write(t_addr, t_data);
        
        t_data = 32'h00112233;
        t_addr = 10'h2AA;
        Iut_3wm_Read(t_addr, t_data);
        Iut_3wm_Write(t_addr, t_data);
        //////////////////////////
        #100000
        $finish;
    end

    task Iut_3wm_Read;
        input [IUT_3W_ADDR_BITS -1 : 0] addr;
        input [IUT_3W_DATA_BITS -1 : 0] data;
    begin
        ///////// TEST READ //////
        iut_start   = 1;
        iut_addr    = addr;
        iut_mode_wr = 0;
        //since iut is reading, we have to feed the slave lt with a value.
        lt_tw_slave_rd_data = data;
        
        $display("Trying RD with addr=%x LT_data=%x", addr, data); 
        wait(active); 
        iut_start = 0;  
        wait(!active); 
        if (lt_tw_slave_rd_data != iut_rd_data ||
            lt_tw_slave_addr != iut_addr ||
            lt_slave_mode_wr != iut_mode_wr)
        begin
            $display(">>>> FAILED on RX");
            $display(">>>> DATA IUT: %x LT : %x", iut_rd_data, lt_tw_slave_rd_data);
            $display(">>>> ADDR IUT: %x LT : %x", iut_addr, lt_tw_slave_addr);
            $display(">>>> MODE IUT: %b LT : %b", iut_mode_wr, lt_slave_mode_wr);
            $finish;
        end
        else
            $display("OK");
    end
    endtask

    task Iut_3wm_Write;
        input [IUT_3W_ADDR_BITS -1 : 0] addr;
        input [IUT_3W_DATA_BITS -1 : 0] data;
    begin
        ///////// TEST WRITE //////
        iut_start   = 1;
        iut_addr    = addr;
        iut_wr_data = data;
        iut_mode_wr = 1;


        $display("Trying WR with addr=%x IUT_data=%x", addr, data); 
        wait(active); 
        iut_start = 0;
        wait(!active); 
        if (lt_tw_slave_wr_data != iut_wr_data ||
            lt_tw_slave_addr != iut_addr ||
            lt_slave_mode_wr != iut_mode_wr)
        begin
            $display(">>>> FAILED on TX");
            $display(">>>> DATA IUT: %x LT : %x", iut_wr_data, lt_tw_slave_wr_data);
            $display(">>>> ADDR IUT: %x LT : %x", iut_addr, lt_tw_slave_addr);
            $display(">>>> MODE IUT: %b LT : %b", iut_mode_wr, lt_slave_mode_wr);
            $finish;
        end
        else
            $display("OK");
    end
    endtask


    //66MHz
	always #7.5 sim_clk = !sim_clk;
endmodule

