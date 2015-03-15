######################################################################

THREEWIRE_MODE ?= basic

######################################################################

#Extension conversion rule
OBJ_EXT=vvp
OBJS = $(SRCS:%.v=%.$(OBJ_EXT))
SRC_SUBDIR = src
SIM_SUBDIR = sim
THREEWIRE_BASIC_SUBDIR = threewire_basic
THREEWIRE_BURST_SUBDIR = threewire_burst

CURR_DIR = $(shell pwd)


ifeq ($(THREEWIRE_MODE),basic)
    $(info Compiling for threemode mode basic)
    THREEWIRE_SUBDIR = $(THREEWIRE_BASIC_SUBDIR)
else
    $(info Compiling for threemode mode burst)
    THREEWIRE_SUBDIR = $(THREEWIRE_BURST_SUBDIR)
endif

$#####################################################################

SRC_CORE = \
	$(SRC_SUBDIR)/ft245a_usb_if.v \
	$(SRC_SUBDIR)/ram_singleport.v \
	$(SRC_SUBDIR)/ram_dualport.v \
	$(SRC_SUBDIR)/led_ctrl.v \
	$(SRC_SUBDIR)/rom_lut.v \
	$(SRC_SUBDIR)/io_synchronizer.v \

SRC_MODEL = \
	$(SRC_SUBDIR)/$(SIM_SUBDIR)/ft2232h_emulator.v \

SRC_TEST = \
	$(SRC_SUBDIR)/$(SIM_SUBDIR)/clockgen_test.v

######################################################################

SRC_THREEWIRE = \
	$(SRC_SUBDIR)/$(THREEWIRE_SUBDIR)/threewire.v  \
	$(SRC_SUBDIR)/$(THREEWIRE_SUBDIR)/protocol_3w.v \
	$(SRC_SUBDIR)/$(THREEWIRE_SUBDIR)/top.v \
	$(SRC_SUBDIR)/$(THREEWIRE_SUBDIR)/project_config.v \
	
SRC_THREEWIRE_MODEL = \
	$(SRC_SUBDIR)/$(THREEWIRE_SUBDIR)/$(SIM_SUBDIR)/threewire_slave_emulator.v 

SRC_THREEWIRE_TEST = \
	$(SRC_SUBDIR)/$(THREEWIRE_SUBDIR)/$(SIM_SUBDIR)/top_test.v \

$#####################################################################

SRC_ALL = \
		  $(SRC_CORE) \
          $(SRC_MODEL) \
		  $(SRC_THREEWIRE) \
		  $(SRC_THREEWIRE_MODEL) \
		  $(SRC_THREEWIRE_TEST) \
		  $(SRC_TEST)  \

$#####################################################################

IVERILOG_DEFINES=-D__IVERILOG__ \
				 -DTHREEWIRE_FOR_NFC \
				 -DBUILD_FOR_SIMULATION \
                 -DSIMULATION_SEED_INITIAL=$(shell echo $$RANDOM) \
				 #-DSIM_RUN_ALL_ADDR_DATA_BITS

IVERILOG_DEFINES += \
                 -I $(CURR_DIR)/$(SRC_SUBDIR) \
                 -I $(CURR_DIR)/$(SRC_SUBDIR)/$(THREEWIRE_SUBDIR)

######################################################################

#Generates a vvp file from the passed target name (source code name without .v)
%:
	iverilog $(IVERILOG_DEFINES) -o $*.vvp $*.v $*_test.v $(SRC_TO_ADD)
	vvp $*.vvp -lxt2

all: $(SRC_COMMON) $(SRC_THREEWIRE)
	iverilog  $(IVERILOG_DEFINES) -o top_simulation.vvp $(SRC_ALL)
	vvp top_simulation.vvp -lxt2

sim:
	gtkwave test.lxt

.PHONY: clean
clean:
	rm -f *.vvp *.lxt


