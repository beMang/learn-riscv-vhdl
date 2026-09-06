# Custom RISC-V RV32I Processor

A multicycle 32-bit RISC-V processor implementation written in VHDL-2008 from scratch. 
This project is "learning by doing" exploration of hardware description languages, CPU microarchitecture, and the RISC-V ISA for my personal knowledge.

## Features & Architecture
- **ISA:** RISC-V RV32I (Base Integer Instruction Set)
- **Architecture:** Multicycle Datapath (Not pipelined for now)
- **Language:** VHDL-2008
- **Simulation Toolchain:** GHDL & GTKWave
- **Target Hardware:** to be determined

---

## Instruction Implementation Status

**Progress:** 3 / 40 instructions implemented

| Category | Instruction | Description | Implemented |
| :--- | :--- | :--- | :---: |
| **Upper Immediate** | `LUI` | Load upper immediate | ❌ |
| | `AUIPC` | Add upper immediate to PC | ❌ |
| **Jumps** | `JAL` | Jump and link | ❌ |
| | `JALR` | Jump and link register | ❌ |
| **Branches** | `BEQ` | Branch if equal | ❌ |
| | `BNE` | Branch if not equal | ❌ |
| | `BLT` | Branch if less than (signed) | ❌ |
| | `BGE` | Branch if greater than or equal (signed) | ❌ |
| | `BLTU` | Branch if less than (unsigned) | ❌ |
| | `BGEU` | Branch if greater than or equal (unsigned) | ❌ |
| **Loads** | `LB` | Load byte (signed) | ❌ |
| | `LH` | Load halfword (signed) | ❌ |
| | `LW` | Load word | ❌ |
| | `LBU` | Load byte (unsigned) | ❌ |
| | `LHU` | Load halfword (unsigned) | ❌ |
| **Stores** | `SB` | Store byte | ❌ |
| | `SH` | Store halfword | ❌ |
| | `SW` | Store word | ❌ |
| **Immediate Arithmetic** | `ADDI` | Add immediate | ✅ |
| **Immediate Comparisons** | `SLTI` | Set less than immediate (signed) | ✅ |
| | `SLTIU` | Set less than immediate (unsigned) | ✅ |
| **Immediate Logical** | `XORI` | Bitwise XOR immediate | ❌ |
| | `ORI` | Bitwise OR immediate | ❌ |
| | `ANDI` | Bitwise AND immediate | ❌ |
| **Immediate Shifts** | `SLLI` | Shift left logical immediate | ❌ |
| | `SRLI` | Shift right logical immediate | ❌ |
| | `SRAI` | Shift right arithmetic immediate | ❌ |
| **Register Arithmetic** | `ADD` | Add registers | ❌ |
| | `SUB` | Subtract registers | ❌ |
| **Register Comparisons** | `SLT` | Set less than (signed) | ❌ |
| | `SLTU` | Set less than (unsigned) | ❌ |
| **Register Logical** | `XOR` | Bitwise XOR | ❌ |
| | `OR` | Bitwise OR | ❌ |
| | `AND` | Bitwise AND | ❌ |
| **Register Shifts** | `SLL` | Shift left logical | ❌ |
| | `SRL` | Shift right logical | ❌ |
| | `SRA` | Shift right arithmetic | ❌ |
| **System & Memory** | `FENCE` | Memory fence | ❌ |
| | `ECALL` | Environment call | ❌ |
| | `EBREAK` | Environment breakpoint | ❌ |

---

## Running Simulation

### Prerequisites
- [GHDL](https://github.com/ghdl/ghdl) (VHDL simulator)
- [GTKWave](http://gtkwave.sourceforge.net/) (Waveform viewer)

### Run Tests
```bash
# Analyze & Simulate (or make command does the same)
ghdl -a --std=08 components/*.vhd tb/*.vhd
ghdl -e --std=08 tb_top_level
ghdl -r --std=08 tb_top_level --wave=wave.ghw

# View Waveforms right now the setup file to visualize traces is not provided.
gtkwave wave.ghw
```