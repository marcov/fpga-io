CC=gcc
#CFLAGS=-Wall -Wextra -L. -lftd2xx  -Wl,-rpath /usr/local/lib
CFLAGS=-Wall -Wextra -L. -lftd2xx.1.2.2  -Wl,-rpath /usr/local/lib
#CFLAGS=-Wall -Wextra -L. -L/opt/local/lib -lftd2xx -framework CoreFoundation  -framework IOKit -lobjc

THREEWIRE_APP = fpga_3w_eval 
IO_BB_APP     = fpga_io_bb_eval 

all: $(THREEWIRE_APP) $(IO_BB_APP)

$(THREEWIRE_APP): main_3w.c fm_regs_reset.c
	$(CC) main_3w.c fm_regs_reset.c fpga_3w_api.c fpga_common_api.c -o $(THREEWIRE_APP) $(CFLAGS) -O3 -g
	
$(IO_BB_APP): main_io_bb.c 
	$(CC) main_io_bb.c fpga_common_api.c fpga_io_bb_api.c -o $(IO_BB_APP) $(CFLAGS) -O3 -g


clean:
	rm -f *.o
	rm -f $(THREEWIRE_APP) $(IO_BB_APP) 
