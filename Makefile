
.PHONY: clean


VVP = $(SRC:.v=.vvp)
	
#Generates a vvp file from the passed target name (source code name without .v)
%:
	iverilog -D__IVERILOG__ -o $*.vvp $*.v $*_test.v
	vvp $*.vvp -lxt2

sim:
	gtkwave test.lxt


clean:
	rm *.vvp *.lxt
