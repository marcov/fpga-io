`timescale 1ns / 1ps

module threewire_test;

    reg sim_clk;
    reg rst;
    reg read_write;
    reg start;
    reg [15:0] wr_data;
    reg [8:0]  address;
    wire [15:0] rd_data;

    threewire test_3w( .in_clk(sim_clk),
                       .in_rst(rst),
                       .in_r_w(read_write),
                       .in_addr(address),
                       .in_wr_data(wr_data),
                       .out_rd_data(rd_data),
                       .in_start(start),
                       .out_io_in_progress(active),
                       .out_tw_clock(tw_clock),
                       .out_tw_cs(tw_chipselect),
                       .io_tw_data(tw_data));
    

    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0,threewire_test);

        sim_clk = 0;
        rst = 0;
        start = 0;

        #75
        rst = 1;

        #100
        rst = 0;

        #150
        start = 1;
        address = 9'h155;
        wr_data = 16'hAA;
        read_write = 0;
        
        #165
        start = 0;

        #10000
        $finish;
    end


    //66MHz
	always #7.5 sim_clk = !sim_clk;

endmodule

