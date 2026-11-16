# P21 – Opcode Class Decoder Dossier

**Project:** RC-V RISC-V Processor
**Block:** P21 – Opcode Class Decoder
**Syllabus Focus:** Unit 1 – Digital Logic Circuits; Unit 4 – Basic Computer Organisation

---

## U1. Digital Logic

The opcode class decoder is a **combinational logic circuit**. It receives a 32-bit RISC-V instruction and examines bits `instr[6:0]`, which contain the 7-bit opcode. It activates the output corresponding to the instruction class.

### Opcode Table

| Instruction Class | Opcode (Binary) | Opcode (Hex) |
| ----------------- | --------------- | ------------ |
| LUI               | `0110111`       | `0x37`       |
| AUIPC             | `0010111`       | `0x17`       |
| JAL               | `1101111`       | `0x6F`       |
| JALR              | `1100111`       | `0x67`       |
| BRANCH            | `1100011`       | `0x63`       |
| LOAD              | `0000011`       | `0x03`       |
| STORE             | `0100011`       | `0x23`       |
| OP-IMM            | `0010011`       | `0x13`       |
| OP                | `0110011`       | `0x33`       |
| SYSTEM            | `1110011`       | `0x73`       |

### Boolean Expression

For example, the Boolean expression for the LOAD output is:

[
is_load = \overline{i_6},\overline{i_5},\overline{i_4},\overline{i_3},\overline{i_2},i_1,i_0
]

Here, `i6` through `i0` represent `instr[6:0]`.

### Truth Table

| `instr[6:0]`       | `is_load` | `is_opimm` | `is_op` | `is_system` |
| ------------------ | --------: | ---------: | ------: | ----------: |
| `0000011` (LOAD)   |         1 |          0 |       0 |           0 |
| `0010011` (OP-IMM) |         0 |          1 |       0 |           0 |
| `0110011` (OP)     |         0 |          0 |       1 |           0 |
| `1110011` (SYSTEM) |         0 |          0 |       0 |           1 |
| `1100011` (BRANCH) |         0 |          0 |       0 |           0 |

The circuit uses AND gates and inverted inputs to recognise opcode patterns. Comparators with constant values are used for the exact ECALL and MRET instruction matches.

No flip-flops are required because the decoder does not store state. Its outputs depend only on the current instruction input.

---

## U2. Digital Components

The Digital circuit uses the following building blocks:

- **32-bit Input Pin:** Receives the complete instruction.
- **Splitter:** Separates the opcode bits `instr[6:0]` from the instruction.
- **NOT Gates:** Provide the complemented opcode bits needed by the decoding logic.
- **AND Gates:** Combine opcode bits to recognise each instruction class.
- **Comparators:** Identify the exact ECALL (`0x00000073`) and MRET (`0x30200073`) instructions.
- **1-bit Output Pins:** Provide the instruction-class signals.

The opcode bits are connected to the logic gates. Each decoding expression drives its corresponding output.

The ECALL and MRET comparators check the complete 32-bit instruction, while `is_system` identifies the SYSTEM opcode class.

The decoder does not need an adder, register or memory because it only identifies the type of instruction.

---

## U3. Data Representation

The decoder uses the 7-bit opcode field. Three example opcode test vectors are:

| Test Vector | Instruction Class | Binary Opcode | Hex Opcode | Unsigned Decimal |
| ----------- | ----------------- | ------------- | ---------- | ---------------: |
| 1           | OP-IMM            | `0010011`     | `0x13`     |               19 |
| 2           | LOAD              | `0000011`     | `0x03`     |                3 |
| 3           | SYSTEM            | `1110011`     | `0x73`     |              115 |

The opcode is an unsigned bit pattern, so signed interpretation is not needed for these values.

The decoder itself does not perform arithmetic. Therefore, arithmetic overflow does not occur inside this block.

Sign extension is relevant to other processor blocks that process immediate values. For example, an immediate generator must extend the sign bit correctly when an instruction format uses a signed immediate. This is not a function of the opcode class decoder.

---

## U4. Computer Organisation

The opcode class decoder performs its work during the **instruction decode stage**.

1. The Program Counter (PC) provides the address of the next instruction.
2. Instruction memory supplies the 32-bit instruction.
3. The instruction is made available to the decode logic.
4. P21 examines the opcode and activates the matching instruction-class output.
5. The hardwired control unit uses the decoder output to determine the control signals required by the datapath.

### Examples of Instructions

- `ADDI` and `ANDI`: OP-IMM
- `ADD`: OP
- `LW`: LOAD
- `SW`: STORE
- `BEQ`: BRANCH
- `ECALL` and `MRET`: SYSTEM instructions, with separate exact-match outputs

The decoder identifies the instruction class. Other processor blocks carry out the operation.

---

## U5. Processors

Different processor architectures can organise instruction decoding in different ways.

### CISC Processor

CISC architectures may have more complex decoding because instructions can have different lengths, formats and addressing modes. Their decode hardware must interpret those formats.

### Stack Machine

A stack machine decodes stack-oriented instructions and generally obtains operands from the stack instead of using a large set of general-purpose registers in the same way as RISC-V.

### GPU

A GPU also decodes instructions, but its processing architecture is designed to execute many operations in parallel across multiple processing units.

RISC-V uses a regular instruction format for its base 32-bit instructions. This makes opcode-class decoding relatively straightforward.

These are general architectural comparisons; the exact implementation differs between processors.

---

## U6. Memory and I/O

P21 does not directly read from or write to data memory, and it does not directly perform an I/O transfer. It identifies the instruction class and informs the control logic which type of operation is required.

For a LOAD instruction, the control unit coordinates the register file, address-generation datapath and data memory so that the requested value can be read and written back to a register.

For a STORE instruction, the control unit coordinates the address and register data with data memory.

SYSTEM instructions are identified by the SYSTEM opcode. Their exact operation is handled by the relevant control and processor logic.

Therefore, P21 helps classify instructions, while neighbouring blocks perform memory or system operations.

---

## E1. Instruction Trace: ANDI

### Example Instruction

```asm
ANDI x5, x6, 15
```

This instruction performs a bitwise AND between the value in register `x6` and the immediate value `15`, then writes the result to `x5`.

**32-bit Instruction Encoding:** `0x00F37293`

**Binary Encoding:**

```text
00000000111100110111001010010011
```

### Instruction Fields

| Field     | Value     |
| --------- | --------- |
| Opcode    | `0010011` |
| `rd`      | `x5`      |
| `funct3`  | `111`     |
| `rs1`     | `x6`      |
| Immediate | `15`      |

### Expected Instruction Flow

1. **PC:** Supplies the address of the ANDI instruction.
2. **Instruction Memory:** Fetches the instruction.
3. **Instruction Decode Logic:** Receives the 32-bit instruction.
4. **P21 Opcode Class Decoder:** Recognises opcode `0010011` and asserts `is_opimm`.
5. **P22 Hardwired Control Unit:** Uses the instruction class and instruction fields to generate the required control signals.
6. **Register File:** Reads the value in `x6`.
7. **Immediate Generator / P20 Immediate Selector:** Supplies and selects the immediate operand `15`.
8. **ALU:** Performs the bitwise AND operation.
9. **Write-Back Path:** Selects the ALU result and writes it to destination register `x5`.

### Expected P21 Decoder Outputs

| Signal      | Expected Value |
| ----------- | -------------: |
| `is_opimm`  |              1 |
| `is_op`     |              0 |
| `is_load`   |              0 |
| `is_store`  |              0 |
| `is_branch` |              0 |
| `is_system` |              0 |
| `is_ecall`  |              0 |
| `is_mret`   |              0 |

These are the expected P21 classification results for this instruction.

The actual register values and control-signal names and values must be copied from the RC-V simulator's `--trace` output.

### Actual Simulator Trace

**Note:** Complete this part after running the instruction in the RC-V simulator.

| Trace Item / Signal  | Actual Value from Simulator       |
| -------------------- | --------------------------------- |
| PC                   | TODO                              |
| Instruction          | `0x00F37293` (confirm from trace) |
| Opcode               | `0010011`                         |
| `is_opimm`           | `1`                               |
| Register `x6` Value  | TODO                              |
| Immediate Value      | `15`                              |
| ALU Operation        | AND                               |
| ALU Result           | TODO                              |
| Destination Register | `x5`                              |
| Write-Back Value     | TODO                              |

**Paste the relevant `--trace` output below:**

```text
TODO: Paste the simulator trace for ANDI here.
```

---

## E2. Review P20 and P22 Pull Requests


- P20 review: TODO — 
- P22 review: TODO — 

---

## E3. Where My Block Sits

My opcode class decoder belongs to the combinational logic part of the processor's instruction-decode path.

It receives the 32-bit instruction from the instruction-fetch/decode path, examines the opcode bits and sends instruction-class outputs to the hardwired control unit.

The control unit then uses this information to coordinate the datapath and other processor blocks.

---

## E4. Syllabus Map

The following topics are relevant to the P21 decoder and the explanations in this dossier.

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA

---

