`timescale 1ns / 1ps

module led_ctrl_testbench;

    reg sim_clk;
    reg rst;
    wire led; 

    /* led ctrl : implementation under test */
    led_ctrl iut_led_ctrl (.in_clk(sim_clk),
                           .in_rst(rst),
                           .out_led(led));

    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0,led_ctrl_testbench);
        sim_clk = 0;
        rst = 0;
        
        //////////////////////////
        #25
        rst = 1;
        #25
        rst = 0;
        
        //////////////////////////
        #2000000000
        $finish;
    end

    //66MHz
	always #7.5 sim_clk = !sim_clk;
endmodule


module tw_slave #( parameter TWS_ADDRESS_BITS = 10,
                   parameter TWS_DATA_BITS = 32)
               (tw_bus_clock,
                tw_bus_chipselect,
                tw_bus_data,
                address,
                wr_data,
                rd_data,
                mode_wr);
    
    input tw_bus_clock;
    input tw_bus_chipselect;
    inout tw_bus_data;
    output reg mode_wr; //from master point of view
    output reg [TWS_ADDRESS_BITS - 1 : 0] address;
    output reg [TWS_DATA_BITS - 1 : 0] wr_data;
    input  [TWS_DATA_BITS - 1 : 0] rd_data;
    
    //reg [$clog2($max(TWS_ADDRESS_BITS, TWS_DATA_BITS)) - 1 : 0] i;
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
            
        for (i = 0; i < TWS_ADDRESS_BITS; i = i + 1)
        begin
            @(posedge tw_bus_clock) address[TWS_ADDRESS_BITS - 1 - i] = tw_slave_data_in; 
        end

        if (mode_wr)
        begin
            // Master is writing some data. 
            for (i = 0; i < TWS_DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock) wr_data[TWS_DATA_BITS - 1 - i] = tw_slave_data_in; 
            end
        end
        else
        begin
            // Master is reading some data.
            for (i = 0; i < TWS_DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock)  tw_slave_data_out =  rd_data[TWS_DATA_BITS - 1 - i];
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
