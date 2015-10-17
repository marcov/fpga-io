
`define ROM_MEMORY_ADDR_WIDTH 	   16

`ifdef __IVERILOG__
`define ROM_MEMORY_INIT_FILE_PATH  "mem_init_vlog.mif"
`else
`define ROM_MEMORY_INIT_FILE_PATH  "C:/mem_init_vlog.mif"
`endif

`define ROM_MEMORY_DATA_WIDTH 	   8
`define I2C_SLAVE_SDA_DELAY_CYCLES 3


module i2c_slave_top
  #(parameter TOP_ROM_MEM_ADDR_WIDTH = `ROM_MEMORY_ADDR_WIDTH,
    parameter TOP_ROM_MEM_DATA_WIDTH = `ROM_MEMORY_DATA_WIDTH,
    parameter TOP_ROM_MEM_INIT_FILE  = `ROM_MEMORY_INIT_FILE_PATH,
    parameter TOP_SDA_SETUP_DELAY_CYCLES = `I2C_SLAVE_SDA_DELAY_CYCLES)
   (input in_ext_osc,
    input in_reset_n,
    input in_i2c_scl,
    inout io_i2c_sda);

	wire slave_sda_oe;
	wire [TOP_ROM_MEM_ADDR_WIDTH - 1 : 0] rom_addr;
	wire [TOP_ROM_MEM_DATA_WIDTH - 1 : 0] rom_data;
    wire in_reset_p;

    assign in_reset_p    = !in_reset_n;
    
    i2c_slave #(.MEM_ADDR_WIDTH(TOP_ROM_MEM_ADDR_WIDTH),
                .MEM_DATA_WIDTH(TOP_ROM_MEM_DATA_WIDTH),
                .SDA_SETUP_DELAY_CYCLES(TOP_SDA_SETUP_DELAY_CYCLES))
        i2c_slave_inst (.in_clk(clk_top_main),
                        .in_rst_n(in_reset_n),
                        .in_scl(in_i2c_scl),
                        .io_sda(io_i2c_sda),
                        .out_sda_oe(slave_sda_oe),
                        .out_mem_addr(rom_addr),
                        .in_mem_data(rom_data));


    rom_lookup_table #(.ROM_ADDR_WIDTH(TOP_ROM_MEM_ADDR_WIDTH),
                       .ROM_DATA_WIDTH(TOP_ROM_MEM_DATA_WIDTH),
                       .MEM_INIT_FILE_PATH(TOP_ROM_MEM_INIT_FILE)) 
		rom_mem_inst (.in_clk(clk_top_main),
 				 	  .in_addr(rom_addr),
 				 	  .out_data(rom_data));

    // Instantiation of clockgen
    clockgen clkgen (
        .CLKIN_IN        (in_ext_osc), 
        .RST_IN          (in_reset_p), 
        .CLK0_OUT        (clk_top_main) 
        );

endmodule





