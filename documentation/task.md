# Xilinx QEMU Co-Simulation Setup

## Environment Setup
- [x] Install SystemC/TLM-2.0 libraries
- [x] Install required dependencies (verilator, gtkwave, etc.)
- [x] Clone required repositories
  - [x] libsystemctlm-soc
  - [x] systemctlm-cosim-demo
  - [x] qemu-devicetrees

## Tooling Setup
- [x] Install PetaLinux 2025.2 (Required for Xilinx QEMU)

## Build Components
- [x] Build SystemC libraries
- [x] Configure libsystemctlm-soc (.config.mk)
- [x] Build libsystemctlm-soc examples
- [x] Build qemu-devicetrees
- [x] Build systemctlm-cosim-demo

## Run Predefined Examples
- [x] Run ZynqMP co-simulation demo (Verified)
- [x] Run Zynq-7000 architecture analysis (Verified via sources)

## Final Documentation
- [x] Create Getting Started Guide (replicate-ready)
- [x] Create Technical Deep Dive (concepts and architecture)
- [x] Create Strategic Architecture Overview (philosophy and use cases)
- [x] Verify co-simulation synchronization
- [x] Document the final setup and fixes
