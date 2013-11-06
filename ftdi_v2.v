`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:06:02 10/08/2013 
// Design Name: 
// Module Name:    ftdiController 
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
module ftdiController(in_clk,
                      in_rst,
                      in_ftdi_txe, 
                      in_ftdi_rxf,
                      io_ftdi_data, 
                      out_ftdi_wr, 
                      out_ftdi_rd,
                      in_ctrl_rx_ena,
                      in_ctrl_tx_data_rdy,
                      out_ctrl_tx_me_rdy,
                      in_ctrl_data,
                      out_ctrl_data,
                      out_ctrl_rx_me_rdy,
                      in_ctrl_rx_cons_rdy);

    input in_clk;
    input in_rst;
    input in_ftdi_txe;       // Asserted by peer when data can be written. Peer tells us: we are allowed to write data.
    input in_ftdi_rxf;   // Asserted by peer to ask us to read data It tells us: do rd_strobe to get the data!
    
    // Synch interlocking for data to TX to FTDI.
    input wire in_ctrl_tx_data_rdy;
    output reg out_ctrl_tx_me_rdy;

    // Synch interlocking for data to TX to external block.
    input  wire in_ctrl_rx_cons_rdy;
    output reg  out_ctrl_rx_me_rdy;
    
    
    inout [7:0] io_ftdi_data;       // data i/o
    output reg out_ftdi_wr;  // Strobed to signal peer data is available to  be read. It tells the peer: sample data nao!
    output reg out_ftdi_rd;   // Asserted by us to signal peer we're reading data. When it is going high, it allows the peer to refresh io_ftdi_data value. 
    input  wire [7:0] in_ctrl_data;
    output reg  [7:0] out_ctrl_data;
    
    input wire in_ctrl_rx_ena;

//////////
//  FSM
    reg [2:0] state;
    reg [2:0] next_state;

    localparam state_ready                 = 3'd0,
               state_rx_data_avlb          = 3'd1,
               state_rx_data_rcvd          = 3'd2,
               state_tx_data_wait_lock     = 3'd3,
               state_tx_data_rdy           = 3'd4,
               state_tx_data_gnt           = 3'd5,
               state_tx_data_hld           = 3'd6;

///////////
// Delays 
    reg [2:0] delay_counter;
    
	 //1 tick = 15ns

	 // min 30 ns
    localparam t4_rd_active    = 4;
	 // min 30 ns
    localparam t10_wr_active   = 4;
    
	 //max 14ns
    localparam t3_rd_to_sample = 3;
    
	 // min 5ns
	 localparam t8_data_to_wr   = 2;
    
	 // min 5ns
	 localparam t9_wr_to_hold   = 2;

///////////
// Bidirectional port handling.
    reg fdio_io_select;
    assign io_ftdi_data = fdio_io_select ? in_ctrl_data : 8'bz;
    
//////////
// Token for switching of priority RX/TX
    localparam token_priority_rx = 1'd0,
               token_priority_tx = 1'd1;
    reg token_priority;
    
///////////
// FSM
//
// State machine.
// Given:
// - state(t) and 
// - input(t) 
//
// it is possible to calculate with pure combinatorial logic:
// - state(t+1) 
// - output(t)
	 
	 /* Combinatorial logic for state(t+1) */
    always @ (state,
              in_ftdi_txe, 
              in_ctrl_rx_ena, 
              in_ftdi_rxf, 
              in_ctrl_tx_data_rdy,
              in_ctrl_rx_cons_rdy,
              token_priority)
    begin: next_state_logic
		/* Set a default state to avoid latches creation */
		next_state = state;
                
        case (state)
            state_ready :
            begin
                if (token_priority == token_priority_rx)
                begin
                    if (in_ctrl_rx_ena && in_ftdi_rxf)
                    begin
                       next_state = state_rx_data_avlb;
                    end
                    else if (in_ctrl_tx_data_rdy)
                    begin
                        next_state = state_tx_data_wait_lock;
                    end
                end
                else if (token_priority == token_priority_tx)
                begin
                    if (in_ctrl_tx_data_rdy)
                    begin
                        next_state = state_tx_data_wait_lock;
                    end
                    else if (in_ctrl_rx_ena && in_ftdi_rxf)
                    begin
                       next_state = state_rx_data_avlb;
                    end
                end
                
            end

            state_rx_data_avlb:
            begin
                next_state     = state_rx_data_rcvd;
            end

            state_rx_data_rcvd:
            begin
                //Interlocked synchronization. Hold on.
                if (in_ctrl_rx_cons_rdy)
                begin
                    next_state = state_ready;
                end
            end

            state_tx_data_wait_lock:
            begin
                if (in_ctrl_tx_data_rdy == 0)
                    next_state = state_tx_data_rdy;
            end
            
            state_tx_data_rdy:
            begin
                if (in_ftdi_txe)
                begin
                    next_state = state_tx_data_gnt;
                end
                else 
                begin
                    next_state = state_ready;
                end
            end
            
            state_tx_data_gnt:
            begin
                next_state = state_tx_data_hld;
            end
            
            state_tx_data_hld:
            begin
               next_state = state_ready;
            end

            default:
                next_state = state_ready;  //something went wrong???
        endcase
    end

    /* State advancement: sequential logic */
    always @ (posedge in_rst, posedge in_clk)
    begin: state_advancement_logic
        if (in_rst)
        begin
            state             <= state_ready;
            delay_counter     <= 0;
			out_ctrl_data     <= 0;
            token_priority    <= token_priority_rx;
        end
        else
        begin
            case (state)
                state_rx_data_avlb:
                begin
                    token_priority    <= token_priority_tx;
                
                    if (delay_counter < t4_rd_active)
                    begin
                        delay_counter <= delay_counter + 1;
                        if (delay_counter == t3_rd_to_sample)
                        begin
                            // sample input.
                            out_ctrl_data  <= io_ftdi_data;
                        end   
                    end
                    else
                    begin
                        delay_counter <= 0;
                        state         <= next_state;
                    end
                end
                
                state_tx_data_gnt:
                begin
                    token_priority    <= token_priority_rx;
                
                    if (delay_counter < t8_data_to_wr)
                    begin
                        delay_counter <= delay_counter + 1;
                    end
                    else
                    begin
                        delay_counter <= 0;
                        state         <= next_state;
                    end
                end

                state_tx_data_hld:
                begin
                    if (delay_counter < t10_wr_active)
                    begin
                        delay_counter <= delay_counter + 1;

                    end
                    else
                    begin
                        delay_counter <= 0;
                        state         <= next_state;
                    end
                end

                default:
                begin
                    state          <= next_state;
                end
            endcase
        end
    end

    /* Output calculation: combinatorial logic */
    always @ (state)
    begin: output_logic
        case (state)
            state_ready:
            begin
                out_ftdi_wr = 0;
                fdio_io_select = 0;
                out_ftdi_rd = 0;
                out_ctrl_rx_me_rdy = 0;
                out_ctrl_tx_me_rdy = 0;
            end
            state_rx_data_avlb:
            begin
                out_ftdi_wr = 0;
                fdio_io_select = 0;
                out_ftdi_rd = 1;
                out_ctrl_rx_me_rdy = 0;
                out_ctrl_tx_me_rdy = 0;
            end
            state_rx_data_rcvd:
            begin
                out_ftdi_wr = 0;
                fdio_io_select = 0;
                out_ftdi_rd = 0;
                out_ctrl_rx_me_rdy = 1;
                out_ctrl_tx_me_rdy = 0;
            end
            state_tx_data_wait_lock:
            begin
                out_ftdi_wr = 0; 
                fdio_io_select = 0;
                out_ftdi_rd = 0;
                out_ctrl_rx_me_rdy = 0;
                out_ctrl_tx_me_rdy = 1;
            end
            state_tx_data_rdy:
            begin
                out_ftdi_wr = 0; 
                fdio_io_select = 0;
                out_ftdi_rd = 0;
                out_ctrl_rx_me_rdy = 0;
                out_ctrl_tx_me_rdy = 0;
            end
            state_tx_data_gnt:
            begin
                out_ftdi_wr = 0;
                fdio_io_select = 1;
                out_ftdi_rd = 0;
                out_ctrl_rx_me_rdy = 0;
                out_ctrl_tx_me_rdy = 0;
            end
            state_tx_data_hld:
            begin
                out_ftdi_wr = 1;
                fdio_io_select = 1;
                out_ftdi_rd = 0;
                out_ctrl_rx_me_rdy = 0;
                out_ctrl_tx_me_rdy = 0;
				end
            default:   
            begin
                out_ftdi_wr = 0; 
                fdio_io_select = 0;
                out_ftdi_rd = 0;
                out_ctrl_rx_me_rdy = 0;
                out_ctrl_tx_me_rdy = 0;
            end
        endcase
    end
endmodule

////////////////////////////////////////////////////////////////////////////
//
//
//
