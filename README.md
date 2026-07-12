# AXI-4-LiteAXI4-Lite Memory-Mapped Register Interface
=======
# AXI-4-Lite
AXI4-Lite Memory-Mapped Register Interface
>>>>>>> b2d9d1e (Add README file)

A fully compliant AXI4-Lite Slave Interface designed and implemented in SystemVerilog for AMD/Xilinx Vivado-based SoC designs. This project demonstrates a robust, byte-addressable hardware register bank that integrates seamlessly with modern master devices (such as RISC-V or ARM Cortex processors).

📌 Project Overview

This project implements a standard AXI4-Lite Slave peripheral featuring a 4-register bank (32-bit data width) controlled via a 4-bit address bus. It handles the complete transactional handshaking protocols of the AMBA AXI4-Lite specification, serving as a reliable template for custom hardware accelerators or Control and Status Register (CSR) interfaces.

🛠️ Key Features

AMBA AXI4-Lite Compliant: Fully implements the standard 5-channel split-bus architecture:

Write Address Channel (AW)

Write Data Channel (W)

Write Response Channel (B)

Read Address Channel (AR)

Read Data Channel (R)

Byte-Addressable Register Map: Uses a 4-bit wide address bus to target four discrete 32-bit alignment offsets:

0x0 (Register 0)

0x4 (Register 1)

0x8 (Register 2)

0xC (Register 3)

Robust Handshaking Logic: Correctly aligns VALID and READY signals to guarantee zero data loss on rising clock edges.

Asynchronous Active-Low Reset: Safe, industry-standard initializations using asynchronous rst_n assertion.

Vivado Interface Integration: Built with standardized naming conventions (s_axi_ prefixes) for automated IP packaging and integration in Vivado IP Integrator.

📁 Repository Structure

├── rtl/
│   ├── axi_lite_slave.sv   # Core AXI4-Lite Slave module containing register logic
│   └── axi_lite_top.sv     # Top-level system wrapper
└── sim/
    └── tb_axi_lite_top.sv  # Self-checking testbench


📐 Signal Handshake Architecture

<<<<<<< HEAD
Data transfers on each channel occur exclusively when both the transmitter's VALID and the receiver's READY signals are active on a rising clock edge.
=======
Data transfers on each channel occur exclusively when both the transmitter's VALID and the receiver's READY signals are active on a rising clock edge:


>>>>>>> b2d9d1e (Add README file)
