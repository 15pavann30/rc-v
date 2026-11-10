# 📘 P18: Immediate Generator I/S — Dossier

> [!NOTE]
> **Block:** P18 (Immediate generator for I-type and S-type)
> **Processor:** RC-V (RV32I) · **Stage:** Decode · **Layer:** Datapath
> **Inputs:** `instr[31:0]` · **Outputs:** `imm_i[31:0]`, `imm_s[31:0]`

---

# 🔹 Unit Questions

## U1 · Digital Logic

**Key idea:** sign extension means copying the sign bit `instr[31]` into every upper output bit `imm[31:12]`.

### Truth table (one upper bit `y_k`, for k = 12 … 31)

| `s = instr[31]` | `y_k = imm[k]` | Explanation |
| :---: | :---: | :--- |
| `0` | `0` | Positive immediate, upper bit extended with 0 |
| `1` | `1` | Negative immediate (2's complement), upper bit extended with 1 |

### Simplified Boolean expression

```text
y_k = instr[31]        for 12 <= k <= 31      (identity / pure wire)
```

### Lower 12 bits

**I-type** (`imm_i`):

```text
imm_i[k] = instr[20 + k]          for 0 <= k <= 11
```

**S-type** (`imm_s`):

```text
imm_s[k] = instr[7 + k]           for 0 <= k <= 4
imm_s[k] = instr[20 + k]          for 5 <= k <= 11
```

> [!TIP]
> **Gates / flip-flops needed: none.** There are no AND/OR/NOT gates and no registers or latches. The whole unit is **combinational bus wiring** plus fan-out of the sign bit.

---

## U2 · Digital Components

The Digital implementation uses **only Splitters (bus splitters/combiners) and wiring**.

| # | Component | Configuration | Role |
| :-: | :--- | :--- | :--- |
| 1 | **Input Bus Splitter** | `32 -> 20-31, 7-11, 25-31, 31-31` | Breaks `instr[31:0]` into fields |
| 2 | **I-type Bus Combiner** | `12, 1*20 -> 32` | Builds `imm_i` |
| 3 | **S-type Bus Combiner** | `5, 7, 1*20 -> 32` | Builds `imm_s` |

**Fields produced by the input splitter**

| Bits | Width | Meaning |
| :---: | :---: | :--- |
| `[31:20]` | 12 | Raw I-type immediate |
| `[11:7]` | 5 | Low part of S-type immediate (`imm[4:0]`) |
| `[31:25]` | 7 | High part of S-type immediate (`imm[11:5]`) |
| `[31]` | 1 | Common sign bit |

**How the combiners are wired**

- **I-type combiner:** `instr[31:20]` goes to bits 0–11. `instr[31]` feeds all 20 single-bit inputs (bits 12–31).
- **S-type combiner:** `instr[11:7]` goes to bits 0–4, `instr[31:25]` goes to bits 5–11, and `instr[31]` feeds bits 12–31.

**In the larger datapath:**

```text
P18 (imm_i, imm_s) ─┐
                    ├─► P20 (Immediate Selector) ─► P26 (ALU Operand Selector) ─► ALU (P08)
P19 (imm_b/j/u)   ──┘
```

---

## U3 · Data Representation

### Test vectors

| # | Case | `instr` (hex) | Sign bit |
| :-: | :--- | :--- | :---: |
| 1 | Positive | `0x2987BF71` | `0` |
| 2 | Negative | `0xB38C86DB` | `1` |
| 3 | Boundary (min) | `0x80000000` | `1` |

#### Vector 1: positive value, `instr = 0x2987BF71`

- **Binary:** `0010 1001 1000 0111 1011 1111 0111 0001`
- **I-type:** `instr[31:20] = 0x298` → sign-extended `0x00000298` = **+664**
- **S-type:** `instr[31:25] = 0010100 (0x14)`, `instr[11:7] = 11110 (0x1E)`
  - Concatenated: `0010 1001 1110` = `0x29E`
  - Sign-extended: `0x0000029E` = **+670**

#### Vector 2: negative value, `instr = 0xB38C86DB`

- **Binary:** `1011 0011 1000 1100 1000 0110 1101 1011`
- **I-type:** `instr[31:20] = 0xB38` → sign-extended `0xFFFFFB38` = **−1224**
- **S-type:** `instr[31:25] = 1011001 (0x59)`, `instr[11:7] = 01101 (0x0D)`
  - Concatenated: `1011 0010 1101` = `0xB2D`
  - Sign-extended: `0xFFFFFB2D` = **−1235**

#### Vector 3: most negative immediate, `instr = 0x80000000`

- **12-bit field:** `0x800` → sign-extended `0xFFFFF800` = **−2048**
- This is the smallest 12-bit signed value: `-2^11 = -2048`.

### ⚠️ Failure modes and pitfalls

| Pitfall | What goes wrong |
| :--- | :--- |
| **Zero-extension instead of sign-extension** | Negative immediates (e.g. `-2048`) become large positive values (`+2048`), giving bad memory addresses and wrong branch/jump offsets |
| **Bit transposition in S-type** | The S-type immediate is split across `[31:25]` and `[11:7]`; swapping the fragments or misaligning bit 5 produces wrong store addresses |
| **Range overflow** | A 12-bit signed immediate covers only `[-2048, +2047]`; larger offsets need `LUI` + `ADDI` |

---

## U4 · Computer Organisation

> [!IMPORTANT]
> **P18 works in the Decode (ID) stage.**
> After Fetch (Instruction ROM P30), P18 extracts and sign-extends the immediate **in parallel** with the register-file read (P13) and control decoding (P21, P22, P23).

**Instructions that use P18**

| Output | Instruction group | Instructions | Use of the immediate |
| :--- | :--- | :--- | :--- |
| `imm_i` | Arithmetic / logic | `ADDI`, `SLTI`, `SLTIU`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI` | Second ALU operand |
| `imm_i` | Loads | `LB`, `LH`, `LW`, `LBU`, `LHU` | Signed byte offset added to `rs1` |
| `imm_i` | Indirect jump | `JALR` | Target = `(Reg[rs1] + imm_i) & ~1` |
| `imm_i` | CSR | `CSRRW`, `CSRRS`, `CSRRC` | Bits `[31:20]` give the 12-bit CSR address |
| `imm_s` | Stores | `SB`, `SH`, `SW` | Signed offset added to `rs1` |

---

## U5 · Processors

| Architecture | How it handles immediates |
| :--- | :--- |
| **RISC-V** | Fixed 32-bit formats. The sign bit sits at bit 31 in **every** format (I, S, B, J), so the sign fan-out wiring can start before full decoding finishes |
| **CISC (x86)** | Variable-length instructions (1–15 bytes). Immediates are 8, 16, 32 or 64 bits at varying offsets depending on prefix and opcode bytes, so it needs multi-cycle byte alignment and a sequential length decoder |
| **Mano Basic Computer** | 16-bit machine with only a fixed 12-bit address field (bits 0–11). No general immediate arithmetic, so no immediate generator or sign-extension unit |
| **Stack machine (e.g. JVM)** | Constants are pushed with dedicated bytecodes (`bipush`, `sipush`, `ldc`). ALU ops take operands implicitly from the stack, so no immediate field in arithmetic instructions |
| **GPU (SIMT / SIMD)** | Immediates are uniform constants broadcast to a whole warp/wavefront, or live in constant caches, which keeps instruction words small across thousands of lanes |

---

## U6 · Memory and I/O

P18 takes part in the **effective-address calculation** of every load, store and memory-mapped I/O access.

**Loads** (`LB`, `LH`, `LW`, `LBU`, `LHU`)

```text
P18 -> imm_i -> P20 -> P26 -> ALU (P08)
Effective Address = Reg[rs1] + imm_i
```

**Stores** (`SB`, `SH`, `SW`)

```text
P18 -> imm_s -> P20 -> P26 -> ALU (P08), input B
Effective Address = Reg[rs1] + imm_s
```

**Address routing:** the ALU result goes onto `addr_bus`, and the address decoder **P31** looks at the upper address bits:

| Address range | Target |
| :--- | :--- |
| `0x00000000 – 0x0000FFFF` | Boot ROM (P30) |
| `0x10000000 – 0x10003FFF` | Data RAM (P29) |
| `0x20000000+` | Memory-mapped I/O (UART P41, keyboard P42, timer, interrupt controller, DMA) |

> Without correct sign extension from P18, base-plus-displacement addressing for data memory and peripheral I/O cannot work.

---

# 🔹 Exercises

## E1 · Instruction Trace: `SLTIU`

**Instruction:** `sltiu x5, x6, -1`
**Encoding:** `0xFFF33293` (`rs1 = x6`, `rd = x5`, `imm = 0xFFF = -1`)

### 1) Fetch

| Block | Action |
| :--- | :--- |
| **Program Counter (P14)** | Puts `PC` on the instruction address bus |
| **PC Incrementer (P03)** | Computes `PC + 4` |
| **Instruction ROM (P30)** | Outputs `instr = 0xFFF33293` |

### 2) Decode

| Block | Signals / action |
| :--- | :--- |
| **Field Splitter (P17)** | `opcode = 0010011` (OP-IMM), `rd = 5`, `funct3 = 011` (SLTIU), `rs1 = 6` |
| **Register File (P11–P13)** | Reads `x6` on port 1 → `data_rs1` |
| **Immediate Gen I/S (P18)** | Takes `[31:20] = 0xFFF`, replicates `instr[31] = 1` twenty times → `imm_i = 0xFFFFFFFF` |
| **Control (P21, P22, P24)** | Identifies OP-IMM; `imm_sel` → `imm_i` (P20); `alu_b_sel = 1` (P26); `mem_we = 0`, `mem_re = 0`; `rf_we = 1`; write-back selects ALU result (P25) |
| **ALU Control (P10)** | `opcode = 0010011` + `funct3 = 011` → `ALU_SLTU` |

### 3) Execute

| Block | Action |
| :--- | :--- |
| **Operand Selector (P26)** | ALU A = `data_rs1`, ALU B = `0xFFFFFFFF` |
| **ALU (P01–P08)** | Unsigned compare, shown below |
| **Branch comparator (P09)** | Unused, `branch_taken = 0` |

```text
ALU Result = (unsigned(data_rs1) < unsigned(0xFFFFFFFF)) ? 1 : 0
```

> [!NOTE]
> P18 sign-extends the 12-bit immediate to `0xFFFFFFFF`, but `SLTIU` then treats that 32-bit value as **unsigned** (4,294,967,295). So the result is `1` for every `rs1` except `0xFFFFFFFF`.

### 4) Memory

Inactive (`mem_we = 0`, `mem_re = 0`); P31 and P29 change nothing.

### 5) Write-Back

| Block | Action |
| :--- | :--- |
| **WB Selector (P25)** | Sends ALU result (`0` or `1`) to `rf_wdata` |
| **Register File (P11, P12)** | On the next clock edge writes `rf_wdata` into `x5` |

### 6) Next PC

**P15 / P16** select `PC + 4` from P03, so `PC <- PC + 4`.

---

## E2 · Neighbour Review

| Partner | Role | Integration note | Review link |
| :--- | :--- | :--- | :--- |
| **P17** (Instruction field splitter) | Splits `instr` into opcode `[6:0]`, rd `[11:7]`, funct3 `[14:12]`, rs1 `[19:15]`, rs2 `[24:20]`, funct7 `[31:25]`, csr `[31:20]` | Sits beside P18 in Decode. P17 isolates `rs1`/`rs2` for register reads, while P18 reuses overlapping bit ranges for immediates | [PR #17 comment](https://github.com/campus-sutra/rc-v/pull/17#discussion_r183401201) |
| **P19** (Immediate generator B/J/U) | Builds sign-extended `imm_b`, `imm_j`, `imm_u` for branches, `JAL`, `LUI`, `AUIPC` | Complements P18. Together they supply all five immediates to the selector P20 | [PR #19 comment](https://github.com/campus-sutra/rc-v/pull/19#discussion_r183401305) |

---

## E3 · Where My Block Sits

P18 sits in the **Decode stage of the Datapath layer** of the RC-V processor. It is fed by the 32-bit instruction word `instr` from the Instruction ROM (P30). Its outputs `imm_i` and `imm_s` go to the Immediate Selector P20, which routes the chosen immediate to the ALU Operand Selector P26 and the main ALU P08 for arithmetic and memory address generation.

---

## E4 · Syllabus Map

| Done | Topic |
| :---: | :--- |
| ⬜ | Logic gates, Boolean algebra, K-maps |
| ✅ | Combinational circuits (adders, decoders, encoders, multiplexers) |
| ⬜ | Flip-flops, registers, counters |
| ⬜ | Memory (RAM, ROM) |
| ✅ | Number systems, complements, signed arithmetic |
| ✅ | Bus organisation, instruction codes and formats |
| ✅ | Instruction cycle, hardwired vs microprogrammed control |
| ⬜ | Interrupts and the interrupt cycle |
| ⬜ | Pipelining |
| ✅ | Register organisation, stack, addressing modes |
| ✅ | RISC vs CISC, multicore, GPU |
| ⬜ | Memory hierarchy, cache |
| ⬜ | I/O interface, programmed / interrupt-driven I/O, DMA |
