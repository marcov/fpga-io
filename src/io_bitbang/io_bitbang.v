/** Module for io bitbanging */

module io_single(input wire  in_dir,
                 input wire  in_outval,
                 inout wire  pin);

    assign pin = in_dir ? in_outval : 'bz;
endmodule


module io_bitbang #(parameter IO_NUM_OF = 10)
                  (// Towards the controller interface
                   input  wire [IO_NUM_OF - 1 : 0] in_io_direction,
                   input  wire [IO_NUM_OF - 1 : 0] in_io_outval,
                   output wire [IO_NUM_OF - 1 : 0] out_io_inputval,
                   // Torwards the HW pins
                   inout  wire [IO_NUM_OF - 1 : 0] io_pins);

    //assign io_pins = in_io_direction ? in_io_outval : 'bz;
    

    io_single io_multi[IO_NUM_OF - 1 : 0] (in_io_direction, in_io_outval, io_pins);

    assign out_io_inputval = io_pins;


endmodule
