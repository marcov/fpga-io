
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
    
    inout  [IUT_IO_NUM_OF - 1 : 0] model_pins;
    reg    [IUT_IO_NUM_OF - 1 : 0] lt_outval;
    
    wire [IUT_IO_NUM_OF - 1 : 0] lt_direction;

    assign lt_direction = iut_direction ^ 'h3FF;

    lt_pad lt_pads[IUT_IO_NUM_OF - 1 : 0] (lt_direction, lt_outval, model_pins);
                    
    io_bitbang io_bitbang_inst(.in_io_direction(iut_direction),
                               .in_io_outval(iut_outval),
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

        #5
        iut_direction = 'h3FF;
        iut_outval    = 'h2AA;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end

        #5
        iut_outval    = 'h155;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end

        #5
        iut_direction = 'h0;
        lt_outval    = 'h3A5;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
       
        #5
        lt_outval    = 'h244;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #5
        lt_outval    = 'bz;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #5
        iut_outval              = 'h3FF;
        iut_direction           = 'h255;
        lt_outval    = 'h3A5;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #5
        iut_outval              = 'h0;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #5
        lt_outval    = 'h3FF;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, model_pins, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (model_pins & iut_direction)) ||
            ((lt_outval & lt_direction) !== (model_pins & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #10000
        $finish;
    end

endmodule

