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
reg  rx_ena;
reg  rx_counter;
reg  [7:0] rx_buffer;						 
	
ftdiController  ftdicon(.in_clk(in_clk),
                        .in_rst(in_reset_p),
                        .in_ftdi_txe(in_ftdi_txe_p), 
                        .in_ftdi_rxf(in_ftdi_rxf_p),
                        .io_ftdi_data(io_ftdi_data), 
                        .out_ftdi_wr(out_ftdi_wr_p), 
                        .out_ftdi_rd(out_ftdi_rd_p),
                        .in_ctrl_rx_ena(rx_ena),
                        .in_ctrl_data_rdy(tx_ready),
                        .in_ctrl_data(data_tx),
                        .out_ctrl_data(data_rx),
                        .out_ctrl_data_rdy(rx_ready));
	
	//Debug
	reg [24:0] counter;
	

    always @ (posedge in_clk, negedge in_reset_n)
	 begin
		if(!in_reset_n)
		begin
			counter  <= 0;
			rx_ena   <= 1;
		end
		else
		begin
          counter  <= counter + 1;
          
          if (rx_ready)
          begin
              case (rx_counter)
                  0:
                  begin
                    rx_counter    <= rx_counter + 1;
                    rx_buffer     <= data_rx;
                  end
                  
                  default:
                    begin
                        if (rx_buffer == 16'hAA)
                        begin
                            data_tx <= ~data_rx; 
                        end
                        else
                        begin
                            data_tx <= data_rx;
                        end
                        tx_ready   <= 1;
                        rx_counter <= 0;
                    end
              endcase
          end
          else
          begin
              tx_ready <= 0;
          end
		end
	end

ledon ledon(.clk(in_clk),
				.reset_n(in_reset_n),
				.out(out_led));

endmodule
