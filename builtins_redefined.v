/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

`define _cdiv8(dividend) ((dividend >> 'h3) + ((dividend & 'b111) ? 1 : 0))

/* clog2 redefinition for XST */
`ifdef __IVERILOG__
//WIP
`define _clog2 $clog2
`define _max   $max
`define _cdiv(dividend,divisor)\
        ((dividend / divisor) + ((dividend % divisor) ? 1 : 0))

`else

`define _clog2(x) __clog2((x))
`define _max(a,b) __max(a,b)
`define _cdiv(dividend,divisor) __cdiv(dividend,divisor)

function integer __clog2;
    input integer value;
    begin
        value = value-1;
        for (__clog2='d0; value>'d0; __clog2=__clog2+1)
            value = value>>1;
    end
endfunction

/* max redefinition for XST */
function integer __max;
    input integer a,b;
    begin
        if (a>=b) __max = a;
        else      __max = b;
    end
endfunction

function integer __cdiv;
    input integer dividend, divisor;
    begin
        __cdiv = (dividend / divisor) + ((dividend % divisor) ? 1 : 0);
    end
endfunction
`endif

