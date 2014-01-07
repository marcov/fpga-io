/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

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
        $dumpvars(0, led_ctrl_testbench);
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
