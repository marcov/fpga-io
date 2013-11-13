module threewire(input in_clk,
                 input in_rst,
                 input in_r_w,
                 input [ADDR_BITS - 1:0] in_addr,
                 input [DATA_BITS - 1:0] in_wr_data,
                 output reg [DATA_BITS - 1:0] out_rd_data,
                 input in_start,
                 output reg out_io_in_progress,
                 output out_tw_clock,
                 output reg out_tw_cs,
                 inout  io_tw_data);
    
    parameter ADDR_BITS = 9;
    parameter DATA_BITS = 16;
    
    reg [1:0] ctr_div;
    reg [3:0] io_bits_ctr;
    reg clk_enable;
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

    assign io_tw_data  = io_hiz_enable ? 1'bz : tw_wr_data;
    assign out_tw_clock  = clk_enable    ? ctr_div[1] : 1'bz; 
    
    always @ (posedge in_clk, posedge in_rst)
    begin
        if (in_rst)
        begin
            ctr_div       <= 0;
            io_hiz_enable <= 0;
            clk_enable    <= 0;
            out_tw_cs     <= 1;
            tw_wr_data    <= 0;
            io_bits_ctr   <= 0;
            state <=      state_idle;
            out_io_in_progress <= 0;
        end
        else
        begin
            // state_idle is not in case block, because
            // we must be ready to answer to in_start within 
            // 1 in_clk cycle.
            // case block time base is on clk divided by X.
            if (state == state_idle)
            begin
                if (in_start)
                begin
                    state <= state_ready;
                    clk_enable <= 1;
                end
                else
                begin
                    clk_enable    <= 0;
                    io_hiz_enable <= 0;
                end
            end
            else
            begin
                ctr_div <= ctr_div + 1;
                
                if (ctr_div == 2'b11)
                begin
                    case (state)
                        state_ready:
                        begin
                            state <= state_txing_r_w;
                        end
                        
                        state_txing_r_w:
                        begin
                            out_tw_cs <= 0;
                            tw_wr_data  <= in_r_w;
                            state       <= state_txing_addr;
                            io_bits_ctr <= ADDR_BITS - 1;
                        end
                        
                        state_txing_addr:
                        begin
                            if (io_bits_ctr > 0)
                            begin
                                io_bits_ctr <= io_bits_ctr - 1;
                            end
                            else
                            begin
                                if (in_r_w == 0)
                                    state <= state_rcv_prepare;
                                else
                                    state <= state_txing_wr_data;
                                
                                io_bits_ctr <= DATA_BITS - 1;
                            end
                            tw_wr_data  <= in_addr[io_bits_ctr];
                        end
                        
                        state_rcv_prepare:
                        begin
                            state         <= state_rcving_rd_data;
                            io_hiz_enable <= 1;
                        end


                        state_rcving_rd_data:
                        begin
                            if (io_bits_ctr > 0)
                                io_bits_ctr <= io_bits_ctr - 1;
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
                            out_tw_cs <= 1;
                        end

                        default:
                        begin
                            /* something wrong ?? */
                            state     <= state_idle;
                        end
                    endcase
                end //if ctr_div
            end //if in_start ... else
        end //if rst
    end // always @
endmodule
