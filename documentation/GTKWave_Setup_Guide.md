# GTKWave Setup & Debugging Guide

This guide covers how to install, launch, and master **GTKWave** for verifying Xilinx QEMU co-simulation.

---

## 🛠️ Part 1: Installation
If you haven't installed it yet, follow these steps to build it from source (which ensures compatibility).

### 1. Install Dependencies
```bash
sudo apt update
sudo apt install -y build-essential libgtk-3-dev gperf flex bison libbz2-dev liblzma-dev
```

### 2. Build from Source
Assuming you have the `gtkwave-gtk3-3.3.126.tar.gz` file in `~/Qemu`:

```bash
cd ~/Qemu
tar -xf gtkwave-gtk3-3.3.126.tar.gz
cd gtkwave-gtk3-3.3.126
./configure --prefix=$HOME/Qemu/gtkwave-install --enable-gtk3
make -j$(nproc)
make install
```

---

## 🚀 Part 2: Launching & Viewing
Since we installed it to a custom folder, you must use the full path.

### 1. Start the Viewer
```bash
~/Qemu/gtkwave-install/bin/gtkwave ~/Qemu/systemctlm-cosim-demo/trace.vcd
```

### 2. Configure the View
1.  **Locate Signals**: In the "SST" (Signal Search Tree) panel on the left, click:
    `SystemC` -> `top`
2.  **Add Signals**: Drag the following useful signals to the black "Signals" area:
    *   `clk` (Clock - should be toggling)
    *   `rst` (Reset - should be 0)
    *   `apbtimer_psel` (Chip Select)
    *   `apbtimer_pwdata` (Write Data)
    *   `apbtimer_paddr` (Address)
3.  **Zoom Out**: Press **`Alt` + `Z`** (Zoom Fit) to see the whole timeline.
4.  **Real-Time Update**: Press **`Shift` + `Ctrl` + `R`** to reload the file while simulation runs.

---

## 🔍 Part 3: Debugging "Flat Lines"
If your waveforms are flat (all 0s), check these three things:

### 1. Are you writing to the right address?
*   **Problem**: Writing to `0xA0000000` (Debug Device) shows text in terminal but **NO** waveforms.
*   **Fix**: Write to **`0xA0020000`** (APB Timer). This device is connected to a bridge that has visible wires.

### 2. Are you zoomed in too much?
*   **Problem**: You see flat lines but the terminal says data is moving.
*   **Fix**: Look at the time scale. If it says `ps` (picoseconds), you are zoomed in too far. Press `Alt+Z` to zoom out.

### 3. Is the simulation actually running?
*   **Problem**: The "End Time" in GTKWave isn't increasing when you press `Shift+Ctrl+R`.
*   **Fix**: Ensure your terminals are running. Terminal 1 (QEMU) should be "waiting for connection" or running. Terminal 2 (SystemC) should be printing `TRACE` lines.

---

## 📝 Reference: Visible Hardware Map
Use these addresses in your C code to see activity on different buses.

| Device Name | Address | Visible Signals (in GTKWave) |
| :--- | :--- | :--- |
| **Debug Device** | `0xA0000000` | **None** (Software only model) |
| **APB Timer** | `0xA0020000` | `apbtimer_psel`, `apbtimer_pwdata` |
| **AXI DMA** | `0xA0010000` | `dma0_...` signals |
| **RAM (Low)** | `0x00000000` | Internal QEMU only |

---

## ⚡ Pro-Tip: Continuous Waveforms
Standard C code runs once and stops. To see "live" updates, use an infinite loop in your application:

```c
// Toggle data forever to create visible square waves
while(1) {
    *ptr = 0xAAAAAAAA;
    for(volatile int i=0; i<50000; i++); // Delay
    *ptr = 0x55555555;
    for(volatile int i=0; i<50000; i++); // Delay
}
```
