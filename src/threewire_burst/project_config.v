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

`define THREEWIRE_HAS_BURST

`define THREEWIRE_FM_DATA_BITS       16 
`define THREEWIRE_FM_ADDRESS_BITS    9 
`define THREEWIRE_FM_CLK_DIV         64

`define THREEWIRE_NFC_DATA_BITS      32
`define THREEWIRE_NFC_ADDRESS_BITS   10
`define THREEWIRE_NFC_CLK_DIV        4


`define THREEWIRE_MIN_CLK_DIV        2 
`define THREEWIRE_MIN_DATA_BITS      1
`define THREEWIRE_MIN_ADDRESS_BITS   1
`define THREEWIRE_MAX_DATA_BITS      64 
`define THREEWIRE_MAX_ADDRESS_BITS   24 
`define THREEWIRE_MAX_CLK_DIV        256 
