######################################################################

MODULE_NAME ?= threewire_basic

######################################################################

#Extension conversion rule
OBJ_EXT=vvp
OBJS = $(SRCS:%.v=%.$(OBJ_EXT))
SRC_SUBDIR = src
SIM_SUBDIR = sim

MODULES_LIST = threewire_basic threewire_burst io_bitbang

CURR_DIR = $(shell pwd)

ifeq ($(filter $(MODULES_LIST),$(MODULE_NAME)),)
    $(error Unsupported MODULE_NAME='$(MODULE_NAME)'. Available modules: '$(MODULES_LIST)')
endif

include $(SRC_SUBDIR)/$(MODULE_NAME)/Makefile.inc

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

SRC_ALL = \
		  $(SRC_CORE) \
          $(SRC_MODEL) \
		  $(SRC_TEST)  \

######################################################################
$(info "SRC MODULE is $(SRC_MODULE)")
$(info "SRC MODULE MODEL is $(SRC_MODULE_MODEL)")
$(info "SRC MODULE TEST is $(SRC_MODULE_TEST)")

$(foreach SRC_FILE,$(SRC_MODULE),SRC_ALL += $(SRC_SUBDIR)/$(MODULE_NAME)/$(SRC_FILE))
$(foreach SRC_FILE,$(SRC_MODULE_MODEL),SRC_ALL += $(SRC_SUBDIR)/$(MODULE_NAME)/sim/$(SRC_FILE))
$(foreach SRC_FILE,$(SRC_MODULE_TEST),SRC_ALL += $(SRC_SUBDIR)/$(MODULE_NAME)/sim/$(SRC_FILE))

######################################################################

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

help:
	@echo "Build verilog module + run simulation"
	@echo "Usage make MODULE=<module-name>"
	@echo "Current supported modules:"
	@echo "-threewire_basic"
	@echo "-threewire_burst"
	@echo "-io_bitbang"


.PHONY: clean
clean:
	rm -f *.vvp *.lxt


