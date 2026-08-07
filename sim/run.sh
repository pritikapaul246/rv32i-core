#!/bin/bash
# Compiles and runs the RV32I core testbench.
# Run from the repo root: ./sim/run.sh
set -e

cd "$(dirname "$0")/.."   # repo root
cp sim/program/program.hex .

iverilog -o sim/rv32i \
    rtl/alu.v rtl/regfile.v rtl/control.v rtl/imm_gen.v rtl/imem.v rtl/dmem.v rtl/rv32i_core.v \
    tb/tb_rv32i_core.v

vvp sim/rv32i

rm program.hex
echo ""
echo "Waveform written to rv32i.vcd — view with: gtkwave rv32i.vcd"
