######################################################################

MODULE_NAME ?= threewire_basic
$(info Building for module: $(MODULE_NAME))

######################################################################

#Extension conversion rule
OBJ_EXT=vvp
OBJS = $(SRCS:%.v=%.$(OBJ_EXT))
SRC_SUBDIR = src
SIM_SUBDIR = sim

MODULES_LIST = threewire_basic threewire_burst io_bitbang i2c_slave

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

SRC_CORE_MODEL = \
  $(SRC_SUBDIR)/$(SIM_SUBDIR)/ft2232h_model.v \
  $(SRC_SUBDIR)/$(SIM_SUBDIR)/clockgen_model.v

######################################################################

SRC_ALL = \
  $(SRC_CORE) \
  $(SRC_CORE_MODEL)

######################################################################
$(info SRC MODULE:       "$(SRC_MODULE)")
$(info SRC MODULE MODEL: "$(SRC_MODULE_MODEL)")
$(info SRC MODULE TEST:  "$(SRC_MODULE_TEST)")

#dirs := a b c d
#files := $(foreach dir,$(dirs),foobar/$(dir))
#$(info "file is $(files)")

SRC_AUTO :=
SRC_AUTO += $(foreach src_file,$(SRC_MODULE),$(SRC_SUBDIR)/$(MODULE_NAME)/$(src_file))
SRC_AUTO += $(foreach src_file,$(SRC_MODULE_MODEL),$(SRC_SUBDIR)/$(MODULE_NAME)/sim/$(src_file))
SRC_AUTO += $(foreach src_file,$(SRC_MODULE_TEST),$(SRC_SUBDIR)/$(MODULE_NAME)/sim/$(src_file))

SRC_ALL += $(SRC_AUTO)

#$(info src auto: "$(SRC_AUTO)")
#$(info src ALL: "$(SRC_ALL)")
######################################################################

IVERILOG_DEFINES=-D__IVERILOG__ \
  -DTHREEWIRE_FOR_NFC \
  -DBUILD_FOR_SIMULATION \
  -DSIMULATION_SEED_INITIAL=$(shell echo $$RANDOM) \
  #-DSIM_RUN_ALL_ADDR_DATA_BITS

IVERILOG_DEFINES += \
  -I $(CURR_DIR)/$(SRC_SUBDIR) \
  -I $(CURR_DIR)/$(SRC_SUBDIR)/$(MODULE_NAME)

######################################################################

#Generates a vvp file from the passed target name (source code name without .v)
%:
	iverilog $(IVERILOG_DEFINES) -o $*.vvp src/$(MODULE_NAME)/$*.v src/$(MODULE_NAME)/$*_test.v
	vvp $*.vvp -lxt2

all: top_testbench.lxt # Build verilog module + run simulation. Set MODULE_NAME to the one of (threewire_basic, threewire_burst, io_bitbang, i2c_slave)

top_testbench.lxt: top_simulation.vvp
	vvp $^ -lxt2

top_simulation.vvp: $(SRC_COMMON) $(SRC_THREEWIRE)
	iverilog  $(IVERILOG_DEFINES) -o $@ $(SRC_ALL)

.PHONY: sim
sim: top_testbench.lxt # Show the simulation result in GTKWave
	gtkwave $^

.PHONY: help
help: ## this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_-]+:.*?## / {gsub("\\\\n",sprintf("\n%22c",""), $$2);printf "\033[36m%-20s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

.PHONY: clean
clean:
	rm -f *.vvp *.lxt


