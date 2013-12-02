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

always @ (*)
begin
    if (RST_IN)
    begin
        CLK0_OUT = 0;
    end
    else
    begin
        CLK0_OUT = CLKIN_IN;
    end
end
endmodule



