/** Module for io bitbanging */

module io_pad(input wire  in_dir,
              input wire  in_outval,
              inout wire  pin);
    assign pin = in_dir ? in_outval : 'bz;
endmodule


module io_bitbang #(parameter IO_NUM_OF = 10)
                  (// i.f. to the controller interface
                   input  wire [IO_NUM_OF - 1 : 0] in_io_direction,
                   input  wire [IO_NUM_OF - 1 : 0] in_io_outval,
                   // i.f. to the IO pad
                   inout  wire [IO_NUM_OF - 1 : 0] io_pins);

    io_pad io_pads_set[IO_NUM_OF - 1 : 0] (in_io_direction, in_io_outval, io_pins);

endmodule
