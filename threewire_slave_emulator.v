`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////////
//
//

module tw_slave #( parameter TWS_ADDRESS_BITS = 10,
                   parameter TWS_DATA_BITS = 32)

               (tw_bus_clock,
                tw_bus_chipselect,
                tw_bus_data,
                address,
                wr_data,
                rd_data,
                mode_wr);
    
    `include "builtins_redefined.v"
    
    input tw_bus_clock;
    input tw_bus_chipselect;
    inout tw_bus_data;
    output reg mode_wr; //from master point of view
    output reg [TWS_ADDRESS_BITS - 1 : 0] address;
    output reg [TWS_DATA_BITS - 1 : 0] wr_data;
    input  [TWS_DATA_BITS - 1 : 0] rd_data;
   
    localparam TWS_BIT_CTR_MAX_BITS = `_max(TWS_ADDRESS_BITS, TWS_DATA_BITS);
    localparam _TWS_BIT_CTR_MAX_WIDTH = `_clog2(TWS_BIT_CTR_MAX_BITS);
    reg [_TWS_BIT_CTR_MAX_WIDTH - 1 : 0] i;
    wire tw_slave_data_in;
    reg  tw_slave_data_out;
    reg  tw_slave_out_enable;
    
    
    assign tw_slave_data_in = tw_bus_data;
    assign tw_bus_data = tw_slave_out_enable ? tw_slave_data_out : 8'bz;
     
    always
    begin : slave_emulator
        
        // STARTS HERE
        tw_slave_out_enable = 0;
        tw_slave_data_out   = 0;
        
        wait (tw_bus_chipselect == 0)
        
        @(posedge tw_bus_clock) mode_wr = tw_slave_data_in;
            
        for (i = 0; i < TWS_ADDRESS_BITS; i = i + 1)
        begin
            @(posedge tw_bus_clock) address[TWS_ADDRESS_BITS - 1 - i] = tw_slave_data_in; 
        end

        if (mode_wr)
        begin
            // Master is writing some data. 
            for (i = 0; tw_bus_chipselect == 0; i = i + 1)
            begin
                if (i >= TWS_DATA_BITS)
                    i = 0;
                @(posedge tw_bus_clock) wr_data[TWS_DATA_BITS - 1 - i] = tw_slave_data_in; 
            end
        end
        else
        begin
            // Master is reading some data.
            for (i = 0; tw_bus_chipselect == 0; i = i + 1)
            begin
                if (i >= TWS_DATA_BITS)
                    i = 0;
                @(posedge tw_bus_clock)  tw_slave_data_out =  rd_data[TWS_DATA_BITS - 1 - i];
                if (i == 0)
                    tw_slave_out_enable = 1;
            end
            
            tw_slave_out_enable = 0;
        end

        wait (tw_bus_chipselect == 1) 
            // fake instruction
            i = i;
    end
endmodule
