/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

module io_synchronizer (in_clk,
                        in_rst,
                        in_data_rx_hsk_req,
                        out_data_rx_hsk_ack,
                        out_data_tx_hsk_req,
                        in_data_tx_hsk_ack,
                        out_rx_enable,
                        rx_done,
                        tx_done,
                        rx_continue,
                        tx_continue);

    // Module input/output
    input  in_clk;
    input  in_rst;
    // data rx
    input  in_data_rx_hsk_req;
    output reg out_data_rx_hsk_ack;
    // data tx
    output reg out_data_tx_hsk_req;
    input in_data_tx_hsk_ack;
    // Generic
    output reg out_rx_enable;
    // Synchronization with protocol decoder.
    output reg rx_done;
    output reg tx_done;
    input  wire rx_continue;
    input  wire tx_continue;

    //////////
    //  FSM
    reg [2:0] state;
    reg [2:0] next_state;
    
    // State machine states
    localparam state_rx_ready        = 0,
               state_rx_data_rcvd    = 1,
               state_proto_decoding  = 2,
               state_tx_data_ready   = 3,
               state_tx_data_hsk_req = 4,
               state_tx_data_hsk_ack = 5; 
              
              
    ////////////////////////////////////////////////////

                           
    // State machine:  state(t+1) logic (combinatorial)
    always @ (state, 
              in_data_rx_hsk_req, 
              in_data_tx_hsk_ack, 
              tx_continue,
              rx_continue)
              
    begin: next_state_logic
        /* Set a default state to avoid latches creation */
        next_state = state;

        case (state)    
            state_rx_ready:
            begin
                if (in_data_rx_hsk_req)
                    next_state = state_rx_data_rcvd;
            end
            
            state_rx_data_rcvd:
            begin
                if (in_data_rx_hsk_req == 0)
                    next_state = state_proto_decoding;
            end
            
            state_proto_decoding:
            begin
                if (rx_continue)
                    next_state = state_rx_ready;
                else if (tx_continue)
                    next_state = state_tx_data_ready;
            end
            
            state_tx_data_ready:
            begin
                next_state = state_tx_data_hsk_req;
            end
            
            state_tx_data_hsk_req:
            begin
                if (in_data_tx_hsk_ack)
                    next_state = state_tx_data_hsk_ack;
            end
                            
            state_tx_data_hsk_ack:
            begin
                if (in_data_tx_hsk_ack == 0)
                begin
                    if (tx_continue)
                        // More to transmit.
                        next_state = state_tx_data_ready;
                    else if (rx_continue)
                        // Nothing to transmit.
                        next_state = state_rx_ready;
                end
            end
            
            default:
                next_state = state_rx_ready;  //something went wrong???
        endcase
    end
    
    
    always @ (posedge in_clk, posedge in_rst)
	begin
        if(in_rst)
        begin
            state   <= state_rx_ready;
            rx_done <= 0;
            tx_done <= 0;
        end
        else
        begin
            // FSM state advancement logic.
            state <= next_state;
            
            ///////////////////////////////////////
            // Make rx_done high duration of 1 clock cycle.
            if (state == state_rx_data_rcvd && 
                next_state == state_proto_decoding)
                rx_done <= 1;
            else
                rx_done <= 0;  
                
            ///////////////////////////////////////
            // Make tx_done high duration of 1 clock cycle.
            if (state == state_tx_data_hsk_req && 
                next_state == state_tx_data_hsk_ack)
                tx_done <= 1;
            else
                tx_done <= 0;  
                
        end
	end

    
    /* FSM output calculation: combinatorial logic */
    always @ (state)
    begin
        out_data_rx_hsk_ack  = 0;
        out_data_tx_hsk_req  = 0;
        out_rx_enable = 0;
        
        case (state)
            state_rx_ready:
            begin
                out_rx_enable = 1;
            end
        
            state_rx_data_rcvd:
            begin
                out_data_rx_hsk_ack  = 1;
            end
        
            state_proto_decoding:
            begin
            end
            
            state_tx_data_ready:
            begin
                // pass
            end
            
            state_tx_data_hsk_req:
            begin
                out_data_tx_hsk_req  = 1;
            end
        
            state_tx_data_hsk_ack:
            begin
                // pass
            end
        
            default:
            begin
                // pass
            end
        endcase    
    end
endmodule
