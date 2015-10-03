


MODULE_NAME := i2c_slave

SRCS := $(MODULE_NAME).v $(MODULE_NAME)_tb.v

OBJS :=  $(MODULE_NAME)_tb.vvp

WAVEFILE := $(OBJS:.vvp=.lxt)

$(info $(WAVEFILE) -- $(OBJS) -- $(SRCS))


.PHONY: wave
wave:	all
	gtkwave $(WAVEFILE)

.PHONY: all
all: $(OBJS)

.SECONDEXPANSION:
$(OBJS):
	@echo "Making..."
	iverilog -o $@ $(SRCS)
	vvp $@ -lxt2
	@echo "OK"


.PHONY: clean
clean:
	@echo "Cleaning..."
	@rm -f *.vvp *.lxt
	@echo "OK" 