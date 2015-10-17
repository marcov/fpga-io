#
#
#


MODULE_NAME := i2c_slave

VFLAGS := -D__IVERILOG__ -DROM_MEMORY_INIT_FILE_DIR="."

OBJS_DIR := build
SIM_DIR  := sim

SRCS := $(MODULE_NAME).v \
        $(MODULE_NAME)_top.v \
        $(SIM_DIR)/$(MODULE_NAME)_top_tb.v \
        ../rom_lut.v                       \
		../sim/clockgen_model.v            \


OBJS :=  $(MODULE_NAME)_top_tb.vvp

WAVEFILE := $(OBJS:.vvp=.lxt)

$(info WAVEFILE = $(WAVEFILE))
$(info OBJS     = $(OBJS))
$(info SRCS     = $(SRCS))


.PHONY: wave
wave: all
	gtkwave $(OBJS_DIR)/$(WAVEFILE)

.PHONY: all
all: $(OBJS)

.SECONDEXPANSION:
$(OBJS): $(OBJS_DIR)
	@echo "Making..."
	iverilog $(VFLAGS) -o $(OBJS_DIR)/$@ $(SRCS) 
	vvp build/$@ -lxt2
	mv $(WAVEFILE) $(OBJS_DIR)
	@echo "OK"


.SECONDEXPANSION:
$(OBJS_DIR):
	 mkdir -p $(OBJS_DIR)
	
.PHONY: clean
clean:
	@echo "Cleaning..."
	@rm -rf $(OBJS_DIR)
	@echo "OK" 
