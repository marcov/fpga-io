`timescale 1ns / 1ps

module threewire_test;

    reg sim_clk;
    reg rst;
    reg iut_start;
    reg iut_mode_wr;
    
    reg  [8:0]  iut_addr;
    reg  [15:0] iut_wr_data;
    wire [15:0] iut_rd_data;
    
    wire [8:0]  lt_slave_addr;
    reg  [15:0] lt_slave_rd_data; 
    wire [15:0] lt_slave_wr_data;
    reg  [8:0] t_addr;
    reg  [15:0] t_data;

    /* Threewire master: implementation under test */
    threewire iut_3w_master ( 
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
                .io_tw_data(tw_bus_data));
    
    /* Threewire slave: lower tester */
    tw_slave  lt_3w_slave(
                .tw_bus_clock(tw_bus_clock),
                .tw_bus_chipselect(tw_bus_chipselect),
                .tw_bus_data(tw_bus_data),
                .address(lt_slave_addr),
                .wr_data(lt_slave_wr_data),
                .rd_data(lt_slave_rd_data),
                .mode_wr(lt_slave_mode_wr));

    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0,threewire_test);
        sim_clk = 0;
        rst = 0;
        iut_start = 0;
        
        //////////////////////////
        #25
        rst = 1;
        #25
        rst = 0;

        t_data = 0;
        t_addr = 0;
        TestRead(t_addr, t_data);
        TestWrite(t_addr, t_data);


        t_data = 16'h3d;
        t_addr = 9'h3;
        TestRead(t_addr, t_data);
        TestWrite(t_addr, t_data);
        
        t_data = 16'h49;
        t_addr = 9'h4e;
        TestRead(t_addr, t_data);
        TestWrite(t_addr, t_data);
        //////////////////////////
        #100000
        $finish;
    end

    task TestRead;
        input [8:0]  addr;
        input [15:0] data;
    begin
        ///////// TEST READ //////
        iut_start   = 1;
        iut_addr    = addr;
        iut_mode_wr = 0;
        //since iut is reading, we have to feed the slave lt with a value.
        lt_slave_rd_data = data;
        
        wait(active); 
        iut_start = 0;  
        wait(!active); 
        if (lt_slave_rd_data != iut_rd_data ||
            lt_slave_addr != iut_addr ||
            lt_slave_mode_wr != iut_mode_wr)
        begin
            $display(">>>> FAILED on RX");
            $display(">>>> DATA IUT: %d LT : %d", lt_slave_rd_data, iut_rd_data);
            $display(">>>> ADDR IUT: %d LT : %d", lt_slave_addr, iut_addr);
            $display(">>>> MODE IUT: %b LT : %b", lt_slave_mode_wr, iut_mode_wr);
            $finish;
        end
    end
    endtask

    task TestWrite;
        input [8:0]  addr;
        input [15:0] data;
    begin
        ///////// TEST WRITE //////
        iut_start   = 1;
        iut_addr    = addr;
        iut_wr_data = data;
        iut_mode_wr = 1;

        wait(active); 
        iut_start = 0;
        wait(!active); 
        if (lt_slave_wr_data != iut_wr_data ||
            lt_slave_addr != iut_addr ||
            lt_slave_mode_wr != iut_mode_wr)
        begin
            $display(">>>> FAILED on TX");
            $display(">>>> DATA IUT: %b LT : %b", lt_slave_wr_data, iut_wr_data);
            $display(">>>> ADDR IUT: %b LT : %b", lt_slave_addr, iut_addr);
            $display(">>>> MODE IUT: %b LT : %b", lt_slave_mode_wr, iut_mode_wr);
            $finish;
        end
    end
    endtask


    //66MHz
	always #7.5 sim_clk = !sim_clk;
endmodule


module tw_slave(tw_bus_clock,
                tw_bus_chipselect,
                tw_bus_data,
                address,
                wr_data,
                rd_data,
                mode_wr);

    parameter ADDR_BITS = 9;
    parameter DATA_BITS = 16;
    
    input tw_bus_clock;
    input tw_bus_chipselect;
    inout tw_bus_data;
    output reg mode_wr; //from master point of view
    output reg [ADDR_BITS - 1 : 0] address;
    output reg [DATA_BITS - 1 : 0] wr_data;
    input  [DATA_BITS - 1 : 0] rd_data;
    
    reg [127 : 0] i;
    wire tw_slave_data_in;
    reg  tw_slave_data_out;
    reg  tw_slave_out_enable;
    
    
    assign tw_slave_data_in = tw_bus_data;
    assign tw_bus_data = tw_slave_out_enable ? tw_slave_data_out : 8'bz;
     
    always
    begin : slave_emulator
        
        // STARTS HERE
        tw_slave_out_enable = 0;
        tw_slave_data_out   = 0;
        
        wait (tw_bus_chipselect == 0)
        
        @(posedge tw_bus_clock) mode_wr = tw_slave_data_in;
            
        for (i = 0; i < ADDR_BITS; i = i + 1)
        begin
            @(posedge tw_bus_clock) address[ADDR_BITS - 1 - i] = tw_slave_data_in; 
        end

        if (mode_wr)
        begin
            // Master is writing some data. 
            for (i = 0; i < DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock) wr_data[DATA_BITS - 1 - i] = tw_slave_data_in; 
            end
        end
        else
        begin
            // Master is reading some data.
            for (i = 0; i < DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock)  tw_slave_data_out =  rd_data[DATA_BITS - 1 - i];
                if (i == 0)
                    tw_slave_out_enable = 1;
            end
            
            @ (posedge tw_bus_clock) tw_slave_out_enable = 0;
        end

        wait (tw_bus_chipselect == 1) 
            // fake instruction
            i = i;
    end
endmodule
