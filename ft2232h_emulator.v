`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////////
//
module ft2232h_device #(parameter BUFFERS_WIDTH = 7)
                     (input in_clk,
                      input in_rd_n,
                      input in_wr_n,
                      output reg out_txe_n,
                      output reg out_rxf_n,
                      inout  [7 : 0] io_data,
                      input  [BUFFERS_WIDTH - 1 : 0]     usb_tx_size,
                      output reg [BUFFERS_WIDTH - 1 : 0] usb_txbuffer_addr,
                      input      [7:0] usb_txbuffer_data,
                      input  [BUFFERS_WIDTH - 1 : 0] usb_rx_size,
                      output reg [BUFFERS_WIDTH - 1 : 0] usb_rxbuffer_addr,
                      output [7:0] usb_rxbuffer_data,
                      output reg usb_rxbuffer_wr,
                      input  usb_tx_start,
                      input  usb_rx_start,
                      output reg  usb_rx_done);

    wire [7:0] in_data;
    wire [7:0] out_data;
    reg        io_out_enable;
    reg [15:0] rcvd_data;

    assign in_data   = io_data;
    assign io_data   = io_out_enable ? out_data : 8'bz;

    reg usb_tx_in_progress;
    reg usb_rx_in_progress;

    reg [BUFFERS_WIDTH - 1 : 0] usb_tx_counter;
    reg [BUFFERS_WIDTH - 1 : 0] usb_rx_counter;

    // RX char
    assign usb_rxbuffer_data = in_data;
    assign out_data = usb_txbuffer_data;

    // HERE we are emulating the FT2332H!
	always 
    begin : usb_to_fpga_ctrl
        // Set io to input
        io_out_enable = 0;
        
        //Disable USB -> FPGA
        out_rxf_n         = 1;

        usb_tx_in_progress = 0;
        
        wait (usb_tx_start);
        usb_tx_in_progress = 0;

        /* Make it half-duplex */
        wait (!usb_rx_in_progress)
        begin
            usb_tx_in_progress = 1;
            
            // So we dont tx twice.
            wait(usb_tx_start == 0);
            //Enable USB -> FPGA
            out_rxf_n         = 0;
           
            usb_txbuffer_addr = 'h0;
            
            for (usb_tx_counter = 0; 
                 usb_tx_counter < usb_tx_size; 
                 usb_tx_counter = usb_tx_counter + 1)
            begin
                // TX char
                @(negedge in_rd_n)
                begin
                    io_out_enable = 1;
                end
                @(posedge in_rd_n)  io_out_enable = 0;
                
                wait (in_clk == 0);
                usb_txbuffer_addr = usb_txbuffer_addr + 1;
            end
        end
	end

    always 
    begin : fpga_to_usb_ctrl

        // Set io to input
		io_out_enable = 0;

        // Disable FPGA -> USB 
        out_txe_n         = 1;
       
        usb_rx_in_progress = 0;
        
        wait(usb_rx_start);
        usb_rx_done = 0;

        usb_rxbuffer_addr = 'h0;
        usb_rxbuffer_wr   = 'h0;

        /* Make it half-duplex */
        wait (!usb_tx_in_progress)
        begin
            usb_rx_in_progress = 1;

            // Enable FPGA -> USB 
            out_txe_n         = 0;

            for (usb_rx_counter = 0; 
                 usb_rx_counter < usb_rx_size; 
                 usb_rx_counter = usb_rx_counter + 1)
            begin
                @ (negedge in_wr_n)
                wait (in_clk == 0);
                usb_rxbuffer_wr = 1;

                // Prepare for next data 
                @ (posedge in_clk)
                wait (in_clk == 0);
                usb_rxbuffer_wr = 0;
                usb_rxbuffer_addr = usb_rxbuffer_addr + 1;
            end

            wait (in_wr_n == 1);
            usb_rx_done = 1;
        end
    end
endmodule


