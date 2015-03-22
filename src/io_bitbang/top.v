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
    inout [7:0] io_ftdi_data,
    input in_ftdi_rxf_n,
    input in_ftdi_txe_n,
    output out_ftdi_wr_n,
    output out_ftdi_rd_n,
    inout [TOP_BB_IO_NUM_OF - 1 : 0] io_bitbang_pads
    );

    // FTDI Wires for logic conversion to FTDI modules.
    wire in_ftdi_txe_p;
    wire in_ftdi_rxf_p;
    wire in_reset_p;
    wire out_ftdi_wr_p;
    wire out_ftdi_rd_p;

    //FTDI Wires conversion logic.
    assign in_ftdi_txe_p = !in_ftdi_txe_n;
    assign in_ftdi_rxf_p = !in_ftdi_rxf_n;
    assign in_reset_p    = !in_reset_n;

    assign out_ftdi_wr_n = !out_ftdi_wr_p;
    assign out_ftdi_rd_n = !out_ftdi_rd_p;
               
            
               
    // Instantiation of clockgen
    clockgen clkgen (
        .CLKIN_IN        (in_ext_osc), 
        .RST_IN          (in_reset_p), 
        .CLK0_OUT        (clk_top_main) 
        );
    
    wire [7:0] data_rx;
    wire [7:0] data_tx;
    
    ft245_asynch_ctrl ftdicon(
                            .in_clk               (clk_top_main),
                            .in_rst               (in_reset_p),
                            .in_ftdi_txe          (in_ftdi_txe_p), 
                            .in_ftdi_rxf          (in_ftdi_rxf_p),
                            .io_ftdi_data         (io_ftdi_data), 
                            .out_ftdi_wr          (out_ftdi_wr_p), 
                            .out_ftdi_rd          (out_ftdi_rd_p),
                            .in_rx_en             (rx_enabled),
                            .in_tx_hsk_req        (data_tx_req),
                            .out_tx_hsk_ack       (data_tx_ack),
                            .in_tx_data           (data_tx),
                            .out_rx_data          (data_rx),
                            .out_rx_hsk_req       (data_rx_req),
                            .in_rx_hsk_ack        (data_rx_ack));

   io_synchronizer  io_synch (.in_clk                (clk_top_main),
                              .in_rst                (in_reset_p),
                              .in_data_rx_hsk_req    (data_rx_req),
                              .out_data_rx_hsk_ack   (data_rx_ack),
                              .out_data_tx_hsk_req   (data_tx_req),
                              .in_data_tx_hsk_ack    (data_tx_ack),
                              .out_rx_enable         (rx_enabled),
                              .rx_done               (rx_done),
                              .tx_done               (tx_done),
                              .rx_continue           (rx_continue),
                              .tx_continue           (tx_continue));

    pcl_bitbang   #(.PCL_BB_IO_NUM_OF (TOP_BB_IO_NUM_OF))
            pcl_bb (.in_clk       (clk_top_main),
                    .in_rst       (in_reset_p),
                    .data_rx      (data_rx),
                    .data_tx      (data_tx),
                    .rx_done      (rx_done),
                    .tx_done      (tx_done),
                    .rx_trig      (rx_continue),
                    .tx_trig      (tx_continue),
                    .io_pins      (io_bitbang_pads));

    
    //ledon ledon(.clk    (clk_top_main),
    //            .reset_n(in_reset_n),
    //            .led_out    (out_led));


    led_ctrl ledhb     (.in_clk(clk_top_main),
                        .in_rst(in_reset_p),
                        .out_led(out_led));
endmodule
