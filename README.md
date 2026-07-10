# Pipelined-processor

# Pipelined RISC-V (RV32I) Processor with STA Optimization

A 32-bit, 5-stage pipelined RV32I processor written in synthesizable
Verilog, with full data/control hazard handling and a documented flow for
synthesis + static timing analysis (STA) driven optimization.

```
IF -> ID -> EX -> MEM -> WB
```

**Overview:** Designed and implemented a 32-bit 5-stage pipelined RISC-V processor; analyzed critical timing paths through synthesis and static timing analysis; optimized the design to improve timing performance and achieve timing closure.

---

## Highlights

- Full RV32I base ISA (minus system/fence instructions)
- Classic 5-stage pipeline with **all four** pipeline registers explicit
  in RTL (`IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB`), not collapsed into a
  single always-block "pipeline" shortcut.
- **Data hazards**: full EX/MEM + MEM/WB forwarding into the EX stage,
  plus a load-use stall when forwarding alone can't close the gap.
- **Control hazards**: branches/jumps resolved in EX with a 2-stage
  flush on taken branches/jumps.
- Self-checking testbench (`tb/tb_riscv_top.v`) with a hand-verified test
  program that specifically exercises every hazard case above.
- A documented, reproducible STA methodology that identifies design's actual critical path (register-file read -> forwarding mux ->
  ALU -> branch comparator -> PC mux) and gives four concrete, ordered optimizations plus a deeper-pipelining (5->7 stage) escalation path.

## Repository layout

```
rtl/            Synthesizable Verilog source
  defines.vh          Shared opcode / ALU-op / control parameters
  program_counter.v   PC register
  instr_mem.v          Instruction memory (readmemh-loaded)
  data_mem.v           Byte-addressable data memory
  register_file.v      32x32 GPR file
  imm_gen.v            Immediate generator (I/S/B/U/J)
  alu.v                32-bit ALU + branch flags
  alu_control.v        ALU opcode decode
  control_unit.v       Main instruction decoder
  if_id_reg.v          IF/ID pipeline register
  id_ex_reg.v          ID/EX pipeline register
  ex_mem_reg.v         EX/MEM pipeline register
  mem_wb_reg.v         MEM/WB pipeline register
  hazard_unit.v        Load-use stall + branch/jump flush logic
  forwarding_unit.v    EX-stage operand forwarding
  riscv_top.v          Top-level integration

tb/
  tb_riscv_top.v       Self-checking testbench

sim/
  program.hex          Machine code for the bundled test program

scripts/
  mini_asm.py          Tiny RV32I encoder used to build program.hex
  synth.ys              Yosys synthesis script

docs/
  ARCHITECTURE.md       Pipeline diagram, module map, hazard handling detail
  STA_GUIDE.md           Synthesis + STA methodology, critical path analysis,
                          ordered optimization plan
  RESULTS_TEMPLATE.md    Before/after metrics table to fill in with your run
```

Expected output (from `tb/tb_riscv_top.v`):

```
[PASS] x1  (addi) : 5
[PASS] x2  (addi) : 10
[PASS] x3  (add, forwarded) : 15
[PASS] x4  (sub, forwarded) : 10
[PASS] x5  (lw) : 15
[PASS] x6  (add after load-use hazard) : 15
[PASS] x8  (branch target, post-flush) : 1
[PASS] x9  (JAL link address) : 44
[PASS] x11 (JAL target) : 7
[PASS] x20 (must be squashed by branch flush) : 0
[PASS] x21 (must be squashed by JAL flush) : 0
ALL CHECKS PASSED
```
## Synthesis + STA

## Project phases (how this was built, and how to extend it)

This repo follows a deliberate build order — useful both as a study path
and as a way to explain the project in an interview:

1. **Single-cycle first.** Get PC / IMem / RegFile / ALU / Control /
   DMem / ImmGen / muxes correct with nothing pipelined.
2. **Pipeline it.** Insert `IF/ID`, `ID/EX`, `EX/MEM`, `MEM/WB` registers.
3. **Fix hazards.** Add `forwarding_unit` (data hazards) and `hazard_unit` (load-use stalls + control-hazard flushes).
4. **STA optimization.** 
   critical path, apply targeted optimizations (dedicated branch
   comparator, register balancing, retiming, logic restructuring,
   and if needed, deeper pipelining)

## Known simplifications

No exceptions/interrupts, no caches, no branch predictor (branches always
cost a fixed 2-cycle flush when taken). These are intentional scope cuts
for a portfolio-sized project and are called out explicitly in
`docs/ARCHITECTURE.md` rather than glossed over — the STA phase target is
the branch-resolution critical path this design already has, not a hidden
gap.

## License

MIT — see [`LICENSE`](LICENSE).
