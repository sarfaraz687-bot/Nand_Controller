	Nand Flash Controller (ONFI Compliant)

Here we have two projects:

•	The Project1 is based on the VHDL sources from https://opencores.org/projects/nand_controller , which is ported to VHDL. In this project only test bench is customized according to the target device. This project is used as a reference model.

•	The project2 is based on new design having both controller source code and test bench written in VHDL. 

Verification:

•	Verification is done with Flash model from https://github.com/cjhonlyone/NandFlashController/tree/master/tb/m73a_nand_model

	Device Interface:

•	Tested device: MT29F64G08AECABH1 (mode 0, 1K Bytes per Page)

•	Interface is Asynchronous 

•	Simulation Model: RTL

	Building IP and simulation:

•	Vivado 2023.1 is used for successful build, simulation and synthesis.




