module comm_handler    (in_clk,
                        in_rst,
                        in_data_rx,
                        in_data_rx_hsk_req,
                        out_data_rx_hsk_ack,
                        out_data_tx,
                        out_data_tx_hsk_req,
                        in_data_tx_hsk_ack,
                        out_rx_enable);

    // Module input/output
    input  in_clk;
    input  in_rst;
    // data rx
    input  wire [7:0] in_data_rx;
    input  in_data_rx_hsk_req;
    output reg out_data_rx_hsk_ack;
    // data tx
    output wire [7:0] out_data_tx;
    output reg out_data_tx_hsk_req;
    input in_data_tx_hsk_ack;
    // Generic
    output reg out_rx_enable;

    // Synchronization with protocol decoder.
    reg rx_done;
    reg tx_done;
    
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
    proto_generic protogen  (.in_clk   (in_clk),
                             .in_rst   (in_rst),
                             .data_rx  (in_data_rx),
                             .data_tx  (out_data_tx),
                             .rx_done  (rx_done),
                             .tx_done  (tx_done),
                             .rx_trig  (rx_continue),
                             .tx_trig  (tx_continue));

                           
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



module proto_generic  (input  in_clk,
                       input  in_rst,
                       input      [7:0] data_rx,
                       output reg [7:0] data_tx,
                       input  rx_done,
                       input  tx_done,
                       output reg rx_trig,
                       output reg tx_trig,
                       output reg out_3w);
    /*
    // Protocol SM          
    localparam  state_proto_idle,
                state_proto_rcdv_cmd,
                state_proto_rcdv_addr0,
                state_proto_rcdv_addr1,
                state_proto_rcdv_data0,
                state_proto_rcdv_data1,
                state_proto_rcdv_txing;
    */ 
    
    reg [2:0]   state;    
    localparam  state_proto_idle      = 0,
                state_proto_rcdv_cmd  = 1,  
                state_proto_rcdv_data = 2,
                state_proto_txing_ans = 3,
                state_proto_tx_next   = 4;
    
    reg [7:0] cmd;
    reg [7:0] data;
    reg [1:0] tx_size;
    
    /////////////////////////////////////////
    always @ (posedge in_clk, posedge in_rst)
    begin
        if (in_rst)
        begin
            state <= state_proto_idle;
            rx_trig <= 0;
            tx_trig <= 0;
        end
        else
        begin
        
            // Make trig high duration of 1 clock cycle.
            if (tx_trig)
                tx_trig <=0;
                
            if (rx_trig)
                rx_trig <=0;
            
            case (state)   
                state_proto_idle:
                begin
                    if (rx_done)
                    begin
                        cmd     <= data_rx;
                        state   <= state_proto_rcdv_cmd;
                        rx_trig <= 1;
                    end
                end
                
                state_proto_rcdv_cmd:
                begin
                    if (rx_done)
                    begin
                        data    <= data_rx;
                        state   <= state_proto_rcdv_data;
                        // LAST BYTE WAS RECEIVED.
                    end
                end
                
                state_proto_rcdv_data:                
                begin
                    state   <= state_proto_txing_ans;
                
                    case (cmd)
                        8'h00:
                        begin
                            data_tx <= cmd;
                            tx_trig <= 1;
                            tx_size <= 1;
                        end
                    
                        8'h01:
                        begin
                            data_tx <= data;
                            tx_trig <= 1;
                            tx_size <= 1;
                            out_3w  <= 1;
                        end
                    
                        default:
                        begin
                            data_tx <= cmd + data;
                            tx_trig <= 1;
                            tx_size <= 3;
                        end
                    endcase
                end
                
                state_proto_txing_ans:
                begin
                    if (tx_size - 1 > 0)
                    begin
                        tx_size <= tx_size - 1;
                        state <= state_proto_tx_next;
                    end
                    else
                    begin
                        if (tx_done)
                        begin
                            tx_size <= 0;
                            rx_trig <= 1;
                            state   <= state_proto_idle;
                        end
                    end
                end
                
                state_proto_tx_next:
                begin
                    if (tx_done)
                    begin
                        data_tx <= tx_size;
                        tx_trig <= 1;
                        state   <= state_proto_txing_ans;
                    end
                end
                
            endcase
        end
    end              
endmodule







