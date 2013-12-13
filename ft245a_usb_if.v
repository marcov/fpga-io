////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date:    23:06:02 10/08/2013 
// Design Name: 
// Module Name:     
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
////////////////////////////////////////////////////////////////////////////////
module ft245_asynch_ctrl(
                      in_clk,
                      in_rst,
                      in_ftdi_txe, 
                      in_ftdi_rxf,
                      io_ftdi_data, 
                      out_ftdi_wr, 
                      out_ftdi_rd,
                      in_rx_en,
                      in_tx_hsk_req,
                      out_tx_hsk_ack,
                      in_tx_data,
                      out_rx_data,
                      out_rx_hsk_req,
                      in_rx_hsk_ack);
//////////                  
// Input / output    
    input in_clk;
    input in_rst;
    
    // From: FTDI. Asserted by FTDI when data can be written.
    input wire in_ftdi_txe;       
    // From: FTDI. Asserted by FTDI when data can be read.
    input wire in_ftdi_rxf;   
    // To: FTDI. Strobed on data writing.
    output reg out_ftdi_wr;
    // To: FTDI. Strobed on data reading.
    output reg out_ftdi_rd;
    // To/From: FTDI. 8-bit parallel data input/output.
    inout [7:0] io_ftdi_data;       
    // To: Top level. Used to enable/disable RX.
    input wire in_rx_en;
    // From: Top level. Data to send to FTDI.
    input  wire [7:0] in_tx_data;
    // To: Top level. Data received from FTDI.
    output reg  [7:0] out_rx_data;
    // TX handshake interlock request/acknowledge.
    input wire in_tx_hsk_req;
    output reg out_tx_hsk_ack;
    // RX handshake interlock request/acknowledge.
    output reg  out_rx_hsk_req;
    input  wire in_rx_hsk_ack;
   
    // Buffer holding tx data.
    reg [7:0] tx_data;

//////////
//  FSM
    reg [2:0] state;
    reg [2:0] next_state;

    localparam state_ready           = 0,
               state_rx_data_avlb    = 1,
               state_rx_data_hsk     = 2,
               state_tx_data_hsk     = 3,
               state_tx_data_rdy     = 4,
               state_tx_data_gnt     = 5,
               state_tx_data_hld     = 6;

///////////
// Timing definitions for FTDI reading/writing.
    reg [2:0] delay_counter;
    
	 //Calculation based on 1 tick = 15ns when running at 66MHz

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

////////////
//  FTDI I/O bidirectional buffer control. Aka IOBUF. 
//  (note that IOBUF input/output naming is opposite than FPGA point of view):
//   - INPUT: from FPGA to PAD.
//   - OUTPUT: from PAD to FPGA.
//   - T: when high, set OUTPUT buffer in three-state mode.
    reg ftdi_output_enable;
    
///////////
// Bidirectional FTDI I/O handling.
    assign io_ftdi_data = ftdi_output_enable ? tx_data : 8'bz;
    
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
              in_rx_en, 
              in_ftdi_rxf, 
              in_tx_hsk_req,
              in_rx_hsk_ack)
    begin: next_state_logic
        /* Set a default state to avoid latches creation */
        next_state = state;

        case (state)
            // Ready to receive/transmit.
            state_ready :
            begin
                begin
                    if (in_rx_en && in_ftdi_rxf)
                    begin
                       next_state = state_rx_data_avlb;
                    end
                    else if (in_tx_hsk_req)
                    begin
                        next_state = state_tx_data_hsk;
                    end
                end
            end
            
            // RX 1B from FTDI completed.
            state_rx_data_avlb:
            begin
                next_state = state_rx_data_hsk;
            end
            
            // Handshake for passing RX byte to top-level.
            state_rx_data_hsk:
            begin
                //handshake synchronization. Hold on.
                if (in_rx_hsk_ack)
                begin
                    next_state = state_ready;
                end
            end
            
            //Handshake for receiving TX data from top-level.
            state_tx_data_hsk:
            begin
                if (in_tx_hsk_req == 0)
                    next_state = state_tx_data_rdy;
            end
            
            //TX ready, waiting for FTDI allowance.
            state_tx_data_rdy:
            begin
                if (in_ftdi_txe)
                begin
                    next_state = state_tx_data_gnt;
                end
            end
            
            //TX granted from FTDI, holding WR strobe.
            state_tx_data_gnt:
            begin
                next_state = state_tx_data_hld;
            end
            
            //TX 1 byte completed.
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
            out_rx_data       <= 0;
        end
        else
        begin
            case (state)
                state_ready:
                begin
                    if (next_state == state_tx_data_hsk)
                    begin
                        // Sample tx data here.
                        tx_data = in_tx_data;
                    end
                    state <= next_state;
                end

                state_rx_data_avlb:
                begin
                
                    if (delay_counter < t4_rd_active)
                    begin
                        delay_counter <= delay_counter + 1;
                        if (delay_counter == t3_rd_to_sample)
                        begin
                            // sample input.
                            out_rx_data  <= io_ftdi_data;
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
                
                    if (delay_counter < t8_data_to_wr)
                    begin
                        delay_counter <= delay_counter + 1;
                    end
                    else
                    begin
                        delay_counter <= 0;
                        state <= next_state;
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
                        state <= next_state;
                    end
                end

                default:
                begin
                    state <= next_state;
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
                ftdi_output_enable = 0;
                out_ftdi_rd = 0;
                out_rx_hsk_req = 0;
                out_tx_hsk_ack = 0;
            end
            state_rx_data_avlb:
            begin
                out_ftdi_wr = 0;
                ftdi_output_enable = 0;
                out_ftdi_rd = 1;
                out_rx_hsk_req = 0;
                out_tx_hsk_ack = 0;
            end
            state_rx_data_hsk:
            begin
                out_ftdi_wr = 0;
                ftdi_output_enable = 0;
                out_ftdi_rd = 0;
                out_rx_hsk_req = 1;
                out_tx_hsk_ack = 0;
            end
            state_tx_data_hsk:
            begin
                out_ftdi_wr = 0; 
                ftdi_output_enable = 0;
                out_ftdi_rd = 0;
                out_rx_hsk_req = 0;
                out_tx_hsk_ack = 1;
            end
            state_tx_data_rdy:
            begin
                out_ftdi_wr = 0; 
                ftdi_output_enable = 0;
                out_ftdi_rd = 0;
                out_rx_hsk_req = 0;
                out_tx_hsk_ack = 0;
            end
            state_tx_data_gnt:
            begin
                out_ftdi_wr = 0;
                ftdi_output_enable = 1;
                out_ftdi_rd = 0;
                out_rx_hsk_req = 0;
                out_tx_hsk_ack = 0;
            end
            state_tx_data_hld:
            begin
                out_ftdi_wr = 1;
                ftdi_output_enable = 1;
                out_ftdi_rd = 0;
                out_rx_hsk_req = 0;
                out_tx_hsk_ack = 0;
				end
            default:   
            begin
                out_ftdi_wr = 0; 
                ftdi_output_enable = 0;
                out_ftdi_rd = 0;
                out_rx_hsk_req = 0;
                out_tx_hsk_ack = 0;
            end
        endcase
    end
endmodule

////////////////////////////////////////////////////////////////////////////
//
//
//
