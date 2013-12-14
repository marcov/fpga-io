`timescale 1ns / 1ps

module ram_dualport_testbench;

    reg sim_clk;
   
    localparam IUT_RAM_ADDR_WIDTH = 8,
               IUT_RAM_DATA_WIDTH = 8;
    
    reg [IUT_RAM_ADDR_WIDTH - 1 : 0] iut_addr_a;
    reg [IUT_RAM_ADDR_WIDTH - 1 : 0] iut_addr_b;
    wire [IUT_RAM_DATA_WIDTH - 1 : 0] iut_out_data_a;
    wire [IUT_RAM_DATA_WIDTH - 1 : 0] iut_out_data_b;
    reg [IUT_RAM_DATA_WIDTH - 1 : 0] iut_in_data_a;
    reg [IUT_RAM_DATA_WIDTH - 1 : 0] iut_in_data_b;
    reg iut_wr_a;
    reg iut_wr_b;

///////////////////////////////////////////////////////////////////
    ram_dualport #(.RAM_ADDR_WIDTH(IUT_RAM_ADDR_WIDTH),
                   .RAM_DATA_WIDTH(IUT_RAM_DATA_WIDTH))
                 ram_dp_iut (.in_clk(sim_clk),
                             .in_addr_a(iut_addr_a),
                             .in_addr_b(iut_addr_b),
                             .out_data_a(iut_out_data_a),
                             .out_data_b(iut_out_data_b),
                             .in_data_a(iut_in_data_a),
                             .in_data_b(iut_in_data_b),
                             .in_wr_a  (iut_wr_a),
                             .in_wr_b  (iut_wr_b));
///////////////////////////////////////////////////////////////////
	initial begin
		// Initialize Inputs
		#0
        $dumpfile("test.lxt");
        $dumpvars(0,ram_dualport_testbench);
		sim_clk = 0;

		#50
        Iut_WRA_RDB('hAA, 'hAA, 'h55);
        Iut_WRB_RDA('h33, 'h33, 'h44);
        Iut_WR_Sequential();

        // Wait 100 ns for global reset to finish
		#100000;
        $finish;
	end

    task Iut_WR_Sequential;
    begin
        
        iut_addr_b = 'h00;

        @ (posedge sim_clk)
        wait (sim_clk == 0);
        //Fill txbuffer with data.
        iut_in_data_b  = 'h00; 
        iut_wr_b  = 1;
        // data will be written at next positive edge.

        @ (posedge sim_clk)
        wait (sim_clk == 0);
        iut_addr_b = iut_addr_b + 1;
        //Fill txbuffer with data.
        iut_in_data_b  = 'h01; 
        // data will be written at next positive edge.

        @ (posedge sim_clk)
        wait (sim_clk == 0);
        iut_addr_b = iut_addr_b + 1;
        //Fill txbuffer with data.
        iut_in_data_b  = 'h02; 
        // data will be written at next positive edge.

        @ (posedge sim_clk)
        wait (sim_clk == 0);
        iut_addr_b = iut_addr_b + 1;
        //Fill txbuffer with data.
        iut_in_data_b  = 'h03; 
        // data will be written at next positive edge.
        
        @ (posedge sim_clk)
        wait (sim_clk == 0);
        iut_wr_b = 0;
    end
    endtask

    task Iut_WRA_RDB;
        input [IUT_RAM_ADDR_WIDTH - 1 : 0] addr_a;
        input [IUT_RAM_ADDR_WIDTH - 1 : 0] addr_b;
        input [IUT_RAM_DATA_WIDTH - 1 : 0] in_data_a;
    begin
        iut_addr_a     = addr_a;
        iut_in_data_a  = in_data_a;
        iut_wr_a       = 1;

        @ (posedge sim_clk)
         begin
            wait (sim_clk == 0);
            iut_wr_b    = 0;
            iut_addr_b  = addr_b;
            // data will be available next positive edge.
        end

        @(posedge sim_clk)
        begin
            wait (sim_clk == 0);
            if (iut_in_data_a !== iut_out_data_b)
            begin
                $display(">>>> FAILED on WR A - RD B");
                $display(">>>> ADDR: %x", iut_addr_a);
                $display(">>>> DATA A: %x - DATA B: %x", iut_in_data_a, iut_out_data_b);
                $finish;
            end
            begin
                $display("OK");
            end

            iut_wr_a = 0;
        end
        

    end 
    endtask
    
    task Iut_WRB_RDA;
        input [IUT_RAM_ADDR_WIDTH - 1 : 0] addr_a;
        input [IUT_RAM_ADDR_WIDTH - 1 : 0] addr_b;
        input [IUT_RAM_DATA_WIDTH - 1 : 0] in_data_b;
    begin
        iut_addr_b     = addr_b;
        iut_in_data_b  = in_data_b;
        iut_wr_b       = 1;

        @ (posedge sim_clk)
         begin
            wait (sim_clk == 0);
            iut_wr_a    = 0;
            iut_addr_a  = addr_a;
            // data will be available next positive edge.
        end

        @(posedge sim_clk)
        begin
            wait (sim_clk == 0);
            if (iut_in_data_b !== iut_out_data_a)
            begin
                $display(">>>> FAILED on WR B - RD A");
                $display(">>>> ADDR: %x", iut_addr_b);
                $display(">>>> DATA A: %x - DATA B: %x", iut_out_data_a, iut_in_data_b);
                $finish;
            end
            else
            begin
                $display("OK");
            end
            
            iut_wr_b = 0;
        end
    end
    endtask

    //66MHz
	always #7.5 sim_clk = !sim_clk; 
endmodule
