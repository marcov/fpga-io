/**
 * Project: USB-BITBANG FPGA interface  
 * Author:  Marco Vedovati 
 * Date:
 * File:
 *
 */

`timescale 1ns / 1ps

module top #(parameter TOP_BB_IO_NUM_OF = 8)
   (input in_ext_osc,
    input in_reset_n,
    output out_led,
    
    input   ftdi_d0_tck,
    input   ftdi_d1_tdi,
    output  ftdi_d2_tdo,
    input   ftdi_d3_tms,
    input   ftdi_d4_trst,
    input   ftdi_d5_xxx,
    input   ftdi_d6_srst,
    input   ftdi_d7_xxx,
    
    input in_ftdi_rxf_n,
    input in_ftdi_txe_n,
    output out_ftdi_wr_n,
    output out_ftdi_rd_n,

    output io_pad_tdi,
    output io_pad_tms,
    output io_pad_tck,
    output io_pad_trst,
    output io_pad_srst,
    input  io_pad_tdo,
    output io_pad_d6,
    output io_pad_d7);
               
    // Instantiation of clockgen
    clockgen clkgen (
        .CLKIN_IN        (in_ext_osc), 
        .RST_IN          (in_reset_p), 
        .CLK0_OUT        (clk_top_main) 
        );

    assign io_pad_tdi = ftdi_d1_tdi;
    assign io_pad_tms = ftdi_d3_tms;
    assign io_pad_tck = ftdi_d0_tck;
    assign io_pad_trst = ftdi_d4_trst;
    assign io_pad_srst = ftdi_d6_srst;
    
    assign ftdi_d2_tdo = io_pad_tdo;

    assign io_pad_d6 = 'b0;
    assign io_pad_d7 = 'b0;
    assign out_ftdi_wr_n = 'b0;
    assign out_ftdi_rd_n = 'b0;
    assign out_led   = io_pad_tdo;
endmodule
