/* Threewire Master
 *
 * Signal description:
 * in_clk     : main input clock.
 * in_rst     : reset.
 * in_addr    : address to be transmitted over 3w
 * in_wr_data : data to be transmitted over 3w in a write operation.
 * out_rd_data: data received from slave over 3w in a read operation.
 * in_start : (single clock cycle) start of operation signal.
 * out_io_in_progress: output signal, high when 3w operation is in progress.
 * out_tw_clock: the 3w bus clock.
 * out_tw_cs   : the 3w bus chip select.
 * io_tw_data  : the 3w bus bi-direction io data line.
 *
 */

module threewire_master_ctrl #(
                   parameter TWM_ADDRESS_BITS  = 10,
                   parameter TWM_DATA_BITS  = 32,
                   parameter TWM_CLK_DIV_2N = 4) 
                  (input in_clk,
                   input in_rst,
                   input in_mode_wr,
                   input [TWM_ADDRESS_BITS - 1:0] in_addr,
                   input [TWM_DATA_BITS - 1:0] in_wr_data,
                   output reg [TWM_DATA_BITS - 1:0] out_rd_data,
                   input in_start,
                   output reg out_io_in_progress,
                   output out_tw_clock,
                   output reg out_tw_cs,
                   inout  io_tw_data,
                   output out_tw_dir);

    // Include functions builtins redefinition for which XST is missing support.
    `include "builtins_redefined.v"


    reg [`_clog2(TWM_CLK_DIV_2N) - 1 : 0] clk_div_ctr;
    reg [`_clog2(`_max(TWM_ADDRESS_BITS, TWM_DATA_BITS)) - 1 : 0] io_bits_ctr;
    //reg clk_enable;
    reg io_hiz_enable;
    reg tw_wr_data;

    reg [2:0]  state;
    localparam state_idle           = 0,
               state_ready          = 1,
               state_txing_r_w      = 2,
               state_txing_addr     = 3,
               state_txing_wr_data  = 4,
               state_rcv_prepare    = 5,
               state_rcving_rd_data = 6,
               state_completed      = 7;

    assign io_tw_data = io_hiz_enable ? 1'bz : tw_wr_data;
    //assign out_tw_clock = clk_enable    ? clk_div_ctr[_clog2(TWM_CLK_DIV_2N) - 1] : 1'b0; 
    /* Keep clock always active */
    assign out_tw_clock = clk_div_ctr[`_clog2(TWM_CLK_DIV_2N) - 1];
    
    // DIR = 0 means we are TXING (Schmitt-trigger inverted on board)
    assign out_tw_dir = io_hiz_enable;

    always @ (posedge in_clk, posedge in_rst)
    begin
        if (in_rst)
        begin
            clk_div_ctr   <= 'd0;
            io_hiz_enable <= 'b0;
            //clk_enable    <= 'd0;
            out_tw_cs     <= 'd1;
            tw_wr_data    <= 'd0;
            io_bits_ctr   <= 'b0;
            state <=      state_idle;
            out_io_in_progress <= 'b0;
        end
        else
        begin
            clk_div_ctr <= clk_div_ctr + 1;
            
            // state_idle is not in case block, because
            // we must be ready to answer to in_start within 
            // 1 in_clk cycle.
            // case block time base is on clk divided by X.
            if (state == state_idle)
            begin
                if (in_start)
                begin
                    state <= state_ready;
                    //clk_enable <= 1;
                    out_io_in_progress <= 1;
                end
                else
                begin
                    //clk_enable    <= 0;
                    io_hiz_enable <= 'b0;
                    out_io_in_progress <= 'b0;
                end
            end
            else
            begin
                if (clk_div_ctr == (TWM_CLK_DIV_2N - 1))
                begin
                    case (state)
                        state_ready:
                        begin
                            state <= state_txing_r_w;
                        end
                        
                        state_txing_r_w:
                        begin
                            out_tw_cs <= 'b0;
                            tw_wr_data  <= in_mode_wr;
                            state       <= state_txing_addr;
                            io_bits_ctr <= TWM_ADDRESS_BITS - 1;
                        end
                        
                        state_txing_addr:
                        begin
                            if (io_bits_ctr > 0)
                            begin
                                io_bits_ctr <= io_bits_ctr - 1;
                            end
                            else
                            begin
                                if (in_mode_wr == 0)
                                    state <= state_rcv_prepare;
                                else
                                begin
                                    state <= state_txing_wr_data;
                                end

                                //setting io_bits_ctr for the rd/write data state 
                                io_bits_ctr <= TWM_DATA_BITS - 1;
                            end
                            tw_wr_data  <= in_addr[io_bits_ctr];
                        end
                       
                        // State to switch io line to input. 
                        state_rcv_prepare:
                        begin
                            state         <= state_rcving_rd_data;
                            io_hiz_enable <= 'b1;
                        end


                        state_rcving_rd_data:
                        begin
                            if (io_bits_ctr > 0)
                            begin
                                io_bits_ctr <= io_bits_ctr - 1;
                            end
                            else
                                state <= state_completed;
                            
                            out_rd_data[io_bits_ctr] <= io_tw_data;
                        end

                        state_txing_wr_data:
                        begin
                            if (io_bits_ctr > 0)
                                io_bits_ctr <= io_bits_ctr - 1;
                            else
                                state <= state_completed;
                            
                            tw_wr_data  <= in_wr_data[io_bits_ctr];
                        end

                        state_completed:
                        begin
                            state     <= state_idle;
                            out_tw_cs <= 'b1;
                        end

                        default:
                        begin
                            /* something wrong ?? */
                            state     <= state_idle;
                        end
                    endcase
                end //if clk_div_ctr
            end //if in_start ... else
        end //if rst
    end // always @
endmodule
