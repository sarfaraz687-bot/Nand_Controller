	Nand Flash Controller (ONFI Compliant)

Here we have two projects:

Project 1:

Based on the VHDL sources from OpenCores NAND Controller.

https://opencores.org/projects/nand_controller

The VHDL sources are ported, and only the test bench is customized according to the target device.

This project serves as a reference model.

Project 2:

A new design with both the controller source code and test bench written in VHDL.
Verification:

Verification is conducted using the Flash model from GitHub.

https://github.com/cjhonlyone/NandFlashController

Device Interface:

Tested device: MT29F64G08AECABH1 (mode 0, 1K Bytes per Page)

Interface: Asynchronous

Simulation Model: RTL

Building IP and Simulation:

Tool: Vivado 2023.1

The project is successfully built, simulated, and synthesized using Vivado 2023.1.




