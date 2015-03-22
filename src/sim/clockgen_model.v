/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

/* Replacement of Xilinx DCM clock generation. To be used with Icarus Verilog simulation only! */
module clockgen(CLKIN_IN, 
                RST_IN, 
                CLKDV_OUT, 
                CLKIN_IBUFG_OUT, 
                CLK0_OUT);

   input CLKIN_IN;
   input RST_IN;
   output CLKDV_OUT;
   output CLKIN_IBUFG_OUT;
   output CLK0_OUT;

   assign CLK0_OUT = RST_IN ? 0 : CLKIN_IN;
endmodule




