module led_ctrl(input  in_clk,
                input  in_rst,
                output out_led);
    
    `include "builtins_redefined.v"

    localparam ROM_LUT_DATA_WIDTH = 8;
    localparam ROM_LUT_ADDR_WIDTH = 8;
    // led_ctrl generates a periodic patter with period 2.
    // Given the clock freq at 66.666MHz, I have to count to 133 333 333
    localparam IN_CLK_FREQ = 66666666;
    localparam PERIOD_S    = 2;
    localparam CLKDIV_WIDTH = _clog2((IN_CLK_FREQ * PERIOD_S) / (1<<ROM_LUT_ADDR_WIDTH));

    reg [CLKDIV_WIDTH - 1 : 0] clkdiv_ctr;
    wire pwm_clk;
    assign pwm_clk = clkdiv_ctr[CLKDIV_WIDTH - 8 - 1 - 1];
    reg  [ROM_LUT_ADDR_WIDTH - 1 : 0] lut_addr;
    wire [ROM_LUT_DATA_WIDTH - 1 : 0] lut_data;
    
    rom_lookup_table rom_lut (.in_clk(in_clk),
                              .in_addr(lut_addr),
                              .out_data(lut_data));


    pwm_generator #(.PWM_VALUE_WIDTH(ROM_LUT_DATA_WIDTH))
                  pwmgen (.in_clk_pwm(pwm_clk),
                          .in_rst(in_rst),
                          .pwm_val(lut_data),
                          .out_pwm(out_led));
                      
    always @ (posedge in_clk, posedge in_rst)
    begin
        if (in_rst)
        begin
            clkdiv_ctr <= 0;
            lut_addr   <= 0;
        end
        else
        begin
            clkdiv_ctr <= clkdiv_ctr + 1;

            if (clkdiv_ctr == ((1 << CLKDIV_WIDTH - 1) - 1))
            begin
                /* It's time to change the output */
                lut_addr <= lut_addr + 1;
            end
        end
    end
endmodule


module pwm_generator #(parameter PWM_VALUE_WIDTH = 8)
                      (input  in_clk_pwm,
                       input  in_rst,
                       input  [PWM_VALUE_WIDTH - 1 : 0] pwm_val,
                       output reg out_pwm);
   
    reg [PWM_VALUE_WIDTH - 1 : 0] pwm_ctr;
    localparam PWM_VALUE_TOP = ('b1 << PWM_VALUE_WIDTH) - 1;

    always @ (posedge in_clk_pwm, posedge in_rst)
    begin
        if (in_rst)
        begin
            pwm_ctr <= PWM_VALUE_TOP;
        end
        else
        begin
            pwm_ctr <= pwm_ctr - 1;
            
            case (pwm_val)
                'h00:
                begin
                    out_pwm <= 0;
                end

                PWM_VALUE_TOP:
                begin
                    out_pwm <= 1;
                end

                default:
                begin
                    out_pwm <= (pwm_val > pwm_ctr) ? 1 : 0;
                end
            endcase
        end
    end
endmodule
