# Getting Started Guide
NOTE: Update the paths of other folders, tools and file path according to your project setup if you face any path related issues.

This guide covers the end-to-end setup and execution of the Xilinx QEMU + SystemC co-simulation environment.

## 🛠 Prerequisites

Ensure your system has the following dependencies installed:
```bash
sudo apt update
sudo apt install -y build-essential git python3 python3-pip dtc cmake libglib2.0-dev libpixman-1-dev zlib1g-dev device-tree-compiler
```

---

## 🏗 Step 1: Component Installation

### A. SystemC 2.3.3
1. Download SystemC from [Accellera](https://www.accellera.org/downloads/standards/systemc).
2. Install into `$HOME/Qemu/systemc-2.3.3-install`:
   ```bash
   tar -xf systemc-2.3.3.tar.gz
   cd systemc-2.3.3
   mkdir build && cd build
   ../configure --prefix=$HOME/Qemu/systemc-2.3.3-install CXXFLAGS="-std=c++14"
   make -j$(nproc) && make install
   ```

### B. PetaLinux (Xilinx QEMU)
1. Download the PetaLinux 2025.2 installer from [AMD/Xilinx](https://www.xilinx.com/support/download/index.html).
2. Install into `$HOME/Qemu/petalinux`:
   ```bash
   chmod +x petalinux-v2025.2-*-installer.run
   ./petalinux-v2025.2-*-installer.run --dir $HOME/Qemu/petalinux
   ```

---

## 📂 Step 2: Workspace Setup

1. **Clone Repositories**:
   ```bash
   cd $PROJ_ROOT
   git clone https://github.com/Xilinx/libsystemctlm-soc.git
   git clone https://github.com/Xilinx/systemctlm-cosim-demo.git
   git clone https://github.com/Xilinx/qemu-devicetrees.git
   ```

2. **Initialize Environment**:
   ```bash
   source scripts/setup_env.sh
   ```

---

## 🔨 Step 3: Building the Project

### A. Demos
```bash
cd $PROJ_ROOT/systemctlm-cosim-demo
echo "SYSTEMC = $SYSTEMC_HOME" > .config.mk
echo "LD_LIBRARY_PATH = $SYSTEMC_HOME/lib-linux64" >> .config.mk
echo "CXXFLAGS += -std=c++14" >> .config.mk
echo "HAVE_VERILOG = n" >> .config.mk
make
```
### B. If header files missing
```bash
I have observed a issue at compiling the demo in some systems, where we manually need to update the path of the libsystemctlm-soc in the $PROJ_ROOT/systemctlm-cosim-demo
Makefile. 
```
### C. Device Trees
```bash
cd $PROJ_ROOT/qemu-devicetrees
make
```

---

## 🔧 Step 4: The PMU Fix (ZynqMP Only)

ZynqMP co-simulation requires stripping the PMU nodes to prevent QEMU from hanging while waiting for a PMU co-simulator.

```bash
cd $PROJ_ROOT/qemu-devicetrees/LATEST/MULTI_ARCH
dtc -I dtb -O dts -o temp.dts zcu102-arm.cosim.dtb
python3 $PROJ_ROOT/scripts/strip_pmu.py temp.dts
dtc -I dts -O dtb -o zcu102-arm.cosim.no_pmu.dtb temp.dts
```

---

## 🚀 Step 5: Running the Simulation

### Option 1: ZynqMP (64-bit) - High Performance
**Terminal 1 (QEMU)**:
```bash
source $PETALINUX_HOME/settings.sh
qemu-system-aarch64 -M arm-generic-fdt -nographic \
  -dtb $PROJ_ROOT/qemu-devicetrees/LATEST/MULTI_ARCH/zcu102-arm.cosim.no_pmu.dtb \
  -device loader,file=app.elf,cpu-num=0 \
  -device loader,addr=0xfd1a0104,data=0x8000000e,data-len=4 \
  -machine-path ./qemu-tmp -sync-quantum 10000
```
**Terminal 2 (SystemC)**:
```bash
source scripts/setup_env.sh
./zynqmp_demo unix:./qemu-tmp/qemu-rport-_amba@0_cosim@0 10000
```

### Option 2: Zynq-7000 (32-bit) - Beginner Friendly
**Terminal 1 (QEMU)**:
```bash
source $PETALINUX_HOME/settings.sh
qemu-system-arm -M arm-generic-fdt -nographic \
  -dtb $PROJ_ROOT/qemu-devicetrees/LATEST/SINGLE_ARCH/zynq-7000-arm.cosim.dtb \
  -machine-path ./qemu-tmp -sync-quantum 10000
```
**Terminal 2 (SystemC)**:
```bash
source scripts/setup_env.sh
./zynq_demo unix:./qemu-tmp/qemu-rport-_amba@0_cosim@0 10000
```
---

## ✅ Verification
- Check your serial console for application prints.
- Open `trace.vcd` in GTKWave to view hardware signal transitions.
