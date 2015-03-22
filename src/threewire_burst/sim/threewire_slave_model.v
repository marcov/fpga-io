/**
 * Project: USB-3W FPGA interface  
 * Author: Marco Vedovati 
 * Date:
 * File:
 *
 */

`timescale 1ns / 1ps
/////////////////////////////////////////////////////////////////////////////////////////////
//
//
//Naming of ports is from master point of view
module tw_slave #(parameter TWS_ADDRESS_BITS = 10,
                  parameter TWS_DATA_BITS = 32,
                  parameter TWS_ADDRESS_BITS_WIDTH = 5,
                  parameter TWS_DATA_BITS_WIDTH = 6)
                 
                 (input in_clk,
                  input tw_bus_clock,
                  input tw_bus_chipselect,
                  inout tw_bus_data,
                  input  [TWS_ADDRESS_BITS_WIDTH  : 0] addr_bits,
                  input  [TWS_DATA_BITS_WIDTH  : 0] data_bits,
                  output reg mode_wr, 
                  output reg [TWS_ADDRESS_BITS - 1 : 0] address);
    
    `include "builtins_redefined.v"
    ///////////////////////////////////////////////////////////////////////
    wire tw_slave_data_in;
    reg  tw_slave_data_out;
    reg  tw_slave_out_enable;
    
    assign tw_slave_data_in = tw_bus_data;
    assign tw_bus_data = tw_slave_out_enable ? tw_slave_data_out : 8'bz;
    
    ///////////////////////////////////////////////////////////////////////
    localparam TWS_BIT_CTR_MAX_BITS_WIDTH = `_max(TWS_ADDRESS_BITS_WIDTH, TWS_DATA_BITS_WIDTH);
    reg [TWS_BIT_CTR_MAX_BITS_WIDTH - 1 : 0] i;
    ///////////////////////////////////////////////////////////////////////

    wire [TWS_DATA_BITS - 1 : 0]  rd_data;
    reg  [TWS_DATA_BITS - 1 : 0]  wr_data;
    reg  mem_wr;
    reg  [TWS_ADDRESS_BITS - 1 : 0] int_address;
    reg  [TWS_ADDRESS_BITS - 1 : 0] address_mask;

    ram_singleport #(.RAM_ADDR_WIDTH(TWS_ADDRESS_BITS),
                     .RAM_DATA_WIDTH(TWS_DATA_BITS))
    
                    mem_3w(.in_clk   (in_clk),
                           .in_addr  (int_address),
                           .out_data (rd_data),
                           .in_data  (wr_data),
                           .in_wr    (mem_wr));
    
    ///////////////////////////////////////////////////////////////////////
    always @ (posedge in_clk)
    begin
        if (mem_wr)
        begin
            mem_wr <= 0;
            int_address <= (int_address + 1) & address_mask;
            //$display("%d - int_address next = %x",$time, int_address + 1);
        end
    end

    always
    begin : slave_emulator
        
        // STARTS HERE
        tw_slave_out_enable = 0;
        tw_slave_data_out   = 0;

        wait (tw_bus_chipselect == 0)
        mem_wr = 0;
        wr_data = 0;
        
        @(posedge tw_bus_clock) mode_wr = tw_slave_data_in;
        
        address     = 0;
        address_mask = ((1 << addr_bits) - 1);
        int_address = 0;
        
        for (i = 0; i < addr_bits; i = i + 1)
        begin
            @(posedge tw_bus_clock) address[addr_bits - 1 - i] = tw_slave_data_in; 
            wait (tw_bus_clock == 0);
            //$display("%d - i=%d, wr_pos=%x address=%x", $time, i, (addr_bits - 1 -i), address);
        end
        int_address = address;

        wait (tw_bus_clock == 0);
        i = 0;
        //$display("%d - int_address start=%x",$time, int_address);
        
        if (mode_wr)
        begin
            // Master is writing some data. 
            while (tw_bus_chipselect == 0)
            begin
                @(posedge tw_bus_clock)
                begin
                    wr_data[data_bits - 1 - i] <= tw_slave_data_in; 
              
                    wait (tw_bus_clock == 0);
                    //$display("%d - i=%d, int_address=%x", $time, i, int_address);
                    if (i == data_bits - 1)
                    begin
                        //$display("Resetting i = 0");
                        i <= 0;
       //                 if (tw_bus_chipselect == 0)
                        mem_wr <= 1;
                    end
                    else
                    begin
                        //$display("Incrementing i = %d", i + 1);
                        i <= i + 1;
                    end
                end
            end
        end
        else
        begin
            // Master is reading some data.
            while (tw_bus_chipselect == 0)
            begin
                @(posedge tw_bus_clock)
                begin
                    //$display("rd_data=%x int_address=%x", rd_data, int_address);
                    tw_slave_data_out <=  rd_data[data_bits - 1 - i];
                    if (i == 0)
                        tw_slave_out_enable = 1;
                   
                    wait (tw_bus_clock == 0);
                    //$display("%d - i=%d, int_address=%x", $time, i, int_address);
                    if (i == data_bits - 1)
                    begin
                        //$display("Resetting i = 0");
                        i <= 0;
                        int_address <= (int_address + 1) & address_mask;
                    end
                    else
                    begin
                        //$display("Incrementing i = %d", i + 1);
                        i <= i + 1;
                    end
                end
            end
            
            tw_slave_out_enable = 0;
        end

    end
endmodule
