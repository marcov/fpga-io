#### fpga-io

This project is about implementing in Verilog a USB to 3wire, GPIO and other.

The implementation was meant to be used with a board made by DLP Design,
the HS-FPGA2, that comes with the Xilinx Spartan 3A FPGA.

If you need to synthesize the code for the real FPGA, then you need the Xilin ISE
software.

If simulation is enough:
- Icarus verilog is used to synthesize the Verilog code,
- GTKWave is used to visualize the synthesis waves.
