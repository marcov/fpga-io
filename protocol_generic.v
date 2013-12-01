module comm_handler    (in_clk,
                        in_rst,
                        in_data_rx,
                        in_data_rx_hsk_req,
                        out_data_rx_hsk_ack,
                        out_data_tx,
                        out_data_tx_hsk_req,
                        in_data_tx_hsk_ack,
                        out_rx_enable,
                        out_tw_clock,
                        out_tw_cs,
                        io_tw_data);

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
    // 3w signals
    output out_tw_clock;
    output out_tw_cs;
    inout  io_tw_data;
    
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
    pcl_3w_master pcl_3wm   (.in_clk   (in_clk),
                             .in_rst   (in_rst),
                             .data_rx  (in_data_rx),
                             .data_tx  (out_data_tx),
                             .rx_done  (rx_done),
                             .tx_done  (tx_done),
                             .rx_trig  (rx_continue),
                             .tx_trig  (tx_continue),
                             .out_tw_clock (out_tw_clock),
                             .out_tw_cs    (out_tw_cs),
                             .io_tw_data   (io_tw_data));

                           
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

////////////////////////////////////////////////////////////////////////////////////
//
// Decodes the messages from host for 3w R/W.
//
module pcl_3w_master  (input  in_clk,
                       input  in_rst,
                       input      [7:0] data_rx,
                       output reg [7:0] data_tx,
                       input  rx_done,
                       input  tx_done,
                       output reg rx_trig,
                       output reg tx_trig,
                       output out_tw_clock,
                       output out_tw_cs,
                       inout  io_tw_data);
    
    reg [2:0]   state;    
    localparam  state_proto_wait_cmd         = 0,
                state_proto_wait_addr        = 1, 
                state_proto_tw_started       = 2,
                state_proto_wait_wrdata      = 3,
                state_proto_wait_tw_complete = 4,
                state_proto_tx_answer        = 5,
                state_proto_wait_echo_char   = 6;
    
  ////////////////////////////////////////////////////////// 

    parameter THREEWIRE_ADDRESS_BITS = 9;
    parameter THREEWIRE_DATA_BITS   = 16;

    ////// TODO: calculate the byte values from bits values!
    localparam ADDR_BYTES  = 2;
    localparam DATA_BYTES  = 2;
    
  ////////////////////////////////////////////////////////// 
    reg [7:0] cmd;
    localparam CMD_READ  = 8'h0,
               CMD_WRITE = 8'h1,
               CMD_OK    = 8'h2,
               CMD_ECHO  = 8'hAA,
               CMD_PING  = 8'hFF;

  //////////////////////////////////////////////////////////
    // Used to count the number of bytes received before changing state.
    reg [DATA_BYTES - 1 : 0] rx_data_len;
    reg [ADDR_BYTES - 1 : 0] rx_addr_len;
    reg [DATA_BYTES - 1 : 0] tx_data_len;

  ////////////////////////////////////////////////////////// 
    reg tw_start;
    reg tw_mode_rw;
    wire [THREEWIRE_DATA_BITS - 1 : 0]   tw_rd_data;
    reg [THREEWIRE_DATA_BITS - 1 : 0]    tw_wr_data;
    reg [THREEWIRE_ADDRESS_BITS - 1 : 0] tw_address;

    threewire #(.DATA_BITS(THREEWIRE_DATA_BITS),
                .ADDR_BITS(THREEWIRE_ADDRESS_BITS))
              tw_master(.in_clk (in_clk),
                        .in_rst (in_rst),
                        .in_mode_wr (tw_mode_rw),
                        .in_addr(tw_address),
                        .in_wr_data(tw_wr_data),
                        .out_rd_data(tw_rd_data),
                        .in_start(tw_start),
                        .out_io_in_progress(tw_running),
                        .out_tw_clock (out_tw_clock),
                        .out_tw_cs    (out_tw_cs),
                        .io_tw_data   (io_tw_data));
   
  ////////////////////////////////////////////////////////// 
  ////////////////////////////////////////////////////////// 
    always @ (posedge in_clk, posedge in_rst)
    begin
        if (in_rst)
        begin
            state <= state_proto_wait_cmd;
            rx_trig <= 0;
            tx_trig <= 0;
            tw_start <= 0;
        end
        else
        begin
        
            // Make trig/start high duration of 1 clock cycle.
            if (tx_trig)
                tx_trig <=0;
                
            if (rx_trig)
                rx_trig <=0;
            
            if (tw_start)
                tw_start <= 0;

            case (state)   
                state_proto_wait_cmd:
                begin
                    if (rx_done)
                    begin
                        case (data_rx)
                            CMD_READ:
                            begin
                                tw_address  <= 0;
                                tw_wr_data  <= 0;
                                rx_addr_len <= ADDR_BYTES - 1;
                                rx_data_len <= DATA_BYTES - 1;
                                cmd     <= data_rx;
                                state   <= state_proto_wait_addr;
                                //Continue RX
                                rx_trig <= 1;
                            end

                            CMD_WRITE:
                            begin
                                tw_address  <= 0;
                                tw_wr_data  <= 0;
                                rx_addr_len <= ADDR_BYTES - 1;
                                rx_data_len <= DATA_BYTES - 1;
                                cmd     <= data_rx;
                                state   <= state_proto_wait_addr;
                                //Continue RX
                                rx_trig <= 1;
                            end
                            
                            CMD_PING:
                            begin
                                // Just send an OK
                                tx_data_len <= 0;
                                data_tx <= CMD_OK;
                                tx_trig <= 1;

                                state <= state_proto_tx_answer;
                            end

                            CMD_ECHO:
                            begin
                                //Continue RX
                                rx_trig <= 1;
                                
                                state <= state_proto_wait_echo_char;
                            end

                            default:
                            begin
                                //Continue RX
                                rx_trig <= 1;
                            end
                        endcase
                    end
                end
                
                state_proto_wait_addr:
                begin
                    if (rx_done)
                    begin
                        tw_address <= tw_address | (data_rx << (rx_addr_len * 8));
                        if (rx_addr_len > 0)
                        begin
                            rx_trig <= 1;
                            rx_addr_len <= rx_addr_len - 1;
                        end
                        else
                        begin
                            if (cmd == CMD_READ)
                            begin
                                // Start tw operation
                                tw_mode_rw = 0;
                                tw_start <= 1;
                                state <= state_proto_tw_started;
                            end
                            else if (cmd == CMD_WRITE)
                            begin
                                rx_trig <= 1;
                                state   <= state_proto_wait_wrdata;
                            end
                            else
                            begin
                                // Should never happen!!!
                                //Continue RX
                                rx_trig <= 1;
                                state <= state_proto_wait_cmd;
                            end
                        end
                    end
                end
                
                state_proto_wait_wrdata:                
                begin
                    if (rx_done)
                    begin
                        tw_wr_data <= tw_wr_data | (data_rx << (rx_data_len * 8));
                        if (rx_data_len > 0)
                        begin
                            rx_trig <= 1;
                            rx_data_len <= rx_data_len - 1;
                        end
                        else
                        begin
                            // Start tw operation
                            tw_mode_rw = 1;
                            tw_start <= 1;
                            state <= state_proto_tw_started;
                        end
                    end
                end
                
                state_proto_tw_started:
                begin
                    if (tw_running)
                    begin
                        state <= state_proto_wait_tw_complete;
                    end
                end

                state_proto_wait_tw_complete:
                begin
                    if (tw_running == 0)
                    begin
                        if (cmd == CMD_WRITE)
                        begin
                            // Just send an OK
                            tx_data_len <= 0;
                            data_tx <= CMD_OK;
                            tx_trig <= 1;
                        end
                        else
                        begin
                            // Send the full data back.
                            tx_data_len <= DATA_BYTES - 1;
                            data_tx <= tw_rd_data >> ((DATA_BYTES - 1) * 8) ;
                            tx_trig <= 1;
                        end
                        state <= state_proto_tx_answer;
                    end
                end

                state_proto_tx_answer:
                begin
                    if (tx_done)
                    begin
                        if (tx_data_len > 0)
                        begin
                            tx_data_len  <= tx_data_len - 1;
                            data_tx <= tw_rd_data >> ((tx_data_len - 1) * 8) ;
                            tx_trig <= 1;
                        end
                        else
                        begin
                            rx_trig <= 1;
                            state   <= state_proto_wait_cmd;
                        end
                    end
                end

                state_proto_wait_echo_char:
                begin
                    if (rx_done)
                    begin
                        // Just send an OK
                        tx_data_len <= 0;
                        data_tx <= data_rx;
                        tx_trig <= 1;

                        state <= state_proto_tx_answer;
                    end
                end
            endcase
        end
    end              
endmodule







