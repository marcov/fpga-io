######################################################################
.PHONY: clean


#Extension conversion rule
OBJ_EXT=vvp
OBJS = $(SRCS:%.v=%.$(OBJ_EXT))
SRC_SUBDIR = src
SIM_SUBDIR = sim

SRC_CORE = \
	$(SRC_SUBDIR)/top.v \
	$(SRC_SUBDIR)/ft245a_usb_if.v \
	$(SRC_SUBDIR)/ram_singleport.v \
	$(SRC_SUBDIR)/ram_dualport.v \
	$(SRC_SUBDIR)/led_ctrl.v \
	$(SRC_SUBDIR)/rom_lut.v \
	$(SRC_SUBDIR)/io_synchronizer.v \
	$(SRC_SUBDIR)/protocol_3w.v \
	$(SRC_SUBDIR)/threewire.v 


SRC_MODEL = \
	$(SRC_SUBDIR)/$(SIM_SUBDIR)/ft2232h_emulator.v \
	$(SRC_SUBDIR)/$(SIM_SUBDIR)/threewire_slave_emulator.v 

SRC_TEST = \
	$(SRC_SUBDIR)/$(SIM_SUBDIR)/top_test.v \
	$(SRC_SUBDIR)/$(SIM_SUBDIR)/clockgen_test.v

SRC_ALL = \
		  $(SRC_CORE) \
          $(SRC_MODEL) \
		  $(SRC_TEST)

CURR_DIR = $(shell pwd)

IVERILOG_DEFINES=-D__IVERILOG__ \
				 -DTHREEWIRE_FOR_NFC \
				 -DBUILD_FOR_SIMULATION \
                 -DSIMULATION_SEED_INITIAL=$(shell echo $$RANDOM) \
				 #-DSIM_RUN_ALL_ADDR_DATA_BITS

IVERILOG_DEFINES += \
                 -I $(CURR_DIR)/$(SRC_SUBDIR)

######################################################################

#Generates a vvp file from the passed target name (source code name without .v)
%:
	iverilog $(IVERILOG_DEFINES) -o $*.vvp $*.v $*_test.v $(SRC_TO_ADD)
	vvp $*.vvp -lxt2

all: $(SRCS_ALL)
	iverilog  $(IVERILOG_DEFINES) -o top_simulation.vvp $(SRC_ALL)
	vvp top_simulation.vvp -lxt2

sim:
	gtkwave test.lxt

clean:
	rm -f *.vvp *.lxt


