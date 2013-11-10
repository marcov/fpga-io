module threewire(input in_clk,
                 input in_rst,
                 input in_r_w,
                 input [ADDR_BITS - 1:0] in_addr,
                 input [DATA_BITS - 1:0] in_wr_data,
                 output reg [DATA_BITS - 1:0] in_rd_data,
                 input in_start,
                 output out_io_in_progress,
                 output out_tw_clock,
                 output reg out_tw_cs,
                 inout  io_tw_data);
    
    parameter ADDR_BITS = 9;
    parameter DATA_BITS = 15;
    
    reg [1:0] ctr_div;
    reg [3:0] io_bits_ctr;
    reg clk_enable;
    reg io_hiz_enable;
    reg tw_wr_data;
    
    
    reg [2:0]  state;
    localparam state_idle        = 0, 
              state_chip_select  = 1,
               state_txing_r_w   = 2,
               state_txing_addr  = 3,
               state_txing_wr_data = 4,
               state_rcving_rd_data = 5;

    assign io_tw_data = io_hiz_enable ? 1'bz : tw_wr_data;
    assign out_tw_cs  = clk_enable    ? ctr_div[1] : 1'bz; 
    
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
        end
        else
        begin
            ctr_div <= ctr_div + 1;
            
            if (ctr_div == 2'b11)
            begin
                case (state)
                begin
                    state_idle:
                    begin
                        if (start)
                        begin
                            clk_enable <= 1;
                            state <= state_chip_select;
                        end
                    end
                    
                    state_chip_select:
                    begin
                        state     <= state_txing_r_w;
                        out_tw_cs <= 0;
                    end
                    
                    state_txing_r_w:
                    begin
                        tw_wr_data  <= in_r_w;
                        state       <= state_txing_r_w;
                        io_bits_ctr <= ADDR_BITS - 1;
                    end
                    
                    state_txing_addr:
                    begin
                        if (io_bits_ctr > 0)
                        begin
                            io_bits_ctr < = io_bits_ctr - 1;
                        end
                        else
                        begin
                            if (in_r_w == 0)
                                state <= state_rcving_rd_data;
                            else
                                state <= state_txing_wr_data;
                        end
                        tw_wr_data  <= in_addr[io_bits_ctr];
                    end
                    
                    
                end
            end
        end
    end
endmodule