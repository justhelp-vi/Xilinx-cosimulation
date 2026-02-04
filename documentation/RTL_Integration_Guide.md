# Master Guide: Integrating Custom RTL with Verilator & SystemC

This guide provides a step-by-step workflow for adding your own Verilog designs into the Xilinx Co-Simulation environment. We will use the existing `apb_timer` as a reference template.

> [!IMPORTANT]
> **Recommended Entry Point**: For beginner testing, it is **highly recommended** to use `zynq_demo.cc` as your reference instead of `zynqmp_demo.cc`. The Zynq-7000 architecture is much simpler and does **not** have the PMU connection requirements, making your first RTL experiments much easier to debug.

---

## 🚀 Overview of the Flow

To see your Verilog code running on a PC, it follows this transformation:
1. **Verilog (`.v`)** $\rightarrow$ **Verilator** $\rightarrow$ **C++ Headers/Objects**
2. **SystemC Top (`.cc`)** $\rightarrow$ **Instantiates C++ Model**
3. **TLM Bridge** $\rightarrow$ **Converts Bus Transactions to RTL Pins**

---

## 🛠 Step 1: Write your Verilog RTL
Create your module (e.g., `my_device.v`). Ensure it uses a standard bus interface like **APB** or **AXI-Lite**, as we have ready-made bridges for these.

**Example (Snippet of `apb_timer.v`):**
```verilog
module apb_timer (
    input pclk, input presetn,
    input psel, input penable, input pwrite,
    input [15:0] paddr, input [31:0] pwdata,
    output [31:0] prdata, output pready
);
    // YOUR LOGIC HERE
endmodule
```

---

## 🏗 Step 2: Update the Build System (Makefile)
You must tell the project to "Verilate" your new file.

1.  Open `Makefile` in `systemctlm-cosim-demo/`.
2.  Add your file to the `VFILES` list:
    ```makefile
    VFILES += my_device.v
    ```
3.  Add the generated library to the `V_LDLIBS` list:
    ```makefile
    V_LDLIBS += $(VOBJ_DIR)/Vmy_device__ALL.a
    ```

---

## 🧩 Step 3: Instantiate in SystemC (`zynqmp_demo.cc`)
Now you must "plug in" the virtual chip into the virtual motherboard.

### A. Include the Headers
At the top of `zynqmp_demo.cc`, add:
```cpp
#ifdef HAVE_VERILOG_VERILATOR
#include "Vmy_device.h"  // Verilator adds a 'V' prefix
#endif
```

### B. Define the Module and Signals
Inside `SC_MODULE(Top)`, define the instance and the "wires" (signals):
```cpp
Vmy_device *my_device;

// Define SystemC signals (The Wires)
sc_signal<bool> sig_psel;
sc_signal<bool> sig_penable;
sc_signal<sc_bv<32>> sig_pwdata;
// ... add others for addr, prdata, etc.
```

### C. Initialize and Connect
In the `Top` constructor:
```cpp
// 1. Create the instance
my_device = new Vmy_device("my_device");

// 2. Connect pins to SystemC signals
my_device->pclk(clk);
my_device->presetn(rst_n);
my_device->psel(sig_psel);
my_device->penable(sig_penable);
// ... repeat for all pins
```

---

## 🌉 Step 4: The TLM Bridge
The CPU speaks "Addresses," but the RTL speaks "Pins." We use a **Bridge** to translate.

1.  **Define the Bridge**:
    ```cpp
    tlm2apb_bridge<bool, sc_bv, 16, sc_bv, 32> *my_bridge;
    ```
2.  **Connect Bridge to Signals**:
    ```cpp
    my_bridge = new tlm2apb_bridge<...>("my_bridge");
    my_bridge->psel(sig_psel);
    my_bridge->penable(sig_penable);
    // ... the bridge drives the signals you defined in Step 3!
    ```

---

## � Step 5: The Hardware Map (Device Tree / DTB)

This is the most critical part. Even if your RTL is perfect, QEMU won't know it exists unless it's in the **DTB**.

### A. Decompile the DTB
You cannot edit the binary `.dtb` directly. You must convert it to `.dts` (source text):
```bash
dtc -I dtb -O dts -o my_board.dts zcu102-arm.cosim.no_pmu.dtb
```

### B. Add a Memory Window
Inside the `.dts`, find the `amba@0` or `hpm0_fpd` section. You need to define a "Remote-Port Memory Slave" node.

**Example (Adding a new range at 0xA0030000)**:
```dts
hpm0_mydev@a0030000 {
    compatible = "remote-port-memory-master"; // Tells QEMU to ship data out
    remote-ports = <0x63 0x0A>;               // 0x63 = cosim node, 0x0A = PORT ID 10
    reg = <0x00 0xa0030000 0x00 0x00010000>;  // Base/Size (1MB)
};
```
*   **Why?**: This creates a "Trap" in QEMU's memory map. Any CPU instruction hitting this range is grabbed and sent to the socket.
*   **The ID**: The number `0x0A` (10) **MUST** match the `register_dev(10, ...)` code in SystemC.

### C. Recompile
```bash
dtc -I dts -O dtb -o zcu102-custom.dtb my_board.dts
```

---

## 📍 Step 6: Memory Mapping (SystemC)
[... existing section ...]
In your code (e.g., `app.c`), you can now talk to your Verilog logic!

```c
#define MY_DEVICE_ADDR 0xA0030000
volatile uint32_t *reg = (uint32_t *)MY_DEVICE_ADDR;

// This write triggers the Wires/Pins in Verilog!
*reg = 0x12345678;
```

---

## ⚡ Step 7: Handling Interrupts (IRQs)
If your RTL module has an `irq` output pin, you can connect it back to the ZynqMP processing system.

1.  **Define the Signal**:
    ```cpp
    sc_signal<bool> sig_irq;
    ```
2.  **Connect pin to signal**:
    ```cpp
    my_device->irq(sig_irq);
    ```
3.  **Connect to ZynqMP Interrupt Input**:
    ```cpp
    // Connect to PL-to-PS IRQ 0
    zynq.pl2ps_irq[0](sig_irq);
    ```

Now, the ARM CPU will receive an interrupt when your Verilog logic toggles the IRQ pin!

---

## 🏁 Summary Checklist
| Task | File to Modify | Why? |
| :--- | :--- | :--- |
| **Write RTL** | `my_device.v` | Hardware Logic. |
| **Add to Build** | `Makefile` | Tell Compiler to Verilate. |
| **Include Header** | `zynqmp_demo.cc` | Expose C++ Class. |
| **Instantiate Pins**| `zynqmp_demo.cc` | Create the wires. |
| **Add Bridge** | `zynqmp_demo.cc` | Bus $\rightarrow$ Pin converter. |
| **Patch DTB** | `my_board.dts` | **The Trap**: Tell QEMU where it is. |
| **Map Address** | `zynqmp_demo.cc` | **The Route**: Tell SystemC where it is. |
| **Connect IRQ** | `zynqmp_demo.cc` | Signal feedback to CPU. |

---

## 💡 Pro-Tip: The "Port ID" Rule
The property `remote-ports = <&cosim 10>` in the Device Tree and `register_dev(10, ...)` in SystemC are the **Socket IDs**. If these don't match exactly, the packets will be sent to the socket but SystemC will drop them because it doesn't know which module they belong to!

---

> [!TIP]
> **Debugging Pro-Tip**: Always run with GTKWave to verify Step 3 & 4. If you see the `psel` wire toggle in the waveforms, but your RTL doesn't respond, the issue is inside your `.v` code. If `psel` never toggles, the issue is in your `memmap` or bridge connection!
