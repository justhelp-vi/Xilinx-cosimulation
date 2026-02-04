#!/bin/bash

# Xilinx QEMU + SystemC Co-Simulation Environment Setup
# Source this script to initialize your workspace: source scripts/setup_env.sh

# 1. Detect Project Root
export PROJ_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

# 2. Configurable Paths (Update these if you installed elsewhere)
export SYSTEMC_HOME="${SYSTEMC_HOME:-$PROJ_ROOT/systemc-2.3.3-install}"
export PETALINUX_HOME="${PETALINUX_HOME:-$PROJ_ROOT/petalinux}"

# 3. Validation
if [ ! -d "$SYSTEMC_HOME" ]; then
    echo "Warning: SYSTEMC_HOME ($SYSTEMC_HOME) not found."
fi

if [ ! -d "$PETALINUX_HOME" ]; then
    echo "Warning: PETALINUX_HOME ($PETALINUX_HOME) not found."
fi

# 4. Export Library Paths
export LD_LIBRARY_PATH="$SYSTEMC_HOME/lib-linux64:$LD_LIBRARY_PATH"

# 5. Helper Aliases
alias qemu-zynqmp="source $PETALINUX_HOME/settings.sh && qemu-system-aarch64"
alias qemu-zynq7k="source $PETALINUX_HOME/settings.sh && qemu-system-arm"

echo "-------------------------------------------------------"
echo "Xilinx Co-Sim Environment Initialized"
echo "PROJ_ROOT:      $PROJ_ROOT"
echo "SYSTEMC_HOME:   $SYSTEMC_HOME"
echo "PETALINUX_HOME: $PETALINUX_HOME"
echo "-------------------------------------------------------"
echo "Ready for simulation."
