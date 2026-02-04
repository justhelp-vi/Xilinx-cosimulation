### NOTE ###
For detailed and clear explanation explore the other branch


# Xilinx QEMU + SystemC + Verilator Co-Simulation Hub

A professional framework for high-performance co-simulation of Xilinx Zynq-7000 and ZynqMP SoCs using QEMU, SystemC TLM-2.0, and Verilated RTL.

## 🚀 Overview

This project provides a complete environment to simulate Xilinx Processing Systems (PS) alongside custom Programmable Logic (PL) implemented in SystemC or Verilog. It leverages the **Xilinx Remote-Port** protocol to synchronize QEMU with external hardware models.

### Key Features
- **Dual Architecture Support**: Seamlessly switch between Zynq-7000 (32-bit) and ZynqMP (64-bit).
- **RTL Integration**: Direct integration of Verilog/VHDL code via Verilator.
- **Cycle-Accurate Handshake**: Quantized "Lock-Step" synchronization for precise hardware interaction.
- **Waveform Debugging**: Full GTKWave support for all PL signals.

## 🏁 Quick Start

1. **Clone the Repo**:
   ```bash
   git clone <repo-url>
   cd Qemu
   ```

2. **Setup the Environment**:
   ```bash
   source scripts/setup_env.sh
   ```

3. **Follow the Guide**:
   Read the **[Getting Started Guide](GETTING_STARTED.md)** for detailed installation and your first simulation run.

## 📚 Documentation

The technical documentation is organized into logically grouped guides:

- **[Getting Started](GETTING_STARTED.md)**: Installation and first run (The "Hello World").
- **[RTL Integration](docs/rtl_integration.md)**: How to add your custom Verilog/VHDL logic.
- **[Technical Deep Dive](docs/technical_deep_dive.md)**: Understanding Remote-Port, handshakes, and memory mapping.
- **[GTKWave Setup](docs/gtkwave_setup.md)**: Visualizing hardware signals.
- **[Strategic Overview](docs/strategic_architecture_overview.md)**: Architectural philosophy and use cases.

## 🛠 Project Structure

```text
├── docs/               # Technical guides and deep dives
├── scripts/            # Automation and utility scripts
├── README.md           # This file
└── GETTING_STARTED.md  # Main installation manual
```

## 🤝 Contributing

This is an open-source project. We welcome contributions to models, documentation, and tooling. Please refer to Xilinx's upstream repositories for core protocol specifications.
