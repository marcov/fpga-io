`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:13:32 10/08/2013 
// Design Name: 
// Module Name:    top 
// Project Name: 
// Target Devices: 
// Tool versions: 
// Description: 
//
// Dependencies: 
//
// Revision: 
// Revision 0.01 - File Created
// Additional Comments: 
//
//////////////////////////////////////////////////////////////////////////////////
module top(
    input in_clk,
    input in_reset_n,
    output out_led,
    inout [7:0] io_ftdi_data,
    input in_ftdi_rxf_n,
    input in_ftdi_txe_n,
    output out_ftdi_wr_n,
    output out_ftdi_rd_n 
    );

wire in_ftdi_txe_p;
wire in_ftdi_rxf_p;
wire in_reset_p;
wire out_ftdi_wr_p;
wire out_ftdi_rd_p;


assign in_ftdi_txe_p = !in_ftdi_txe_n;
assign in_ftdi_rxf_p = !in_ftdi_rxf_n;
assign in_reset_p    = !in_reset_n;

assign out_ftdi_wr_n = !out_ftdi_wr_p;
assign out_ftdi_rd_n = !out_ftdi_rd_p;


wire [7:0] data_rx;
reg  [7:0] data_tx;
reg  tx_ready;
							 
ftdiController ftdicon (
                        .in_clk(in_clk),
                        .in_rst(in_reset_p),
                        .in_ftdi_txe(in_ftdi_txe_p), 
                        .in_ftdi_rxf(in_ftdi_rxf_p),
                        .io_ftdi_data(io_ftdi_data), 
                        .out_ftdi_wr(out_ftdi_wr_p), 
                        .out_ftdi_rd(out_ftdi_rd_p),
                        .in_tx_data_ready(tx_ready),
                        .in_data_tx(data_tx),
                        .out_reg_data_rcvd(data_rx),
                        .out_data_rcvd_ready(rx_ready)
                        );
	
	
	//Debug
	reg [24:0] counter;
	
	always @ (data_rx, rx_ready)
	begin
		data_tx  = ~data_rx;
        if (rx_ready)
        begin
            tx_ready = 1;
        end
        else
        begin
            tx_ready = 0;
        end
	end


    always @ (posedge in_clk, negedge in_reset_n)
	 begin
		if(!in_reset_n)
		begin
			counter  <= 0;
		end
		else
		begin
          counter  <= counter + 1;
		end
	end

ledon ledon(.clk(in_clk),
				.reset_n(in_reset_n),
				.out(out_led));

endmodule
