# Single-Cycle RV32I RISC-V CPU Core

A from-scratch, single-cycle implementation of a subset of the RV32I RISC-V
instruction set architecture in Verilog, with a self-checking testbench and
lint verification.

**Status:** Core datapath (fetch/decode/execute/memory/writeback) is
implemented and verified for the instruction subset listed below. This is
a working, testable core — not a complete RV32I implementation.

## Architecture

Classic single-cycle datapath, structured into separate modules:

| Module                    | Role |
|---------------------------|------|
| `rtl/rv32i_core.v`        | Top-level datapath: PC logic, module interconnect. Exposes `wb_data_out` so the datapath is observable and is kept by synthesis |
| `rtl/control.v`           | Main + ALU decoder, generates all control signals from opcode/funct3/funct7 |
| `rtl/imm_gen.v`           | Generates sign-extended immediates for I/S/B/U/J instruction formats |
| `rtl/regfile.v`           | 32x32-bit register file, x0 hardwired to zero |
| `rtl/alu.v`               | ADD/SUB/AND/OR/XOR/SLT/SLL/SRL |
| `rtl/imem.v`              | 64-word instruction memory, loaded from `program.hex` |
| `rtl/dmem.v`              | 32-word data memory, byte-addressed but word-aligned in this version |
| `tb/tb_rv32i_core.v`      | Self-checking testbench |
| `sim/program/program.hex` | Hand-assembled demo program |
| `sim/run.sh`              | One-command build + simulate script |
| `cov_sim/sim_main.cpp`    | Verilator C++ driver that writes `coverage.dat` on exit |

## Repo Structure

```
rv32i-core/
├── rtl/            RTL source (synthesizable design)
├── tb/             Testbench (verification only, not synthesizable)
├── sim/
│   ├── program/    Hand-assembled test programs (.hex)
│   └── run.sh      Build + simulate script
├── cov_sim/        Verilator coverage driver
├── README.md
└── .gitignore
```

## Supported Instructions

- R-type: `add, sub, and, or, xor, slt, sll, srl`
- I-type: `addi, andi, ori, xori, slti`
- Memory: `lw, sw`
- Control flow: `beq, jal`
- `lui`


## Known Limitations

- No `jalr` (needed for function call/return sequences)
- Only `beq` is implemented; `bne`, `blt`, `bge`, `bltu`, `bgeu` are not
- Only word-aligned `lw`/`sw`; no `lb`, `lh`, `lbu`, `lhu`, `sb`, `sh`
- No CSRs, exceptions, or interrupts
- Single-cycle, not pipelined — no hazard/forwarding logic exists because
  there's no pipeline to create hazards yet

## Verification

`tb_rv32i_core.v` runs a hand-assembled program through the core:

```
addi x1, x0, 5        # x1 = 5
addi x2, x0, 10        # x2 = 10
add  x3, x1, x2         # x3 = 15
sw   x3, 0(x0)          # mem[0] = 15
lw   x4, 0(x0)          # x4 = 15 (round-tripped through data memory)
jal  x0, 0              # infinite loop (halt)
```

Confirmed passing output:
```
x1     = 5   (expect 5)
x2     = 10  (expect 10)
x3     = 15  (expect 15)
x4     = 15  (expect 15, round-tripped through data memory)
mem[0] = 15  (expect 15)
RESULT: PASS - core executed ADDI/ADD/SW/LW correctly
```

## Coverage (Verilator)

Measured with Verilator 5.052 `--coverage`:

| Metric     | Result |
|------------|--------|
| Line       | 50.9% (29/57) |
| Branch     | 81.8% (18/22) |
| Expression | 88.0% (22/25) |

Totals include the testbench file's own lines. Coverage is low on `alu.v`
and `control.v` because the demo program only exercises ADDI/ADD/SW/LW.
Toggle coverage is low because the test values are small, so the upper bits
of the 32-bit buses never switch.

Reproduce (from repo root):
```bash
verilator --coverage --timing -Wno-fatal --top-module tb_rv32i_core --cc rtl/*.v tb/tb_rv32i_core.v --exe cov_sim/sim_main.cpp -Mdir obj_dir_cov
make -C obj_dir_cov -f Vtb_rv32i_core.mk
cp sim/program/program.hex obj_dir_cov/
cd obj_dir_cov && ./Vtb_rv32i_core && cd ..
verilator_coverage --annotate obj_dir_cov/coverage_annotated obj_dir_cov/coverage.dat
```

## Lint

Run with Verilator (from repo root):
```bash
verilator --lint-only -Wall rtl/*.v --top-module rv32i_core
```

Findings (all reviewed, none are bugs):
- `imm_gen.v`: opcode bits `instr[6:0]` unused. Expected, since imm_gen
  only reads the immediate-relevant instruction fields, not the opcode.
- `imem.v` / `dmem.v`: upper and lowest address bits unused. Expected,
  since this design uses word-aligned addressing over small memories
  (`addr[7:2]` indexes the 64-word imem, `addr[6:2]` the 32-word dmem);
  the unused bits would matter in a byte-addressable or larger design.

## Synthesis (Yosys)

Generic gate-level synthesis with Yosys 0.63 (`synth -top rv32i_core`):

| Item | Result |
|------|--------|
| Total cells | 3,757 |
| Flip-flops | 1,312 |
| Multiplexers | 1,320 |
| Design check problems | 0 |

The top module originally exposed only `pc_out` and `instr_out`, so
synthesis removed the register file and data memory as unobservable logic
(about 32 flip-flops remained). Adding the `wb_data_out` port and reducing
memory sizes produced a representative netlist. The instruction memory is
a fixed ROM loaded from `program.hex` at synthesis time.

Reproduce:
```bash
cp sim/program/program.hex .
yosys -p "read_verilog rtl/alu.v rtl/regfile.v rtl/control.v rtl/imm_gen.v rtl/imem.v rtl/dmem.v rtl/rv32i_core.v; hierarchy -top rv32i_core; proc; flatten; opt; synth -top rv32i_core; stat"
```
