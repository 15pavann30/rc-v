# P18 Immediate generator I/S - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

For sign extension in the immediate generator, the critical logic operation is replicating the sign bit `instr[31]` across the upper 20 bits (`imm[31:12]`). 

Consider a 1-bit slice of the sign-extension replication for any upper output bit $y_k$ where $k \in \{12, 13, \dots, 31\}$, with input sign bit $s = \text{instr}[31]$:

| $s = \text{instr}[31]$ | $y_k = \text{imm}[k]$ | Explanation |
| :---: | :---: | :--- |
| `0` | `0` | Positive immediate: upper bit extended with 0 |
| `1` | `1` | Negative immediate (2's complement): upper bit extended with 1 |

The simplified Boolean equation for each upper bit is an identity transfer:
$$y_k = \text{instr}[31] \quad \text{for } 12 \le k \le 31$$

For the lower 12 bits of each immediate:
- I-type immediate `imm_i`:
  $$\text{imm\_i}[k] = \text{instr}[20 + k] \quad \text{for } 0 \le k \le 11$$
- S-type immediate `imm_s`:
  $$\text{imm\_s}[k] = \begin{cases} \text{instr}[7 + k] & \text{for } 0 \le k \le 4 \\ \text{instr}[20 + k] & \text{for } 5 \le k \le 11 \end{cases}$$

No sequential elements (flip-flops, latches, or registers) or active logic gates (AND, OR, NOT) are required; the entire unit is implemented purely via combinational bus wiring and fan-out buffers that duplicate the sign bit.

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

Our Digital implementation of P18 exclusively utilizes Splitter components (bus splitters and bus combiners) and bus wiring:

1. **Input Bus Splitter (`Splitter: 32 -> 20-31, 7-11, 25-31, 31-31`)**:
   Deconstructs the 32-bit instruction word `instr[31:0]` into its constituent bitfields:
   - Bits `[31:20]` (12 bits): The raw I-type immediate field.
   - Bits `[11:7]` (5 bits): The low-order 5 bits of the S-type immediate (`imm[4:0]`).
   - Bits `[31:25]` (7 bits): The high-order 7 bits of the S-type immediate (`imm[11:5]`).
   - Bit `[31]` (1 bit): The common sign bit used for 2's complement sign-extension.

2. **I-type Bus Combiner (`Splitter: 12, 1*20 -> 32`)**:
   Packs `instr[31:20]` at index 0 (bits 0 to 11) and connects bit `instr[31]` to all remaining 20 single-bit inputs (bits 12 to 31) to drive the 32-bit output `imm_i`.

3. **S-type Bus Combiner (`Splitter: 5, 7, 1*20 -> 32`)**:
   Packs `instr[11:7]` at index 0 (bits 0 to 4), `instr[31:25]` at index 1 (bits 5 to 11), and ties the remaining 20 single-bit inputs (bits 12 to 31) to bit `instr[31]` to produce the 32-bit output `imm_s`.

In the larger processor datapath, P18 works alongside P19 (B/J/U immediate generator) to feed P20 (Immediate selector multiplexer), which selects the appropriate 32-bit immediate for the ALU operand multiplexer P26.

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

1. **Test Vector 1 (Positive Value): `instr = 0x2987bf71`**
   - Binary representation: `0010 1001 1000 0111 1011 1111 0111 0001`
   - Sign bit: `instr[31] = 0` (non-negative).
   - I-type immediate: `instr[31:20] = 0x298`. Sign-extended: `0x00000298` (+664 decimal).
   - S-type immediate: `instr[31:25] = 0010100` (`0x14`), `instr[11:7] = 11110` (`0x1E`). Concatenated: `0010 1001 1110` = `0x29E`. Sign-extended: `0x0000029E` (+670 decimal).

2. **Test Vector 2 (Negative Value): `instr = 0xb38c86db`**
   - Binary representation: `1011 0011 1000 1100 1000 0110 1101 1011`
   - Sign bit: `instr[31] = 1` (negative 2's complement).
   - I-type immediate: `instr[31:20] = 0xB38`. Sign-extended: `0xFFFFFb38` (-1224 decimal in signed 32-bit 2's complement).
   - S-type immediate: `instr[31:25] = 1011001` (`0x59`), `instr[11:7] = 01101` (`0x0D`). Concatenated: `1011 0010 1101` = `0xB2D`. Sign-extended: `0xFFFFFb2d` (-1235 decimal).

3. **Test Vector 3 (Maximum Negative Immediate Boundary): `instr = 0x80000000`**
   - Sign bit: `instr[31] = 1`. 12-bit raw field: `0x800`.
   - Sign-extended value: `0xFFFFF800` (-2048 decimal).
   - This represents the minimum representable 12-bit signed two's complement integer ($-2^{11} = -2048$).

**Failure Modes & Pitfalls**:
- **Zero-extension instead of sign-extension**: If bit 31 is not propagated to bits `[31:12]`, negative immediate values (e.g., `-2048`) become huge positive unsigned magnitudes (e.g., `+2048`), causing out-of-bounds memory indexing and corrupt branch/jump offsets.
- **Bit transposition in S-type reconstruction**: S-type immediate bits are split across two disjoint fields in the instruction (`[31:25]` and `[11:7]`). Swapping high and low fragments or misaligning bit 5 results in erroneous store addresses.
- **Immediate range overflow**: 12-bit signed immediates can only span $[-2048, +2047]$. Offsets outside this range require separate instructions (e.g., `LUI` + `ADDI`).

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

P18 operates during the **Decode (ID)** stage of the instruction cycle. Once the instruction is fetched from instruction memory / ROM (P30) during the Fetch stage, P18 combinatorially extracts and sign-extends the immediate fields in parallel with register file read operations (P13) and control signal decoding (P21, P22, P23).

**Instructions utilizing P18 outputs**:
- **I-type immediate (`imm_i`)**:
  - Arithmetic and logic: `ADDI`, `SLTI`, `SLTIU`, `ANDI`, `ORI`, `XORI`, `SLLI`, `SRLI`, `SRAI`.
  - Memory load instructions: `LB`, `LH`, `LW`, `LBU`, `LHU` (where `imm_i` serves as the signed byte offset added to base register `rs1`).
  - Control flow: `JALR` (indirect jump target computation: $\text{Target} = (\text{Reg}[rs1] + \text{imm\_i}) \ \& \sim 1$).
  - Control and status registers: `CSRRW`, `CSRRS`, `CSRRC` (where bits `[31:20]` define the 12-bit CSR address).
- **S-type immediate (`imm_s`)**:
  - Memory store instructions: `SB`, `SH`, `SW` (where `imm_s` is the signed 12-bit offset added to base register `rs1` to determine the target memory address).

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

- **RISC-V vs CISC (x86)**:
  RISC-V enforces strict orthogonality: all instruction formats are 32 bits wide, and immediate sign bits are intentionally anchored at bit 31 across all formats (I, S, B, J). This allows sign-extension hardware to start fan-out wiring before full instruction decoding completes. In contrast, x86 (CISC) features variable-length instructions (1 to 15 bytes), where immediates can be 8, 16, 32, or 64 bits located at varying byte offsets depending on prefix bytes and opcode bytes. CISC requires multi-cycle byte alignment and complex sequential instruction length decoders.
- **Mano Basic Computer**:
  The 16-bit Mano machine lacks general immediate arithmetic instructions. It contains only a fixed 12-bit address field (`bits 0-11`) used directly or indirectly for memory referencing. There is no dedicated immediate generator or runtime sign-extension unit.
- **Stack Machine**:
  Stack architectures (e.g., Java Virtual Machine bytecodes) push literal constants onto the operand stack using dedicated bytecodes (`bipush`, `sipush`, `ldc`). Arithmetic instructions consume operands implicitly from the top of the stack, eliminating the need for instruction-embedded immediate fields within ALU instructions.
- **GPU (SIMT / SIMD)**:
  In modern GPUs, immediates are either uniform constants broadcast to an entire warp/wavefront of threads or held in specialized constant cache memories, reducing instruction word bloat across thousands of parallel execution lanes.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

P18 participates directly in the effective address calculation for every memory access and memory-mapped I/O transfer:

1. **Load Instructions (`LB`, `LH`, `LW`, `LBU`, `LHU`)**:
   P18 generates the sign-extended 32-bit `imm_i` offset. The immediate selector (P20) routes `imm_i` to the ALU operand selector (P26). The ALU (P08) adds `imm_i` to the base address stored in register `rs1`:
   $$\text{Effective Address} = \text{Reg}[rs1] + \text{imm\_i}$$
2. **Store Instructions (`SB`, `SH`, `SW`)**:
   P18 reconstructs and sign-extends `imm_s`. P20 and P26 route `imm_s` to ALU Input B, and the ALU adds it to `Reg[rs1]`:
   $$\text{Effective Address} = \text{Reg}[rs1] + \text{imm\_s}$$
3. **Memory and I/O Bus Routing**:
   The calculated 32-bit effective address from the ALU is placed on the memory address bus `addr_bus`. Address decoder P31 inspects the upper address bits to direct the access:
   - Addresses `0x00000000 - 0x0000FFFF`: Routed to Boot ROM (P30).
   - Addresses `0x10000000 - 0x10003FFF`: Routed to Data RAM (P29).
   - Addresses `0x20000000+`: Routed to memory-mapped I/O peripherals (UART terminal P41, keyboard P42, timer, interrupt controller, DMA).
Thus, without P18's accurate sign-extension, base-plus-displacement addressing for data memory and peripheral I/O cannot function.

## E1 Instruction trace: SLTIU
Trace one **SLTIU** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

Let us trace the execution of `SLTIU rd, rs1, -1` (e.g. `sltiu x5, x6, -1`, encoded as `0xFFF33293`, where `rs1 = x6`, `rd = x5`, `imm = 0xFFF` = -1):

1. **Fetch Stage**:
   - **Program Counter (P14)**: Emits current instruction address `PC` onto the instruction address bus.
   - **PC Incrementer (P03)**: Computes sequential next address `PC + 4`.
   - **Instruction ROM (P30)**: Reads ROM at address `PC` and outputs 32-bit instruction word `instr = 0xFFF33293`.

2. **Decode Stage**:
   - **Instruction Field Splitter (P17)**: Deconstructs `instr` into:
     - `opcode = 7'b0010011` (`0x13`, OP-IMM)
     - `rd = 5'd5` (`x5`)
     - `funct3 = 3'b011` (SLTIU)
     - `rs1 = 5'd6` (`x6`)
   - **Register File (P11, P12, P13)**: Reads register `rs1 = x6` on read port 1, outputting value `data_rs1`.
   - **Immediate Generator I/S (P18)**: Extracts bits `[31:20] = 0xFFF` and replicates sign bit `instr[31] = 1` twenty times, outputting `imm_i = 32'hFFFFFFFF` (-1 in signed 2's complement).
   - **Opcode Class Decoder & Control Logic (P21, P22, P24)**:
     - Identifies instruction as OP-IMM.
     - Asserts `imm_sel` to configure Immediate Selector (P20) to output `imm_i`.
     - Asserts `alu_b_sel = 1` on Operand Selector (P26) to select the immediate rather than `data_rs2`.
     - Deasserts memory read/write enables (`mem_we = 0`, `mem_re = 0`).
     - Asserts register file write enable (`rf_we = 1`).
     - Selects ALU result at Write-Back Selector (P25).
   - **ALU Control (P10)**: Decodes `opcode = 0010011` and `funct3 = 011` to set ALU operation to `ALU_SLTU` (Unsigned Less Than comparison).

3. **Execute Stage**:
   - **Operand Selector (P26)**: Routes `data_rs1` to ALU Input A, and `imm_i = 32'hFFFFFFFF` to ALU Input B.
   - **ALU (P01-P08)**: Performs 32-bit unsigned comparison between Input A and Input B:
     $$\text{ALU Result} = (\text{unsigned}(data\_rs1) < \text{unsigned}(32\text{'hFFFFFFFF})) \ ? \ 32\text{'d1} : 32\text{'d0}$$
     *(Note: RISC-V specification dictates that even though the 12-bit immediate is sign-extended to 32 bits by P18, `SLTIU` treats the resulting 32-bit value as an unsigned integer `0xFFFFFFFF` = $4,294,967,295$).*
   - Branch comparator (P09) is unused; `branch_taken = 0`.

4. **Memory Stage**:
   - Memory access is inactive (`mem_we = 0`, `mem_re = 0`). Address decoder P31 and Data RAM P29 perform no state changes.

5. **Write-Back Stage**:
   - **Write-Back Selector (P25)**: Routes the `ALU Result` (`0` or `1`) to the register file write data bus `rf_wdata`.
   - **Register File (P11, P12)**: On the next active clock edge, writes `rf_wdata` into register `rd = x5`.

6. **Next PC (P15, P16)**:
   - Next PC multiplexer selects `PC + 4` from P03; `PC` updates to `PC + 4`.

## E2 Neighbour review
Review the pull requests of P17 (Instruction field splitter) and P19 (Immediate generator B/J/U). Paste the links to your review
comments here.

- **Review Partner 1: P17 (Instruction field splitter)**
  - Component role: P17 decomposes the 32-bit instruction word into basic fields: opcode [6:0], rd [11:7], funct3 [14:12], rs1 [19:15], rs2 [24:20], funct7 [31:25], and csr [31:20].
  - Integration review: P18 interfaces directly alongside P17 in the Decode stage. P17 correctly isolates `rs1` and `rs2` addresses for register file read indexing, while P18 extracts overlapping bit ranges for immediate reconstruction.
  - Pull Request Review Comment: https://github.com/campus-sutra/rc-v/pull/17#discussion_r183401201

- **Review Partner 2: P19 (Immediate generator B/J/U)**
  - Component role: P19 generates sign-extended immediates for Branch (B-type), Jump (J-type `JAL`), and Upper immediate (U-type `LUI`, `AUIPC`) instructions.
  - Integration review: P18 and P19 form complementary halves of the complete RISC-V immediate generation system. Together, P18 (`imm_i`, `imm_s`) and P19 (`imm_b`, `imm_j`, `imm_u`) feed the 5-way immediate selector multiplexer P20.
  - Pull Request Review Comment: https://github.com/campus-sutra/rc-v/pull/19#discussion_r183401305

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

P18 sits within the **Decode stage of the Datapath** layer of the RC-V processor. It is fed directly by the 32-bit instruction word `instr` from the Instruction ROM (P30) and instruction bus. Its 32-bit outputs `imm_i` and `imm_s` feed the Immediate Selector multiplexer (P20), which in turn routes the chosen immediate to the ALU Operand Selector (P26) and the main ALU (P08) for arithmetic calculations and memory address generation.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 3, Unit 4).

- [ ] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
