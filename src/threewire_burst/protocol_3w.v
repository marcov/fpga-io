/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

////////////////////////////////////////////////////////////////////////////////////
//
// Decodes the messages from host for 3w R/W.
//
module pcl_3w_master #(parameter PCL_3WM_ADDRESS_BITS      = 10,
                       parameter PCL_3WM_DATA_BITS         = 32,
                       parameter PCL_3WM_BURST_MAX_SIZE    = 32,
                       parameter PCL_3WM_CLK_DIV_MAX       = 256)
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
    
    reg [3:0]   state;    
    localparam  state_proto_wait_cmd          = 0,
                state_proto_wait_burst        = 1,
                state_proto_wait_addr         = 2, 
                state_proto_tw_started        = 3,
                state_proto_wait_wrdata       = 4,
                state_proto_wait_tw_complete  = 5,
                state_proto_tx_answer         = 6,
                state_proto_wait_echo_char    = 7,
                state_proto_wait_set_addr_bits = 8,
                state_proto_wait_set_data_bits = 9,
                state_proto_wait_set_clk_div   = 10;
   
  ////////////////////////////////////////////////////////// 
    // BITS -> /8 -> bytes -> clog2 -> bits needed for len.
    localparam PCL_3WM_ADDRESS_BYTES      = `_cdiv(PCL_3WM_ADDRESS_BITS, 8);
    localparam PCL_3WM_DATA_BYTES         = `_cdiv(PCL_3WM_DATA_BITS, 8);
    localparam PCL_3WM_BURST_WIDTH        = `_clog2(PCL_3WM_BURST_MAX_SIZE);
    localparam PCL_3WM_DATA_BITS_WIDTH    = `_clog2(PCL_3WM_DATA_BITS);
    localparam PCL_3WM_ADDRESS_BITS_WIDTH = `_clog2(PCL_3WM_ADDRESS_BITS);
    localparam PCL_3WM_CLK_DIV_EXP2_MAX   = `_clog2(PCL_3WM_CLK_DIV_MAX);
    localparam PCL_3WM_CLK_DIV_EXP2_WIDTH = `_clog2(PCL_3WM_CLK_DIV_EXP2_MAX);
  ////////////////////////////////////////////////////////// 
    reg [7:0] cmd;
    localparam CMD_MODE_BURST  = (8'h01 << 7);
    localparam CMD_READ        = 8'h00,
               CMD_WRITE       = 8'h01,
               CMD_OK          = 8'h02,
               CMD_ECHO        = 8'h03,
               CMD_PING        = 8'h04,
               CMD_SET_IO_BITS = 8'h05;

  //////////////////////////////////////////////////////////
    // Used to count the number of bytes received before changing state.
    // Max TX size is achieved when answering with a block of data.
    reg [`_clog2(PCL_3WM_DATA_BYTES) - 1 : 0] rx_data_len;
    reg [`_clog2(PCL_3WM_DATA_BYTES) - 1 : 0] tx_data_len;

    reg [`_clog2(PCL_3WM_ADDRESS_BYTES) - 1 : 0] rx_addr_len;

    //Configurable bits for 3W address/data/clk_div
    reg [PCL_3WM_DATA_BITS_WIDTH     : 0]  data_bits;
    reg [PCL_3WM_ADDRESS_BITS_WIDTH  : 0]  addr_bits;
    reg [PCL_3WM_CLK_DIV_EXP2_WIDTH : 0]   clk_div_exp2;

  ////////////////////////////////////////////////////////// 
    reg tw_start;
    reg tw_mode_rw;
    reg [PCL_3WM_ADDRESS_BITS - 1 : 0] tw_address;
    reg [PCL_3WM_BURST_WIDTH - 1 : 0]  tw_burst_reps;
    reg [PCL_3WM_BURST_WIDTH - 1 : 0]  burst_ctr;
  ////////////////////////////////////////////////////////// 
    wire [PCL_3WM_BURST_WIDTH - 1 : 0] mem_addr_tw;
    reg  [PCL_3WM_BURST_WIDTH - 1 : 0] mem_addr_pcl;
    wire [PCL_3WM_DATA_BITS   - 1 : 0] mem_dout_tw;
    wire [PCL_3WM_DATA_BITS   - 1 : 0] mem_dout_pcl;
    wire [PCL_3WM_DATA_BITS   - 1 : 0] mem_din_tw;
    reg  [PCL_3WM_DATA_BITS   - 1 : 0] mem_din_pcl;
    wire mem_wr_tw;
    reg  mem_wr_pcl;
    
    threewire_master_ctrl #(
                .TWM_ADDRESS_BITS(PCL_3WM_ADDRESS_BITS),
                .TWM_DATA_BITS(PCL_3WM_DATA_BITS),
                .TWM_ADDRESS_BITS_WIDTH(PCL_3WM_ADDRESS_BITS_WIDTH),
                .TWM_DATA_BITS_WIDTH(PCL_3WM_DATA_BITS_WIDTH),
                .TWM_BURST_WIDTH(PCL_3WM_BURST_WIDTH),
                .TWM_CLK_DIV_EXP2_WIDTH(PCL_3WM_CLK_DIV_EXP2_WIDTH))

              tw_master(.in_clk (in_clk),
                        .in_rst (in_rst),
                        .in_mode_wr (tw_mode_rw),
                        .in_addr(tw_address),
                        .in_burst_reps(tw_burst_reps),
                        .out_mem_addr(mem_addr_tw),
                        .out_mem_data(mem_din_tw),
                        .in_mem_data(mem_dout_tw),
                        .out_mem_wr(mem_wr_tw),
                        .addr_bits(addr_bits),
                        .data_bits(data_bits),
                        .in_clk_div_exp2(clk_div_exp2),
                        .in_start(tw_start),
                        .out_io_in_progress(tw_running),
                        .out_tw_clock (out_tw_clock),
                        .out_tw_cs    (out_tw_cs),
                        .io_tw_data   (io_tw_data),
                        .out_tw_dir   (out_tw_dir));
  
    
    ram_dualport #(.RAM_ADDR_WIDTH(PCL_3WM_BURST_WIDTH),
                   .RAM_DATA_WIDTH(PCL_3WM_DATA_BITS))
                 mem_tw      (.in_clk(in_clk),
                              .in_addr_a(mem_addr_tw),
                              .in_addr_b(mem_addr_pcl),
                              .out_data_a(mem_dout_tw),
                              .out_data_b(mem_dout_pcl),
                              .in_data_a(mem_din_tw),
                              .in_data_b(mem_din_pcl),
                              .in_wr_a  (mem_wr_tw),
                              .in_wr_b  (mem_wr_pcl));

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
            mem_wr_pcl <= 0;
            mem_addr_pcl <= 0;
            // Set default value for 3w data/address bits
            data_bits <= PCL_3WM_DATA_BITS;
            addr_bits <= PCL_3WM_ADDRESS_BITS;
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

            if (mem_wr_pcl)
            begin
                mem_wr_pcl <= 0;
                //Set mem access value for the next write 
                mem_addr_pcl <= mem_addr_pcl + 1;
                mem_din_pcl <= 0;
            end
            
            case (state)   
                state_proto_wait_cmd:
                begin
                    if (rx_done)
                    begin
                        case (data_rx & ~(CMD_MODE_BURST))
                            CMD_READ:
                            begin
                                tw_address  <= 0;
                                rx_addr_len <= `_cdiv8(addr_bits) - 1;
                                cmd     <= data_rx;
                                if (data_rx & CMD_MODE_BURST)
                                    state   <= state_proto_wait_burst;
                                else
                                begin
                                    state         <= state_proto_wait_addr;
                                    tw_burst_reps <= 0;
                                    burst_ctr     <= 0;
                                end
                                //Continue RX
                                rx_trig <= 1;
                            end

                            CMD_WRITE:
                            begin
                                tw_address  <= 0;
                                rx_addr_len <= `_cdiv8(addr_bits) - 1;
                                rx_data_len <= `_cdiv8(data_bits) - 1;
                                cmd     <= data_rx;
                                if (data_rx & CMD_MODE_BURST)
                                    state   <= state_proto_wait_burst;
                                else
                                begin
                                    state         <= state_proto_wait_addr;
                                    tw_burst_reps <= 0;
                                    burst_ctr     <= 0;
                                end
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

                            CMD_SET_IO_BITS:
                            begin
                                //Continue RX
                                rx_trig <= 1;
                                
                                state <= state_proto_wait_set_addr_bits;
                            end
                            
                            default:
                            begin
                                //Continue RX
                                rx_trig <= 1;
                            end
                        endcase
                    end
                end
               
                state_proto_wait_burst:
                begin
                    if (rx_done)
                    begin
                        tw_burst_reps <= data_rx;
                        burst_ctr     <= data_rx;
                        state        <= state_proto_wait_addr;
                        //Continue RX
                        rx_trig <= 1;
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
                            mem_addr_pcl <= 0;
                            mem_din_pcl  <= 0;
                            if ((cmd & ~CMD_MODE_BURST) == CMD_READ)
                            begin
                                // Start tw operation
                                tw_mode_rw = 0;
                                tw_start <= 1;
                                state <= state_proto_tw_started;
                            end
                            else if ((cmd & ~CMD_MODE_BURST) == CMD_WRITE)
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
                        mem_din_pcl <= mem_din_pcl | (data_rx << (rx_data_len * 8));

                        if (rx_data_len > 0)
                        begin
                            rx_trig <= 1;
                            rx_data_len <= rx_data_len - 1;
                        end
                        else
                        begin
                            mem_wr_pcl <= 1;
                            
                            if (burst_ctr > 0)
                            begin
                                burst_ctr <= burst_ctr - 1;
                                rx_data_len <= `_cdiv8(data_bits) - 1;
                                rx_trig <= 1;
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
                        if ((cmd & ~CMD_MODE_BURST) == CMD_WRITE)
                        begin
                            // Just send an OK
                            tx_data_len <= 0;
                            data_tx     <= CMD_OK;
                            tx_trig     <= 1;
                        end
                        else
                        begin
                            // cmd is CMD_READ
                            // Send the full data back.
                            
                            tx_data_len <= `_cdiv8(data_bits) - 1;
                            data_tx     <= mem_dout_pcl >> ((`_cdiv8(data_bits) - 1) * 8) ;
                            tx_trig     <= 1;
                            // Special case of single data byte 
                            if (`_cdiv8(data_bits) - 1 == 0) mem_addr_pcl <= mem_addr_pcl + 1;
                            
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
                            data_tx <= mem_dout_pcl >> ((tx_data_len - 1) * 8) ; 
                            tx_trig <= 1;
                            // Prepare address for next clock cycle 
                            if (tx_data_len - 1 == 0) mem_addr_pcl <= mem_addr_pcl + 1;
                        end
                        else
                        begin
                            if (burst_ctr > 0)
                            begin
                                burst_ctr <= burst_ctr - 1;
                                
                                tx_data_len <= `_cdiv8(data_bits) - 1;
                                data_tx     <= mem_dout_pcl >> ((`_cdiv8(data_bits) - 1) * 8) ;
                                tx_trig     <= 1;
                                // Special case of single data byte 
                                if (`_cdiv8(data_bits) - 1 == 0) mem_addr_pcl <= mem_addr_pcl + 1;
                            end
                            else
                            begin
                                rx_trig <= 1;
                                state   <= state_proto_wait_cmd;
                            end
                        end
                    end
                end

                state_proto_wait_echo_char:
                begin
                    if (rx_done)
                    begin
                        // Just send back the ECHO char 
                        tx_data_len <= 0;
                        data_tx <= data_rx;
                        tx_trig <= 1;

                        state <= state_proto_tx_answer;
                    end
                end
                
                state_proto_wait_set_addr_bits:
                begin
                    if (rx_done)
                    begin
                        addr_bits <= data_rx;
                        rx_trig <= 1;

                        state <= state_proto_wait_set_data_bits;
                    end
                end
                
                state_proto_wait_set_data_bits:
                begin
                    if (rx_done)
                    begin
                        data_bits <= data_rx;
                        rx_trig <= 1;
                        state <= state_proto_wait_set_clk_div;
                    end
                end
                                
                state_proto_wait_set_clk_div:
                begin
                    if (rx_done)
                    begin
                        clk_div_exp2 <= data_rx;

                        // Just send an OK
                        tx_data_len <= 0;
                        data_tx <= CMD_OK;
                        tx_trig <= 1;
                        state <= state_proto_tx_answer;
                    end
                end

            endcase
        end
    end              
endmodule







