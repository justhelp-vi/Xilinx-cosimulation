# Getting Started: Xilinx QEMU Co-Simulation Setup

This guide provides the exact steps required to replicate the Xilinx QEMU + SystemC co-simulation environment on a fresh Linux system (Ubuntu 22.04+ recommended).

## Prerequisites

- **Tools**: `build-essential`, `cmake`, `git`, `python3`, `dtc` (device-tree-compiler)
- **Disk Space**: ~25GB (PetaLinux consumes the most)
- **Memory**: 8GB+ RAM recommended

---

## 1. Install SystemC 2.3.3

1. **Download**: Get the SystemC 2.3.3 source [from Accellera](https://www.accellera.org/downloads/standards/systemc).
2. **Build with C++14**:
   ```bash
   mkdir systemc-install && cd systemc-install
   tar -xf systemc-2.3.3.tar.gz
   cd systemc-2.3.3
   mkdir build && cd build
   ../configure --prefix=/opt/systemc-2.3.3 CXXFLAGS="-std=c++14"
   make -j$(nproc)
   sudo make install
   ```

---

## 2. Install PetaLinux 2025.2 (For Xilinx QEMU)

Xilinx's fork of QEMU is required for the Remote-Port protocol.

1. **Download**: `petalinux-v2025.2-11160223-installer.run` from the Xilinx website.
2. **Setup Dependencies** (Refer to UG1144 for your OS).
3. **Install**:
   ```bash
   ./petalinux-v2025.2-11160223-installer.run --dir /opt/petalinux
   ```

---

## 3. Clone and Build Repositories

Create a workspace directory (e.g., `~/Qemu`) and clone these three:

### A. libsystemctlm-soc (TLM Wrappers)
```bash
git clone https://github.com/Xilinx/libsystemctlm-soc.git
```

### B. systemctlm-cosim-demo (Demo Applications)
```bash
git clone https://github.com/Xilinx/systemctlm-cosim-demo.git
cd systemctlm-cosim-demo
```
**Configure `.config.mk`**:
```makefile
SYSTEMC = /opt/systemc-2.3.3
LD_LIBRARY_PATH = /opt/systemc-2.3.3/lib-linux64
CXXFLAGS += -std=c++14
HAVE_VERILOG = n
```
**Build**:
```bash
make -j$(nproc)
```

### C. qemu-devicetrees (Board Definitions)
```bash
git clone https://github.com/Xilinx/qemu-devicetrees.git
cd qemu-devicetrees
make
```

---

## 4. The ZynqMP PMU Bypass Fix

Standard ZynqMP co-simulation hangs while waiting for a PMU co-simulator.

1. **The Tool**: We have already created a robust script: `~/Qemu/documentation/strip_pmu.py`.
2. **Apply the patch**:
   ```bash
   cd ~/Qemu/qemu-devicetrees/LATEST/MULTI_ARCH
   # Convert to text
   dtc -I dtb -O dts -o temp.dts zcu102-arm.cosim.dtb
   # STRIP PMU
   python3 ~/Qemu/documentation/strip_pmu.py temp.dts
   # Convert back to binary
   dtc -I dts -O dtb -o zcu102-arm.cosim.no_pmu.dtb temp.dts
   ```

---

## 5. Verification: Running the Demo

### Terminal 1: QEMU (Server)
```bash
source /opt/petalinux/settings.sh
qemu-system-aarch64 -M arm-generic-fdt -nographic \
  -dtb /path/to/zcu102-no-pmu.dtb \
  -machine-path ./qemu-tmp -sync-quantum 10000
```

### Terminal 2: SystemC (Client)
```bash
export LD_LIBRARY_PATH=/opt/systemc-2.3.3/lib-linux64
./zynqmp_demo unix:./qemu-tmp/qemu-rport-_amba@0_cosim@0 10000
```

### Verification Commands:
1. **Size check**: `ls -l trace.vcd` (should grow every second).
2. **Socket check**: `ls -la qemu-tmp/` (should show the `.amba` socket).
3. **Trace monitor**: `tail -f trace.vcd` (should see advancing `#` timestamps).
