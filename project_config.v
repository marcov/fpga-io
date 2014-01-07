/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

/*******************************************
 *
 * Global project configuration
 *
 */

`undef   THREEWIRE_HAS_BURST

`ifdef   THREEWIRE_FOR_FM
`define  THREEWIRE_DATA_BITS        16 
`define  THREEWIRE_ADDRESS_BITS     9 
`define  THREEWIRE_CLK_DIV_2N       64
`elsif   THREEWIRE_FOR_NFC
`define  THREEWIRE_DATA_BITS        32
`define  THREEWIRE_ADDRESS_BITS     10
`define  THREEWIRE_CLK_DIV_2N       4
`endif 
