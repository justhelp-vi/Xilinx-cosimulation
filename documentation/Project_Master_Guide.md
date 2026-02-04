# Project Master Guide (Absolute Beginner Edition)

This guide is designed for a complete beginner. Follow these steps exactly, one by one, to build a working Xilinx QEMU Co-Simulation environment on Linux.

> **Note**: This guide uses the path `~/Qemu` because that is your current setup. If you were starting from scratch on a new machine, you could use any folder name, but staying consistent is key.

---

## 🛑 Step 0: The Golden Rule
**Do not skip steps.** Even if you think you have a tool installed, run the command to be sure. We will work in `~/Qemu`.

---

## 🛠️ Step 1: Install Dependencies
Open your terminal (Ctrl+Alt+T) and copy-paste this command to install the required system tools:

```bash
sudo apt update
sudo apt install -y build-essential git python3 python3-pip dtc cmake libglib2.0-dev libpixman-1-dev zlib1g-dev device-tree-compiler
```

---

## 📂 Step 2: Create the Workspace
We will use the `~/Qemu` folder.

```bash
mkdir -p ~/Qemu
cd ~/Qemu
# Verify where you are:
pwd
# Output should be: /home/testuser/Qemu
```

---

## 📥 Step 3: Install SystemC (The Hardware Library)

1. **Download**: Go to [Accellera Downloads](https://www.accellera.org/downloads/standards/systemc) and download **SystemC 2.3.3 (Core SystemC Language and Examples)**.
   *File name should be: `systemc-2.3.3.tar.gz`*
   
2. **Move it**: Move the file you downloaded into your `~/Qemu` folder.

3. **Install it**: Run these commands one by one:
   ```bash
   cd ~/Qemu
   tar -xf systemc-2.3.3.tar.gz
   cd systemc-2.3.3
   mkdir build
   cd build
   # Configure with C++14 support (Critical!)
   ../configure --prefix=$HOME/Qemu/systemc-2.3.3-install CXXFLAGS="-std=c++14"
   make -j4
   make install
   ```

---

## 🐧 Step 4: Install PetaLinux (For Xilinx QEMU)

Standard QEMU does not work. You need Xilinx's special version.

1. **Download**: Go to the [AMD/Xilinx Download Page](https://www.xilinx.com/support/download/index.html/content/xilinx/en/downloadNav/embedded-design-tools.html).
2. **Select**: PetaLinux Tools -> 2025.2.
3. **Get File**: Download the **PetaLinux 2025.2 Installer** (`petalinux-v2025.2-....run`).
4. **Install**:
   ```bash
   cd ~/Qemu
   chmod +x petalinux-v2025.2-*-installer.run
   ./petalinux-v2025.2-*-installer.run --dir $HOME/Qemu/petalinux
   ```

---

## 📦 Step 5: Get the Project Code
Run these exactly:

```bash
cd ~/Qemu

# 1. The Bridge Library
git clone https://github.com/Xilinx/libsystemctlm-soc.git

# 2. The Demo Applications
git clone https://github.com/Xilinx/systemctlm-cosim-demo.git

# 3. The Device Trees (Board Configs)
git clone https://github.com/Xilinx/qemu-devicetrees.git
```

---

## 🔨 Step 6: Build Everything

### A. Build the Demos
```bash
cd ~/Qemu/systemctlm-cosim-demo

# Create the configuration file
echo "SYSTEMC = $HOME/Qemu/systemc-2.3.3-install" > .config.mk
echo "LD_LIBRARY_PATH = $HOME/Qemu/systemc-2.3.3-install/lib-linux64" >> .config.mk
echo "CXXFLAGS += -std=c++14" >> .config.mk
echo "HAVE_VERILOG = n" >> .config.mk

# Build
make
```

### B. Build Device Trees
```bash
cd ~/Qemu/qemu-devicetrees
make
```

---

## 🔧 Step 7: The "PMU Fix" and "Software App"

### A. Fix the PMU (Remove blocking hardware)
1. **The Problem**: QEMU hangs if it waits for a PMU co-simulator that isn't running.
2. **The Solution**: We strip the PMU-related nodes from the Device Tree.
3. **Use the Robust Script**: We have created a standalone script at `~/Qemu/documentation/strip_pmu.py` that handles this automatically and safely.

**How to use it**:
   ```bash
   cd ~/Qemu/qemu-devicetrees/LATEST/MULTI_ARCH
   # 1. Convert DTB to readable DTS text
   dtc -I dtb -O dts -o temp.dts zcu102-arm.cosim.dtb
   
   # 2. Run the robust patcher (using the file in your documentation folder)
   python3 ~/Qemu/documentation/strip_pmu.py temp.dts
   
   # 3. Convert back to binary DTB for QEMU
   dtc -I dts -O dtb -o zcu102-arm.cosim.no_pmu.dtb temp.dts
   ```

> [!TIP]
> **Simpler Alternative (Zynq-7000)**: If you are finding the PMU stripping and 64-bit startup too complex for your first test, you can use the **Zynq-7000** demo. It is a 32-bit architecture that has **no PMU requirements** and works immediately with standard Device Trees. (See Step 9 at the bottom of this guide).

### B. Create the Test Software
1. **App Code**:
   ```bash
   cd ~/Qemu/systemctlm-cosim-demo
   cat << EOF > app.c
   #include <stdint.h>
   // Use APB Timer Address (0xA0020000) for visible waveforms!
   // Use Debug Device (0xA0000000) for terminal prints only.
   #define DEBUG_DEV_ADDR 0xA0020000 
   
   int main() {
       volatile uint32_t *ptr = (uint32_t *)DEBUG_DEV_ADDR;
       
       // Infinite Loop: Toggle values to create visible waveforms in GTKWave
       while(1) {
           *ptr = 0xAAAAAAAA;
           for(volatile int j = 0; j < 50000; j++); // Delay
           *ptr = 0x55555555;
           for(volatile int j = 0; j < 50000; j++); // Delay
       }
       return 0;
   }
   EOF
   ```
2. **Startup Code**:
   ```bash
   cat << EOF > startup.s
   .global _start
   _start: ldr x0, =0x40000; mov sp, x0; bl main
   hang: b hang
   EOF
   ```
3. **Compile**:
   ```bash
   source ~/Qemu/petalinux/settings.sh
   aarch64-none-elf-gcc -g -Ttext=0x00000000 -nostartfiles startup.s app.c -o app.elf
   ```

---

## 📖 Appendix: Command Parameter Reference

To understand *why* we run those specific commands, here is a breakdown of the parameters:

### QEMU Parameters
- **`-M arm-generic-fdt`**: Tells QEMU to use a special Xilinx machine type that can "understand" Remote-Port nodes in the device tree.
- **`-dtb <file>`**: Loads the Hardware Map. This tells QEMU which addresses are local and which ones belong to the co-simulation socket.
- **`-machine-path ./qemu-tmp`**: Specifies where QEMU should create its Unix Domain Sockets (the communication files).
- **`-sync-quantum 10000`**: Defines the "Time Slice" for synchronization. This ensures QEMU and SystemC stay in **Lock-Step**: QEMU will pause every 10,000 picoseconds to wait for SystemC to catch up, preventing the two simulators from drifting apart in time.
- **`-device loader,file=app.elf,cpu-num=0`**: Directly injects your compiled code into the processor's memory at boot.
- **`-device loader,addr=0xfd1a0104,data=0x8000000e,data-len=4`**: A "Hardware Hack" used to release the ZynqMP CPUs from their initial sleep state (required for bare-metal apps).

### SystemC Parameters
- **`unix:./qemu-tmp/qemu-rport-...`**: The address of the socket file created by QEMU. This is the "Wire" connecting the two processes.
- **`10000`**: The sync quantum (must match QEMU).

---

## 🚀 Step 8: Run the Simulation!

You need **3 Terminal Windows**.

### Terminal 1: The Processor (QEMU)
Copy-paste this block:
```bash
# Setup Environment
source ~/Qemu/petalinux/settings.sh
cd ~/Qemu/systemctlm-cosim-demo

# Kill previous
pkill -f qemu-system-aarch64
mkdir -p ./qemu-tmp

# Run QEMU with Software
qemu-system-aarch64 -M arm-generic-fdt -nographic \
  -dtb ~/Qemu/qemu-devicetrees/LATEST/MULTI_ARCH/zcu102-arm.cosim.no_pmu.dtb \
  -device loader,file=app.elf,cpu-num=0 \
  -device loader,addr=0xfd1a0104,data=0x8000000e,data-len=4 \
  -machine-path ./qemu-tmp -sync-quantum 10000
```
*It will say "QEMU waiting for connection".*

### Terminal 2: The Hardware Model (SystemC)
Copy-paste this block:
```bash
cd ~/Qemu/systemctlm-cosim-demo
export LD_LIBRARY_PATH=~/Qemu/systemc-2.3.3/lib-linux64

# Run SystemC Demo
./zynqmp_demo unix:./qemu-tmp/qemu-rport-_amba@0_cosim@0 10000
```
*If you use debug device (0xA0000000) instead of APB timer (0xA0020000)You should see output here! or of you use apbtimer you should open the trace.vcd file in GTKWave!*

### Terminal 3: The Waveforms (GTKWave)
For detailed setup instructions, see the [GTKWave Setup Guide](GTKWave_Setup_Guide.md).

```bash
~/Qemu/gtkwave-install/bin/gtkwave ~/Qemu/systemctlm-cosim-demo/trace.vcd
```
1. Press `Shift+Ctrl+R` to reload.
2. Drag `apbtimer_pwdata` to the view.
3. Press `Alt+Z` to zoom out.


---

## 🏎️ Alternative: Zynq-7000 (32-bit ARM)
If you want to run on the older Zynq-7000 (Zedboard/ZC702) architecture:

### 1. Change Software Address
In `app.c`, change the address to `0x40000000`:
```c
#define DEBUG_DEV_ADDR 0x40000000
```

### 2. Run SystemC
```bash
./zynq_demo unix:./qemu-tmp/qemu-rport-_cosim@0 1000000
```

### 3. Run QEMU
```bash
mkdir -p ./qemu-tmp
qemu-system-arm -M xilinx-zynq-a9 -serial null -serial mon:stdio \
  -display none -m 1024 \
  -device loader,file=app.elf \
  -machine-path ./qemu-tmp
```

---

## ✅ Verification
- **Terminal 2**: Seeing "deadbeef" means Software -> QEMU -> Socket -> SystemC -> Print success.
- **Terminal 3**: Seeing waveforms means the signals are toggling in real time.

---

## 🏎️ Step 9: Running Zynq-7000 (The "Fast Track")

If you want to bypass the ZynqMP complexity, follow these steps for the 32-bit Zynq-7000 (ZedBoard) co-simulation.

### 1. Update your Software Address
In `app.c`, the Zynq-7000 uses a different bus entry point (`0x40000000`):
```c
#define DEBUG_DEV_ADDR 0x40000000 
```

### 2. Run QEMU (Terminal 1)
```bash
source ~/Qemu/petalinux/settings.sh
qemu-system-arm -M arm-generic-fdt -nographic \
  -dtb ~/Qemu/qemu-devicetrees/LATEST/SINGLE_ARCH/zynq-7000-arm.cosim.dtb \
  -machine-path ./qemu-tmp -sync-quantum 10000
```

### 3. Run SystemC (Terminal 2)
```bash
./zynq_demo unix:./qemu-tmp/qemu-rport-_amba@0_cosim@0 10000
```

---

## ✅ Final Verification
1. **Terminal 2**: Seeing output prints confirms the end-to-end path.
2. **Terminal 3**: Run `gtkwave trace.vcd` to see the 32-bit signals toggling.
