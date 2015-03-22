/**
 * Project: USB-IO FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

////////////////////////////////////////////////////////////////////////////////////
//
// Decodes the messages from host for 3w R/W.
//
module pcl_bitbang #(parameter PCL_BB_IO_NUM_OF = 10)
                      (input  in_clk,
                       input  in_rst,
                       input      [7:0] data_rx,
                       output reg [7:0] data_tx,
                       input  rx_done,
                       input  tx_done,
                       output reg rx_trig,
                       output reg tx_trig,
                       //
                       inout  [PCL_BB_IO_NUM_OF - 1 : 0] io_pins);
    
    // Include functions builtins redefinition for which XST is missing support.
    `include "builtins_redefined.v"
    
    reg [2:0]   state;    
    localparam  state_proto_wait_cmd         = 0,
                state_proto_wait_param       = 1,
                state_proto_wait_data        = 2,
                state_proto_update_io        = 3,
                state_proto_tx_answer        = 4,
                state_proto_wait_echo_char   = 5;
    
  ////////////////////////////////////////////////////////// 
    // BITS -> /8 -> bytes -> clog2 -> bits needed for len.
    
    localparam PCL_BB_DATA_BYTES = `_cdiv(PCL_BB_IO_NUM_OF, 8);

  ////////////////////////////////////////////////////////// 
    reg [7:0] cmd;
    localparam CMD_READ       = 8'h00,
               CMD_WRITE      = 8'h01,
               CMD_OK         = 8'h02,
               CMD_ECHO       = 8'h03,
               CMD_PING       = 8'h04;

    reg [7:0] param;
    localparam PARAM_DIRECTION = 8'h00,
               PARAM_OUTVAL    = 8'h01;

  //////////////////////////////////////////////////////////
    // Used to count the number of bytes received before changing state.
    // Max TX size is achieved when answering with a block of data.
    reg [`_clog2(PCL_BB_DATA_BYTES) - 1 : 0] pcl_rx_len;
    reg [`_clog2(PCL_BB_DATA_BYTES) - 1 : 0] pcl_tx_len;

  ////////////////////////////////////////////////////////// 
    reg  [PCL_BB_IO_NUM_OF - 1 : 0]    bb_outval;
    reg  [PCL_BB_IO_NUM_OF - 1 : 0]    bb_direction;
    reg  [PCL_BB_IO_NUM_OF - 1 : 0]    bb_new_outval;
    reg  [PCL_BB_IO_NUM_OF - 1 : 0]    bb_new_direction;
    
    bitbang_ctrl #(
                .IO_NUM_OF(PCL_BB_IO_NUM_OF))
                bb_instance(.in_io_direction(bb_direction),
                            .in_io_outval(bb_outval),
                            .io_pins(io_pins));
                            
   
  ////////////////////////////////////////////////////////// 
  ////////////////////////////////////////////////////////// 
    always @ (posedge in_clk, posedge in_rst)
    begin
        if (in_rst)
        begin
            state <= state_proto_wait_cmd;
            rx_trig <= 0;
            tx_trig <= 0;

            bb_direction <= 0;
            bb_outval    <= 0;

            cmd   <= 0;
            param <= 0;
        end
        else
        begin
        
            // Make trig/start high duration of 1 clock cycle.
            if (tx_trig)
                tx_trig <=0;
                
            if (rx_trig)
                rx_trig <=0;
            
            case (state)   
                state_proto_wait_cmd:
                begin
                    if (rx_done)
                    begin
                        case (data_rx)
                            CMD_READ:
                            begin
                                cmd         <= data_rx;
                                state       <= state_proto_tx_answer;
                                pcl_tx_len  <= PCL_BB_DATA_BYTES - 1;
                                data_tx     <= io_pins >> ((PCL_BB_DATA_BYTES - 1) * 8) ;
                                
                                tx_trig <= 1;
                            end

                            CMD_WRITE:
                            begin
                                cmd         <= data_rx;
                                state       <= state_proto_wait_param;
                                //Continue RX
                                rx_trig <= 1;
                                bb_new_outval    <= 0;
                                bb_new_direction <= 0;
                            end
                            
                            CMD_PING:
                            begin
                                // Just send an OK
                                pcl_tx_len <= 0;
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
                

                state_proto_wait_param:
                begin
                    if (rx_done)
                    begin
                        pcl_rx_len  <= PCL_BB_DATA_BYTES - 1;
                        param       <= data_rx;
                        
                        state       <= state_proto_wait_data;
                        //Continue RX
                        rx_trig <= 1;
                    end
                end


                state_proto_wait_data:                
                begin
                    if (rx_done)
                    begin
                        if (param === PARAM_OUTVAL)
                        begin
                            bb_new_outval <= bb_new_outval | (data_rx << (pcl_rx_len * 8));
                        end
                        else if (param === PARAM_DIRECTION)
                        begin
                            bb_new_direction <= bb_new_direction | (data_rx << (pcl_rx_len * 8));
                        end

                        if (pcl_rx_len > 0)
                        begin
                            rx_trig <= 1;
                            pcl_rx_len <= pcl_rx_len - 1;
                        end
                        else
                        begin
                            // Set values here!
                            state <= state_proto_update_io;
                        end
                    end
                end
               
                state_proto_update_io:
                begin
                    if (param === PARAM_OUTVAL)
                    begin
                        bb_outval <= bb_new_outval;
                    end
                    else if (param === PARAM_DIRECTION)
                    begin
                        bb_direction <= bb_new_direction; 
                    end

                    // Just send an OK
                    pcl_tx_len <= 0;
                    data_tx <= CMD_OK;
                    tx_trig <= 1;

                    state <= state_proto_tx_answer;
                end

                state_proto_tx_answer:
                begin
                    if (tx_done)
                    begin
                        if (pcl_tx_len > 0)
                        begin
                            pcl_tx_len  <= pcl_tx_len - 1;
                            data_tx     <= io_pins >> ((pcl_tx_len - 1) * 8) ;
                            tx_trig     <= 1;
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
                        pcl_tx_len <= 0;
                        data_tx <= data_rx;
                        tx_trig <= 1;

                        state <= state_proto_tx_answer;
                    end
                end
            endcase
        end
    end              
endmodule







