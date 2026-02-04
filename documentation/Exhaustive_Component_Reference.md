# Exhaustive Component Reference: Xilinx Co-Simulation

This document provides a minute, technical breakdown of every library, package, and tool used in this co-simulation environment. It is intended for developers who need to understand the internal logic and code structure of the system.

---

## 1. SystemC 2.3.3 (The Simulation Kernel)

SystemC is the foundation of the co-simulation. It isn't just a library; it's an event-driven simulation kernel that manages "Time" and "Concurrency" in C++.

### Why Version 2.3.3?
Xilinx libraries are validated against the Accellera SystemC 2.3.x series. 2.3.3 is the stable release that balances modern C++ support with the strict requirements of TLM-2.0.

### The C++14 Requirement
Modern co-simulation demos use **variadic templates** and **standard smart pointers** which are optimized in the C++14 standard. Building SystemC with `-std=c++14` ensures that the library's ABI (Application Binary Interface) matches the demo code, preventing "undefined reference" errors during linking.

### Key Components:
- **`sc_main`**: The entry point. Unlike a standard `main()`, it initializes the SystemC kernel before executing.
- **`sc_time`**: A specialized class for picosecond-accurate timing.
- **`sc_signal`**: Used for modeling physical wires (like resets and interrupts).

---

## 2. libsystemctlm-soc (The Bridge Library)

This is the most critical repository. It translates between the low-level Remote-Port protocol (C) and the high-level TLM-2.0 protocol (C++).

### Directory Structure:
- **`libremote-port/`**: Contains the pure C code for socket communication and packet parsing. This is the "driver" for the Remote-Port protocol.
- **`soc/xilinx/`**: Contains the C++ "wrappers" for Xilinx chips.
  - `zynqmp/xilinx-zynqmp.h`: Defines the AArch64 processor cluster and its bus interfaces (HPM, HPC, LPD).
  - `versal/xilinx-versal.h`: Defines the Versal ACAP architecture.
- **`tlm-bridges/`**: Contains logic to convert TLM transactions into AXI, APB, or CHI signals.

### Logic Flow:
1. A packet arrives from QEMU via the Unix Socket.
2. `libremote-port` decodes it into a bus request (Address, Data, Size).
3. `xilinx-zynqmp` receives it and generates a `tlm::tlm_generic_payload`.
4. The payload is sent through the SystemC `bus` to the target memory or model.

---

## 3. qemu-devicetrees (Hardware Definition)

Traditional QEMU uses built-in machines. Xilinx QEMU uses external **Device Trees (DTBs)** to allow extreme flexibility.

### The `remote-port` Node
This is the "special sauce" in the DTS file. It doesn't describe real silicon; it describes how QEMU should talk to an external process.
```dts
pmu@0 {
    compatible = "remote-port";
    chrdev-id = "pmu-apu-rp";  // Links to a socket
};
```

### Multi-Arch vs. Single-Arch
- **Single-Arch**: Used when only one processor architecture is involved (e.g., just the ARM Cortex-A9 in Zynq-7000).
- **Multi-Arch**: Used for complex SoCs like ZynqMP, where you have A53 cores (Application) and R5 cores (Real-time) running simultaneously in different QEMU instances. This is why we used the `MULTI_ARCH` folder for ZynqMP.

### The Build Logic:
The `Makefile` in this repo uses `dtc` (Device Tree Compiler) with a large set of include files (`zynqmp.dtsh`, `versal.dtsh`) to generate board-specific binaries for every Xilinx evaluation board (ZCU102, ZCU104, VCK190).

---

## 4. systemctlm-cosim-demo (The Integration Demos)

These applications act as the "Main" program that ties everything together.

### Demo Breakdown:
- **`zynq_demo`**: Models a Zynq-7000. It tests the ARMv7 interaction with PL (Programmable Logic) memory.
- **`zynqmp_demo`**: Our primary test. It models a complex ZynqMP system with 4x A53 cores, demo DMA, and custom memory blocks.
- **`versal_demo`**: Models the Versal ACAP, including the PMC (Platform Management Controller).

### Detailed Operation:
The demos don't just "stay alive." They actively:
1. Initialize the SoC module.
2. Instantiate a **TLM Bus** (`iconnect.h`).
3. Connect a **Debug Device** (`debugdev.h`).
4. Wait for QEMU to connect.
5. Capture every transaction into **`trace.vcd`** for debugging.

---

## 5. PetaLinux & Xilinx QEMU (The Environment)

We used **PetaLinux 2025.2** because it provides the pre-patched Xilinx QEMU fork.

### Critical Modifications in Xilinx QEMU:
- **`-machine-path`**: A non-standard flag that tells QEMU which directory to use for its Unix sockets.
- **`-sync-quantum`**: The engine for the "global clock." It forces QEMU to wait for SystemC to acknowledge every block of simulation time.
- **`-device loader`**: This is used to write values directly into CPU registers or memory during startup. For example:
  - `addr=0xfd1a0104,data=0x8000000e`: This specific write releases the ZynqMP CPUs from reset, allowing them to start executing from the programmed start address.

---

## 6. The "PMU Bypass" Logic

This was the final hurdle in our setup.

- **The Problem**: ZynqMP has a PMU (Platform Management Unit - a MicroBlaze CPU). The standard co-simulation DTB expects a second socket for the PMU (Remote-Port 1). If you don't provide it, QEMU hangs forever.
- **The Solution**: We used a Python script (or manual editing) to delete the `pmu@0` node and its aliases from the DTS.
- **The Result**: QEMU now thinks the PMU is not part of the co-simulation, allowing us to simulate just the APU (Application Processing Unit) without the overhead of a second simulation process.
