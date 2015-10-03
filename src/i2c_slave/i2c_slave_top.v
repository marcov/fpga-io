
`define ROM_MEMORY_ADDR_WIDTH 	16
`define ROM_MEMORY_DATA_WIDTH 	8

module i2c_slave_top
  #(parameter TOP_ROM_MEM_ADDR_WIDTH = `ROM_MEMORY_ADDR_WIDTH,
    parameter TOP_ROM_MEM_DATA_WIDTH = `ROM_MEMORY_DATA_WIDTH)
   (input in_ext_osc,
    input in_reset_n,
    input in_scl,
    inout io_sda);

	wire slave_sda_oe;
	wire [TOP_ROM_MEM_ADDR_WIDTH - 1 : 0] rom_addr;
	wire [TOP_ROM_MEM_DATA_WIDTH - 1 : 0] rom_data;

   i2c_slave #(.MEM_ADDR_WIDTH(TOP_ROM_MEM_ADDR_WIDTH),
               .MEM_DATA_WIDTH(TOP_ROM_MEM_DATA_WIDTH))
        i2c_slave_inst (.in_clk(in_ext_osc),
                        .in_rst_n(in_reset_n),
                        .in_scl(in_scl),
                        .io_sda(io_sda),
                        .out_sda_dir(slave_sda_oe),
                        .out_mem_addr(rom_addr),
                        .in_mem_data(rom_data));


    rom_lookup_table #(.ROM_ADDR_WIDTH(TOP_ROM_MEM_ADDR_WIDTH),
                       .ROM_DATA_WIDTH(TOP_ROM_MEM_DATA_WIDTH)) 
		rom_mem_inst (.in_clk(in_ext_osc),
 				 	  .in_addr(rom_addr),
 				 	  .out_data(rom_data));

endmodule





