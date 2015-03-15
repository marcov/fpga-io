
`timescale 1ns / 1ps


module lt_pad (input wire dir,
               input wire outval,
               inout wire pad);

       assign pad = dir ? outval : 'bz;

endmodule

module threewire_testbench;

    parameter IUT_IO_NUM_OF = 10;

    reg sim_clk;
    reg rst;
    reg  [IUT_IO_NUM_OF - 1 : 0] iut_direction;
    reg  [IUT_IO_NUM_OF - 1 : 0] iut_outval;
    wire [IUT_IO_NUM_OF - 1 : 0] iut_inval;
    
    inout  [IUT_IO_NUM_OF - 1 : 0] model_pins;
    reg    [IUT_IO_NUM_OF - 1 : 0] lt_pads_drive_val;
    
    wire [IUT_IO_NUM_OF - 1 : 0] lt_direction;

    lt_direction = ~ iut_direction;

    lt_pad lt_pads[IUT_IO_NUM_OF - 1 : 0] (lt_direction, lt_pads_drive_val, model_pins);
                    
    io_bitbang io_bitbang_inst(
                        .in_io_direction(iut_direction),
                        .in_io_outval(iut_outval),
                        .out_io_inputval(iut_inval),
                        .io_pins(model_pins));


    
    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0, threewire_testbench);
        sim_clk = 0;
        rst = 0;
        
        //////////////////////////
        #25
        rst = 1;
        #25
        rst = 0;

        iut_direction = 'h3FF;
        iut_outval    = 'h2AA;

        #5
        iut_outval    = 'h155;

        #5
        iut_direction = 'h0;
        lt_pads_drive_val    = 'h3A5;
        $display("Model pins set to input, value = %x -  read val = %x", model_pins, iut_inval);
       
        #5
        lt_pads_drive_val    = 'h244;
        $display("Model pins set to input, value = %x -  read val = %x", model_pins, iut_inval);
        
        #5
        lt_pads_drive_val    = 'bz;
        $display("Model pins set to input, value = %x -  read val = %x", model_pins, iut_inval);
        
        #5
        iut_outval              = 'h3FF;
        iut_direction           = 'h255;
        lt_pads_drive_val    = 'h3A5;
        $display("Model pins set to input, value = %x -  read val = %x", model_pins, iut_inval);
        
        #5
        iut_outval              = 'h0;
        $display("Model pins set to input, value = %x -  read val = %x", model_pins, iut_inval);
        
        #5
        lt_pads_drive_val    = 'h3FF;
        $display("Model pins set to input, value = %x -  read val = %x", model_pins, iut_inval);
        
        #10000
        $finish;
    end

endmodule

