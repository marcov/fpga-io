////////////////////////////////////////////////////////////////////////////////////
//
// Decodes the messages from host for 3w R/W.
//
module pcl_3w_master #(parameter PCL_3WM_ADDRESS_BITS = 10,
                       parameter PCL_3WM_DATA_BITS    = 32,
                       parameter PCL_3WM_CLK_DIV_2N   = 4)
                      (input  in_clk,
                       input  in_rst,
                       input      [7:0] data_rx,
                       output reg [7:0] data_tx,
                       input  rx_done,
                       input  tx_done,
                       output reg rx_trig,
                       output reg tx_trig,
                       output out_tw_clock,
                       output out_tw_cs,
                       inout  io_tw_data,
                       output out_tw_dir);
    
    // Include functions builtins redefinition for which XST is missing support.
    `include "builtins_redefined.v"
    
    reg [2:0]   state;    
    localparam  state_proto_wait_cmd         = 0,
                state_proto_wait_addr        = 1, 
                state_proto_tw_started       = 2,
                state_proto_wait_wrdata      = 3,
                state_proto_wait_tw_complete = 4,
                state_proto_tx_answer        = 5,
                state_proto_wait_echo_char   = 6;
    
  ////////////////////////////////////////////////////////// 
    // BITS -> /8 -> bytes -> clog2 -> bits needed for len.
    
    localparam PCL_3W_ADDRESS_BYTES = _cdiv(PCL_3WM_ADDRESS_BITS, 8);
    localparam PCL_3W_DATA_BYTES = _cdiv(PCL_3WM_DATA_BITS, 8);

  ////////////////////////////////////////////////////////// 
    reg [7:0] cmd;
    localparam CMD_READ  = 8'h0,
               CMD_WRITE = 8'h1,
               CMD_OK    = 8'h2,
               CMD_ECHO  = 8'h03,
               CMD_PING  = 8'h04;

  //////////////////////////////////////////////////////////
    // Used to count the number of bytes received before changing state.
    // Max TX size is achieved when answering with a block of data.
    reg [_clog2(PCL_3W_DATA_BYTES) - 1 : 0] rx_data_len;
    reg [_clog2(PCL_3W_DATA_BYTES) - 1 : 0] tx_data_len;

    reg [_clog2(PCL_3W_ADDRESS_BYTES) - 1 : 0] rx_addr_len;
  ////////////////////////////////////////////////////////// 
    reg tw_start;
    reg tw_mode_rw;
    wire[PCL_3WM_DATA_BITS - 1 : 0]    tw_rd_data;
    reg [PCL_3WM_DATA_BITS - 1 : 0]    tw_wr_data;
    reg [PCL_3WM_ADDRESS_BITS - 1 : 0] tw_address;

    threewire_master_ctrl #(
                .TWM_ADDRESS_BITS(PCL_3WM_ADDRESS_BITS),
                .TWM_DATA_BITS(PCL_3WM_DATA_BITS),
                .TWM_CLK_DIV_2N(PCL_3WM_CLK_DIV_2N))
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
                        .io_tw_data   (io_tw_data),
                        .out_tw_dir   (out_tw_dir));
   
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
                                rx_addr_len <= PCL_3W_ADDRESS_BYTES - 1;
                                rx_data_len <= PCL_3W_DATA_BYTES - 1;
                                cmd     <= data_rx;
                                state   <= state_proto_wait_addr;
                                //Continue RX
                                rx_trig <= 1;
                            end

                            CMD_WRITE:
                            begin
                                tw_address  <= 0;
                                tw_wr_data  <= 0;
                                rx_addr_len <= PCL_3W_ADDRESS_BYTES - 1;
                                rx_data_len <= PCL_3W_DATA_BYTES - 1;
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
                            tx_data_len <= PCL_3W_DATA_BYTES - 1;
                            data_tx <= tw_rd_data >> ((PCL_3W_DATA_BYTES - 1) * 8) ;
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







