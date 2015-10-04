

module i2c_slave
#(
    parameter MEM_ADDR_WIDTH         = 16,
    parameter MEM_DATA_WIDTH         = 8,
    parameter SDA_SETUP_DELAY_CYCLES = 3
)
(   input      in_clk,
    input      in_rst_n,
    input      in_scl,
    inout      io_sda,
    output reg out_sda_oe,
    output     [MEM_ADDR_WIDTH - 1 : 0] out_mem_addr,
    input      [MEM_DATA_WIDTH - 1 : 0] in_mem_data);

    
    localparam STATE_IDLE             = 0,
               STATE_WAIT_I2C_ADDR    = 1,
               STATE_WAIT_DATA_BYTE   = 2,
               STATE_WAIT_RESTART     = 4,
               STATE_TX_DATA          = 5,
               STATE_WAIT_ACK         = 6,
               STATE_TX_ACK           = 7;

    reg [MEM_ADDR_WIDTH - 1 : 0] addr_register;
    reg          out_sda;
    reg [4 : 0]  state;
    reg [4 : 0]  next_state;
    reg [4 : 0]  rx_bit_ctr;
    reg [4 : 0]  tx_bit_ctr;
    reg [7 : 0]  rx_byte;
    reg [7 : 0]  rx_byte_upctr;
    reg [7 : 0]  tx_byte;
    reg          flag_start_det;
    reg          flag_stop_det;
    reg          flag_rw;
    reg [7 : 0]  dly_upctr;
    reg          flag_oe;

    assign io_sda = out_sda_oe && !out_sda ? 1'b0 : 1'bz;

    wire in_sda = !(io_sda === 'b0);

    assign out_mem_addr = addr_register;

	 /* Combinatorial logic for state(t+1) */
    always @ (state,
              rx_bit_ctr,
              tx_bit_ctr,
              flag_rw,
              flag_start_det,
              flag_stop_det,
              rx_byte,
              out_sda_oe) 
    begin: next_state_logic
        /* Set a default state to avoid latches creation */
        next_state = state;

        if (flag_stop_det)
        begin
            next_state = STATE_IDLE;
        end
        else
        begin
            case (state)
                STATE_IDLE, STATE_WAIT_RESTART:
                begin
                    if (flag_start_det)
                    begin
                        next_state = STATE_WAIT_I2C_ADDR;
                    end
                end

                STATE_WAIT_I2C_ADDR:
                begin
                    if (rx_bit_ctr >= 8)
                    begin
                        next_state = ((rx_byte >> 1) == 'h50) ? STATE_TX_ACK : STATE_IDLE;
                        flag_rw    = (rx_byte & 'b1); 
                    end
                end

                STATE_TX_ACK:
                begin
                    if (tx_bit_ctr == 0)
                    begin
                        if (flag_rw)
                        begin
                            next_state = STATE_TX_DATA;
                        end
                        else if (flag_oe == 0 && out_sda_oe == 0) 
                        begin
                            // We have to delay transition to next state at the end of ack
                            // bit transmission, i.e. falling edge of SCL after ACK BIT, where
                            // OE is disabled.
                            next_state = STATE_WAIT_DATA_BYTE;
                        end
                    end
                end
               
                STATE_WAIT_DATA_BYTE:
                begin
                    if (rx_bit_ctr >= 8)
                    begin
                        next_state    = STATE_TX_ACK;
                    end
                end

                STATE_TX_DATA:
                begin
                    if (tx_bit_ctr == 0 && !out_sda_oe)
                    begin
                        next_state = STATE_WAIT_ACK;
                    end
                end

                STATE_WAIT_ACK:
                begin
                    if (rx_bit_ctr >= 1)
                    begin
                        next_state = (rx_byte == 0) ? STATE_TX_DATA : STATE_IDLE;
                    end
                end
            endcase
        end
    end


    always @ (posedge in_clk, negedge in_rst_n)
    begin: state_advancement_logic

        if (!in_rst_n)
        begin
            addr_register  <= 0;
            out_sda_oe     <= 0;
            out_sda        <= 1;
            rx_bit_ctr     <= 0;
            tx_bit_ctr     <= 0;
            state          <= STATE_IDLE;
            next_state     <= STATE_IDLE;
            rx_byte        <= 0;
            rx_byte_upctr  <= 0;
            flag_start_det <= 0;
            flag_stop_det  <= 0;
            flag_oe        <= 0;
            dly_upctr      <= 0;
        end
        else
        begin
            // Reset start/stop flags
            if (flag_start_det)  flag_start_det <= 0;
            if (flag_stop_det)   flag_stop_det  <= 0;
           
            // NOTE: can set output enabled only when SDA is not being pulled by master!
            if (flag_oe && in_sda)
            begin
                dly_upctr <= 1;
                flag_oe  <= 0;
            end

            // SDA delayed setup time.
            if (dly_upctr > 0)
            begin
                dly_upctr <= dly_upctr + 1;

                if (dly_upctr >= SDA_SETUP_DELAY_CYCLES)
                begin
                    out_sda_oe  <= 1;
                    dly_upctr   <= 0;
                    flag_oe     <= 0;
                end
            end

            state <= next_state;

            // On state change
            if (state != next_state)
            begin
                case (next_state)
                    
                    STATE_TX_ACK:
                    begin
                        tx_bit_ctr <= 1;
                        tx_byte    <= 0;
                       
                        if (state == STATE_WAIT_I2C_ADDR && (flag_rw == 0))
                        begin
                            // Not optimal, should not reset the register content in case master does not write...
                            rx_byte_upctr <= 0;
                            addr_register <= 0;
                        end
                        if (state == STATE_WAIT_DATA_BYTE)
                        begin
                            rx_byte_upctr <= rx_byte_upctr + 1;

                            case (rx_byte_upctr)
                                0:
                                    addr_register[15 : 8] <= rx_byte;
                                1:
                                    addr_register[7 : 0]  <= rx_byte;
                            endcase
                        end
                    end
                    
                    STATE_WAIT_I2C_ADDR, STATE_WAIT_ACK, STATE_WAIT_DATA_BYTE:
                    begin
                        rx_byte    <= 0;
                        rx_bit_ctr <= 0;
                    end

                    STATE_TX_DATA:
                    begin
                        tx_byte       <= in_mem_data;
                        addr_register <= addr_register + 1;
                        tx_bit_ctr    <= 8;
                    end

                endcase
            end
        end
    end
    
    // Start detection
    always @ (negedge in_sda)
    begin
        if (in_scl === 1)
        begin
            flag_start_det <= 1;
        end
    end

    // Stop detection
    always @ (posedge in_sda)
    begin
        if (in_scl === 1)
        begin
            flag_stop_det <= 1;
        end
    end

    // Reception
    always @ (posedge in_scl)
    begin
        case (state)
            STATE_WAIT_I2C_ADDR, STATE_WAIT_DATA_BYTE, STATE_WAIT_ACK:
            begin
                rx_byte    <= (rx_byte << 1) | in_sda;
                rx_bit_ctr <= rx_bit_ctr + 1;
            end

        endcase
    end

    // Transmission
    always @ (negedge in_scl)
    begin
        if (tx_bit_ctr > 0)
        begin
            out_sda     <= (tx_byte >> (tx_bit_ctr - 1));
            tx_bit_ctr  <= tx_bit_ctr - 1;
            // Output Enable will be set with a delay, manged by flag_oe.
            if (out_sda_oe == 0)  flag_oe <= 1;
        end
        else
        begin
            out_sda_oe <= 0;
        end
    end
endmodule

