CC=gcc
#CFLAGS=-Wall -Wextra -L. -lftd2xx  -Wl,-rpath /usr/local/lib
CFLAGS=-Wall -Wextra -L. -lftd2xx.1.2.2  -Wl,-rpath /usr/local/lib
#CFLAGS=-Wall -Wextra -L. -L/opt/local/lib -lftd2xx -framework CoreFoundation  -framework IOKit -lobjc

THREEWIRE_APP = fpga_3w_eval 
IO_BB_APP     = fpga_io_bb_eval 
JTAG_SERVER   = jtag_server

COMMON_SRC      = fpga_common_api.c fpga_io_bb_api.c fm_regs_reset.c fpga_3w_api.c
JTAG_SERVER_SRC = $(COMMON_SRC) jtag_sever.c

ALL_APPS = $(THREEWIRE_APP) $(IO_BB_APP) $(JTAG_SERVER)

all: $(ALL_APPS)

$(THREEWIRE_APP): $(COMMON_SRC) main_3w.c
	$(CC) $^  -o $@ $(CFLAGS) -O3 -g
	
$(IO_BB_APP): $(COMMON_SRC) main_io_bb.c
	$(CC) $^  -o $@ $(CFLAGS) -O3 -g

$(JTAG_SERVER): $(COMMON_SRC) jtag_server.c
	$(CC) $^  -o $@ $(CFLAGS) -O3 -g


clean:
	rm -f *.o
	rm -f $(ALL_APPS)


