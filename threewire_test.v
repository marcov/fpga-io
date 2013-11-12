`timescale 1ns / 1ps

module threewire_test;

    reg sim_clk;
    reg rst;
    reg op_is_write;
    reg start;
    reg [15:0]  wr_data;
    reg [8:0]   address;
    wire [15:0] rd_data;
    
    wire tw_slave_data_in;
    reg  tw_slave_data_out;
    reg  tw_slave_out_enable;

    threewire iut_3w ( .in_clk(sim_clk),
                       .in_rst(rst),
                       .in_r_w(op_is_write),
                       .in_addr(address),
                       .in_wr_data(wr_data),
                       .out_rd_data(rd_data),
                       .in_start(start),
                       .out_io_in_progress(active),
                       .out_tw_clock(tw_bus_clock),
                       .out_tw_cs(tw_bus_chipselect),
                       .io_tw_data(tw_bus_data));
    
    assign tw_slave_data_in = tw_bus_data;
    assign tw_bus_data = tw_slave_out_enable ? tw_slave_data_out : 8'bz;
    
    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0,threewire_test);

        sim_clk = 0;
        rst = 0;
        start = 0;
        tw_slave_out_enable = 0;
        tw_slave_data_out = 0;

        #75
        rst = 1;

        #100
        rst = 0;

        #150
        start       = 1;
        address     = 9'h155;
        wr_data     = 16'hAA;
        op_is_write = 0;
        //since iut is reading, we have to feed the slave emulator with a value.
        tw_slave_transmit_data = 16'hCA;

        #165
        start = 0;
        

        #10000
        $finish;
    end


    reg tw_slave_mode_is_write;
    reg [iut_3w.ADDR_BITS - 1 : 0] tw_slave_rcvd_address;
    reg [iut_3w.DATA_BITS - 1 : 0] tw_slave_incoming_data;
    reg [iut_3w.DATA_BITS - 1 : 0] tw_slave_transmit_data;
    reg [127 : 0] i;

    always
    begin : slave_emulator
        wait (tw_bus_chipselect == 0)
        
        @(posedge tw_bus_clock) tw_slave_mode_is_write = !tw_slave_data_in;
            
        for (i = 0; i < iut_3w.ADDR_BITS; i = i + 1)
        begin
            @(posedge tw_bus_clock) tw_slave_rcvd_address[iut_3w.ADDR_BITS - 1 - i] = tw_slave_data_in; 
        end

        if (!tw_slave_mode_is_write)
        begin
            // just read
            for (i = 0; i < iut_3w.DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock) tw_slave_incoming_data[iut_3w.DATA_BITS - 1 - i] = tw_slave_data_in; 
            end
        end
        else
        begin
            //we must write
            @ (posedge tw_bus_clock) tw_slave_out_enable = 1;

            for (i = 0; i < iut_3w.DATA_BITS; i = i + 1)
            begin
                @(posedge tw_bus_clock)  tw_slave_data_out =  tw_slave_transmit_data[iut_3w.DATA_BITS - 1 - i];
            end
            
            @ (posedge tw_bus_clock) tw_slave_out_enable = 0;
        end

        wait (tw_bus_chipselect == 1) 
            // FAKE instruction
            i = i;
    end


    //66MHz
	always #7.5 sim_clk = !sim_clk;

endmodule

