
module pad_monitor (input wire dir,
                    input wire outval,
                    inout wire pad);

       assign pad = dir ? outval : 'bz;       
endmodule
