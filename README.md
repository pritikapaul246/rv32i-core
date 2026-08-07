# Single-Cycle RV32I RISC-V CPU Core

A from-scratch, single-cycle implementation of a subset of the RV32I RISC-V
instruction set architecture in Verilog, with a self-checking testbench and
lint verification.

**Status:** Core datapath (fetch/decode/execute/memory/writeback) is
implemented and verified for the instruction subset listed below. This is
a working, testable core — not a complete RV32I implementation. See
"Known Limitations" for exactly what's out of scope.

## Architecture

Classic single-cycle datapath, structured into separate modules:

| Module                    | Role |
|---------------------------|------|
| `rtl/rv32i_core.v`        | Top-level datapath: PC logic, module interconnect |
| `rtl/control.v`           | Main + ALU decoder — generates all control signals from opcode/funct3/funct7 |
| `rtl/imm_gen.v`           | Generates sign-extended immediates for I/S/B/U/J instruction formats |
| `rtl/regfile.v`           | 32×32-bit register file, x0 hardwired to zero |
| `rtl/alu.v`               | ADD/SUB/AND/OR/XOR/SLT/SLL/SRL |
| `rtl/imem.v`              | Instruction memory, loaded from `program.hex` |
| `rtl/dmem.v`              | Data memory, byte-addressed but word-aligned in this version |
| `tb/tb_rv32i_core.v`      | Self-checking testbench |
| `sim/program/program.hex` | Hand-assembled demo program |
| `sim/run.sh`              | One-command build + simulate script |

## Repo Structure

```
rv32i-core/
├── rtl/            RTL source (synthesizable design)
├── tb/             Testbench (verification only, not synthesizable)
├── sim/
│   ├── program/    Hand-assembled test programs (.hex)
│   └── run.sh      Build + simulate script
├── docs/           (reserved for future: pipeline diagram, ISA notes)
├── README.md
└── .gitignore
```

## Supported Instructions

- R-type: `add, sub, and, or, xor, slt, sll, srl`
- I-type: `addi, andi, ori, xori, slti`
- Memory: `lw, sw`
- Control flow: `beq, jal`
- `lui`

This is intentionally a subset — enough to demonstrate a correct working
datapath and control unit, not a full ISA implementation.

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

Run it:
```bash
./sim/run.sh
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

View the waveform with `gtkwave rv32i.vcd` to trace PC, instruction fetch,
and register writeback cycle by cycle.

## Lint

Run with Verilator (from repo root):
```bash
verilator --lint-only -Wall rtl/*.v --top-module rv32i_core
```

Findings (all reviewed, none are bugs):
- `imm_gen.v`: opcode bits `instr[6:0]` unused — expected, since imm_gen
  only reads the immediate-relevant instruction fields, not the opcode.
- `imem.v` / `dmem.v`: address bits `[31:10]` and `[1:0]` unused —
  expected, since this design uses word-aligned addressing over a small
  256-word memory (`addr[9:2]` indexes the array); the unused bits would
  matter in a design with byte-addressable memory or a larger address
  space.

## How to explain this design in an interview

- Why single-cycle first: it's the cleanest way to get correct control
  logic before adding pipelining complexity (hazards, forwarding,
  branch prediction) — the natural next step.
- Why these instructions: chosen to exercise every datapath element
  (ALU ops, memory read/write, register writeback, immediate generation,
  control flow) with the smallest useful subset.
- Known next steps if extended: pipeline it (5-stage classic MIPS-style),
  add JALR + branch variants beyond BEQ, add CSRs for interrupts,
  and push the RTL through an open-source synthesis/PnR flow
  (Yosys + OpenLane on the SkyWater 130nm PDK) to go from RTL to a
  real physical layout — directly relevant for SoC/ASIC-focused roles.
