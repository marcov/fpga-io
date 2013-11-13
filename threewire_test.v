`timescale 1ns / 1ps

module threewire_test;

    reg sim_clk;
    reg rst;
    reg iut_op_is_write;
    reg start;
    reg  [15:0] iut_wr_data;
    reg  [8:0]  iut_addr;
    wire [15:0] iut_rd_data;
    reg  [15:0] lt_3w_slave_tx_data; 
    wire [8:0]  tw_slave_rcvd_addr;
    wire [15:0] tw_slave_rcvd_data;
    threewire iut_3w_master ( .in_clk(sim_clk),
                       .in_rst(rst),
                       .in_r_w(iut_op_is_write),
                       .in_addr(iut_addr),
                       .in_wr_data(iut_wr_data),
                       .out_rd_data(iut_rd_data),
                       .in_start(start),
                       .out_io_in_progress(active),
                       .out_tw_clock(tw_bus_clock),
                       .out_tw_cs(tw_bus_chipselect),
                       .io_tw_data(tw_bus_data));
    
    tw_slave  lt_3w_slave(
                .tw_bus_clock(tw_bus_clock),
                .tw_bus_chipselect(tw_bus_chipselect),
                .tw_bus_data(tw_bus_data),
                .rcvd_addr(tw_slave_rcvd_addr),
                .rcvd_data(tw_slave_rcvd_data),
                .tx_data(lt_3w_slave_tx_data),
                .rcvd_mode_w(tw_slave_mode_w));

    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0,threewire_test);

        sim_clk = 0;
        rst = 0;
        start = 0;

        #25
        rst = 1;

        #25
        rst = 0;

        #25
        ///////// TEST READ //////
        start           = 1;
        iut_addr        = 9'h155;
        iut_op_is_write = 0;
        //since iut is reading, we have to feed the slave emulator with a value.
        lt_3w_slave_tx_data = 16'h96CA;
        #15
        start = 0;
       

        #2000
        ///////// TEST WRITE //////
        start           = 1;
        iut_addr        = 9'h1B2;
        iut_wr_data     = 16'hA4F9;
        iut_op_is_write = 1;
        #15
        start = 0;
       

        #10000
        $finish;
    end




    //66MHz
	always #7.5 sim_clk = !sim_clk;
endmodule


module tw_slave(tw_bus_clock,
                tw_bus_chipselect,
                tw_bus_data,
                rcvd_addr,
                rcvd_data,
                tx_data,
                rcvd_mode_w);

    parameter ADDR_BITS = 9;
    parameter DATA_BITS = 16;
    
    input tw_bus_clock;
    input tw_bus_chipselect;
    inout tw_bus_data;
    output reg rcvd_mode_w;
    output reg [ADDR_BITS - 1 : 0] rcvd_addr;
    output reg [DATA_BITS - 1 : 0] rcvd_data;
    input  [DATA_BITS - 1 : 0] tx_data;
    
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
        
        @(posedge tw_bus_clock) rcvd_mode_w = !tw_slave_data_in;
            
        for (i = 0; i < ADDR_BITS; i = i + 1)
        begin
            @(posedge tw_bus_clock) rcvd_addr[ADDR_BITS - 1 - i] = tw_slave_data_in; 
        end

        if (!rcvd_mode_w)
        begin
            // just read
            for (i = 0; i < DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock) rcvd_data[DATA_BITS - 1 - i] = tw_slave_data_in; 
            end
        end
        else
        begin
            //we must write

            for (i = 0; i < DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock)  tw_slave_data_out =  tx_data[DATA_BITS - 1 - i];
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
