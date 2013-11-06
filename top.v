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

    // Local registers/wires.
    wire [7:0] data_rx;
    reg  [7:0] data_tx;
    reg  rx_enabled;

    reg  [2:0] rx_counter;
    reg  [2:0] tx_counter;
    
    reg  [7:0] rx_buffer;
	//Debug
	reg [24:0] counter;
    
    
    /// RX interlocking sync control signals.
    // ftdicon is the producer
    // me is the consumer.
    reg  rx_me_rdy;
    wire rx_ftdi_rdy;
    
    /// TX interlocking sync control signals.
    // me is the producer
    // ftdicon is the consumer
    reg  tx_me_rdy;
    wire tx_ftdi_rdy;
    
    // Synchronization between state machine and transmission logic.
    reg tx_ready;
        
//////////
//  FSM
    reg [2:0] state;
    reg [2:0] next_state;
    // State machine states
    localparam state_ready           = 3'd0,
               state_rx_ftdi_ready   = 3'd1,
               state_processing      = 3'd2,
               state_tx_ready        = 3'd3,
               state_tx_me_ready     = 3'd4,
               state_tx_ftdi_ready   = 3'd5;
               
               
    // Instantiation of ftdiController module.
    ftdiController  ftdicon(.in_clk               (in_clk),
                            .in_rst               (in_reset_p),
                            .in_ftdi_txe          (in_ftdi_txe_p), 
                            .in_ftdi_rxf          (in_ftdi_rxf_p),
                            .io_ftdi_data         (io_ftdi_data), 
                            .out_ftdi_wr          (out_ftdi_wr_p), 
                            .out_ftdi_rd          (out_ftdi_rd_p),
                            .in_ctrl_rx_ena       (rx_enabled),
                            .in_ctrl_tx_data_rdy  (tx_me_rdy),
                            .out_ctrl_tx_me_rdy   (tx_ftdi_rdy),
                            .in_ctrl_data         (data_tx),
                            .out_ctrl_data        (data_rx),
                            .out_ctrl_rx_me_rdy   (rx_ftdi_rdy),
                            .in_ctrl_rx_cons_rdy  (rx_me_rdy));
	

	
        // State machine:  state(t+1) logic (combinatorial)
        always @ (state, 
                  rx_ftdi_rdy, 
                  tx_ftdi_rdy, 
                  tx_ready)
        begin: next_state_logic
	        /* Set a default state to avoid latches creation */
	        next_state = state;

            case (state)    
                state_ready:
                begin
                    if (rx_ftdi_rdy)
                        next_state = state_rx_ftdi_ready;
                    else if (tx_ready)
                    // Attention, potentially we could never fall in this if we keep having rx_ftdi_rdy!
                        next_state = state_tx_me_ready;    
                end
                
                state_rx_ftdi_ready:
                begin
                    if (rx_ftdi_rdy == 0)
                        next_state = state_processing;
                end
                
                state_processing:
                begin
                    if (tx_ready)
                        next_state = state_tx_ready;
                    else
                        next_state = state_ready;
                end
                
                state_tx_ready:
                begin
                        next_state = state_tx_me_ready;
                end
                
                state_tx_me_ready:
                begin
                    if (tx_ftdi_rdy)
                        next_state = state_tx_ftdi_ready;
                end
                                
                state_tx_ftdi_ready:
                begin
                    if (tx_ftdi_rdy == 0)
                    begin
                        if (tx_ready)
                        begin
                            // More to transmit.
                            next_state = state_tx_ready;
                        end
                        else
                        begin
                            // Nothing to transmit.
                            next_state = state_ready;
                        end
                    end
                end
                
                default:
                    next_state = state_ready;  //something went wrong???
            endcase
        end
        
        
        always @ (posedge in_clk, negedge in_reset_n)
    	begin
    		if(!in_reset_n)
    		begin
    			counter      <= 0;
                state        <= state_ready;
                tx_ready     <= 0;
                rx_counter   <= 0;
    		end
    		else
    		begin
              counter  <= counter + 1;
              // FSM state advancement logic.
              state    <= next_state;
              
              // WHY FOR TX_READY NO LATCH IS GENERATED???
              // I DONT SET IT IN ANY POSSIBLE CASES.
              // MAYBE BECAUSE IT'S SEQUENTIAL LOGIC AND NOT COMBINATORIAL???
              
              if (state == state_ready && 
                  next_state == state_rx_ftdi_ready)
              begin
                  // When entering this state, fetch data!
                  case (rx_counter)
                      0:
                      begin
                          rx_counter    <= rx_counter + 1;
                          rx_buffer     <= data_rx;
                      end
                      
                      1:
                      begin
                          rx_counter    <= rx_counter + 1;
                          rx_buffer     <= data_rx;
                      end
                      
                      2:
                      begin
                          rx_counter    <= rx_counter + 1;
                          rx_buffer     <= data_rx;
                      end
                      
                      3:
                      begin
                          rx_counter    <= rx_counter + 1;
                          rx_buffer     <= data_rx;
                      end
                             
                      default:
                      begin
                          rx_buffer     <= data_rx;
                          rx_counter <= 0;
                          tx_ready   <= 1;
                          tx_counter <= 5;
                      end
                  endcase
              end
              else if (next_state == state_tx_ready)
              begin
                  if (tx_counter > 1)
                  begin
                      if (rx_buffer == 16'hAA)
                      begin
                          data_tx <= ~rx_buffer; 
                      end
                      else
                      begin
                          data_tx <= rx_buffer;
                      end
                      
                      tx_counter <= tx_counter - 1;
                  end
                  else
                  begin
                      tx_ready   <= 0;
                      tx_counter <= 0;
                  end
              end
            end
    	end

        
        /* FSM output calculation: combinatorial logic */
        always @ (state)
        begin
            case (state)
                state_ready:
                begin
                    rx_me_rdy  = 0;
                    tx_me_rdy  = 0;
                    rx_enabled = 1;
                end
            
                state_rx_ftdi_ready:
                begin
                    rx_me_rdy  = 1;
                    tx_me_rdy  = 0;
                    rx_enabled = 0;
                end
            
                state_processing:
                begin
                    rx_me_rdy  = 0;
                    tx_me_rdy  = 0;
                    rx_enabled = 0;    
                end
                
                state_tx_ready:
                begin
                    rx_me_rdy  = 0;
                    tx_me_rdy  = 0;
                    rx_enabled = 0;
                end
                
                state_tx_me_ready:
                begin
                    rx_me_rdy  = 0;
                    tx_me_rdy  = 1;
                    rx_enabled = 0;
                end
            
                state_tx_ftdi_ready:
                begin
                    rx_me_rdy  = 0;
                    tx_me_rdy  = 0;
                    rx_enabled = 0;
                end
            
                default:
                begin
                    rx_me_rdy  = 0;
                    tx_me_rdy  = 0;
                    rx_enabled = 0;
                end
            endcase    
        end

    ledon ledon(.clk    (in_clk),
    			.reset_n(in_reset_n),
    			.out    (out_led));

endmodule
