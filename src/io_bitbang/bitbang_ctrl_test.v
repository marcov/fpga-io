
`timescale 1ns / 1ps



module bitbang_testbench;

    parameter IUT_IO_NUM_OF = 10;
    localparam IUT_IO_MASK = ((1 << IUT_IO_NUM_OF) - 1);

    reg  sim_clk;
    reg  rst;
    reg  [IUT_IO_NUM_OF - 1 : 0]   iut_direction;
    reg  [IUT_IO_NUM_OF - 1 : 0]   iut_outval;
    wire  [IUT_IO_NUM_OF - 1 : 0]  iut_inval;
    
    wire  [IUT_IO_NUM_OF - 1 : 0]  iut_2_lt_wires;
    reg    [IUT_IO_NUM_OF - 1 : 0] lt_outval;
    
    wire [IUT_IO_NUM_OF - 1 : 0] lt_direction;

    assign lt_direction = iut_direction ^ IUT_IO_MASK;

    pad_monitor pads_mon[IUT_IO_NUM_OF - 1 : 0] (.dir(lt_direction), 
                                                 .outval(lt_outval), 
                                                 .pad(iut_2_lt_wires));
                    
    bitbang_ctrl bitbang_dut(.in_io_direction(iut_direction),
                             .in_io_outval(iut_outval),
                             .out_io_inval(iut_inval),
                             .io_pins(iut_2_lt_wires));

    initial begin
        #0
        $dumpfile("test.lxt");
        $dumpvars(0, bitbang_testbench);
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
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end

        #5
        iut_outval    = 'h155;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end

        #5
        iut_direction = 'h0;
        lt_outval    = 'h3A5;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
       
        #5
        lt_outval    = 'h244;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #5
        lt_outval    = 'bz;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
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
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #5
        iut_outval              = 'h0;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #5
        lt_outval    = 'h3FF;
        #1
        $display("%d: PINS val=%b - IUT dir=%b outval=%b - LT dir=%b outval=%b", 
                 $time, iut_2_lt_wires, iut_direction, iut_outval, lt_direction, lt_outval);
        if (((iut_outval & iut_direction) !== (iut_2_lt_wires & iut_direction)) ||
            ((lt_outval & lt_direction) !== (iut_2_lt_wires & lt_direction)) )
        begin
            $display(">>>> FAIL!");
            $finish;
        end
        
        #10000
        $finish;
    end

endmodule

