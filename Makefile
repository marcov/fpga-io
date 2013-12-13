######################################################################
.PHONY: clean


#Extension conversion rule
OBJ_EXT=vvp
OBJS = $(SRCS:%.v=%.$(OBJ_EXT))

SRCS_ALL = \
	top.v \
	top_test.v \
	ft245a_usb_if.v \
	ft2232h_emulator.v \
	ram_dualport.v \
	led_ctrl.v \
	rom_lut.v \
	io_synchronizer.v \
	protocol_3w.v \
	threewire.v \
	threewire_slave_emulator.v \
	clockgen_test.v

IVERILOG_DEFINES=-D__IVERILOG__ -DTHREEWIRE_FOR_FM

######################################################################

#Generates a vvp file from the passed target name (source code name without .v)
%:
	iverilog $(IVERILOG_DEFINES) -o $*.vvp $*.v $*_test.v
	vvp $*.vvp -lxt2

all: $(SRCS_ALL)
	iverilog  $(IVERILOG_DEFINES) -o top_simulation.vvp $(SRCS_ALL)
	vvp top_simulation.vvp -lxt2

sim:
	gtkwave test.lxt

clean:
	rm *.vvp *.lxt


