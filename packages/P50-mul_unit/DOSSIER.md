# P50 Multiplier (shift and add) - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
One key combinational part of the control unit is the `load` signal generator, which starts a new multiplication only when the unit is not busy (`busy = 0`) and `start = 1`.

**Truth Table for `load`:**

| `busy` | `start` | `load` |
| :---: | :---: | :---: |
| 0 | 0 | 0 |
| 0 | 1 | 1 |
| 1 | 0 | 0 |
| 1 | 1 | 0 |

- **Simplified Boolean Expression:** $\text{load} = \overline{\text{busy}} \cdot \text{start}$
- **Gates & Flip-Flops used:** A `NOT` gate and an `AND` gate for `load`; `NOT` gates and comparators for state decoding (`cnt == 0`, `cnt == 4`); and D flip-flops inside the registers (`CNT`, `REG_A`, `REG_B`, `ACC`).

## U2 Digital components
The Digital circuit (`P50.dig`) uses the following building blocks:
- **Registers:** A 3-bit counter register (`CNT`) to track cycles, a 4-bit shift-right register (`REG_B`) for the multiplier, an 8-bit shift-left register (`REG_A`) for the multiplicand, and an 8-bit accumulator (`ACC`) to hold the running product.
- **Adders:** A 3-bit adder (`CNT + 1`) to increment the cycle count and an 8-bit adder (`ACC + REG_A`) to accumulate partial products.
- **Multiplexers:** 2-to-1 MUXes select between `0` and `REG_A` (controlled by `b_lsb`), load vs. shift paths for `REG_A`/`REG_B`, and reset/load/run states for `ACC` and `CNT`.
- **Comparators & Splitters:** Comparators check `cnt == 0` (to derive `busy`) and `cnt == 4` (to signal `done`), while splitters extract `b[0]` (`b_lsb`) and perform bit-shifting by wiring.

## U3 Data representation
Three test vectors from the circuit/module:

1. **Vector 1 (`7 * 4 = 28`):**
   - `a = 7` (`0b0111` / `0x7`), `b = 4` (`0b0100` / `0x4`)
   - `result = 28` (`0b00011100` / `0x1C`, unsigned & signed decimal: `28`).
2. **Vector 2 (`15 * 13 = 195`):**
   - `a = 15` (`0b1111` / `0xF`), `b = 13` (`0b1101` / `0xD`)
   - `result = 195` (`0b11000011` / `0xC3`, unsigned decimal: `195`, signed 8-bit two's complement: `-61`).
3. **Vector 3 (`15 * 9 = 135`):**
   - `a = 15` (`0b1111` / `0xF`), `b = 9` (`0b1001` / `0x9`)
   - `result = 135` (`0b10000111` / `0x87`, unsigned decimal: `135`, signed 8-bit two's complement: `-121`).

- **Overflow & Sign Extension Risks:** An unsigned $n \times n$ multiplication requires $2n$ bits ($4 \times 4 \rightarrow 8$ bits; $32 \times 32 \rightarrow 64$ bits). In the 32-bit Verilog module, only the lower 32 bits (`prod_acc[31:0]`) are returned in `MUL_RESULT`, so products exceeding $2^{32}-1$ (or outside $[-2^{31}, 2^{31}-1]$ in signed arithmetic) overflow/truncate. Additionally, because shift-and-add shifts in `0`s from the MSB (unsigned shift), negative two's complement inputs would produce wrong results unless sign-extended to $2n$ bits before multiplication.

## U4 Computer organisation
Since the P50 multiplier is a memory-mapped I/O peripheral rather than an internal ALU functional unit, it does its work asynchronously over 32 clock cycles *after* the CPU executes store instructions during the **Memory (MEM)** stage:
- **`sw` (Store Word):** Used during the MEM stage to write operands into `MUL_A` (`0x00020200`) and `MUL_B` (`0x00020204`), and to write `1` to `MUL_CTRL` (`0x00020208`) to trigger the operation.
- **`lw` (Load Word):** Used during the MEM stage to poll `MUL_STATUS` (`0x0002020C`) until `busy == 0`, and then read the final product from `MUL_RESULT` (`0x00020210`).

## U5 Processors
- **CISC Processor (e.g., x86 or Mano's basic computer with hardware multiply):** Instead of a memory-mapped peripheral requiring multiple `sw`/`lw` polling instructions, a CISC processor provides a dedicated `MUL` instruction (often supporting memory operands directly) where microcode or a multi-cycle internal execution unit stalls the pipeline and places the result straight into architectural registers.
- **Stack Machine (e.g., JVM):** Operands `A` and `B` are pushed onto the operand stack; a single zero-operand `IMUL` instruction pops the top two values, multiplies them, and pushes the product back onto the stack without needing register specifiers or MMIO addresses.
- **GPU:** A GPU executes thousands of multiplications in parallel across SIMD/SIMT lanes (warps/wavefronts) using dedicated hardware multiplier arrays (FMA units), hiding latency through massive thread-level parallelism rather than single-threaded polling.

## U6 Memory and I/O
The P50 multiplier directly participates in **Memory-Mapped I/O (MMIO)** transfers at **Slot 8** (`0x00020200` – `0x0002021F`):
- When the CPU executes a load/store targeting `0x000202xx`, the **Address Decoder / Bus Interconnect** asserts the `sel` signal for slot 8 and passes the register index `ridx = addr[5:2]`.
- On a write (`sel && we`), data travels from the CPU's write-data bus (`wdata`) into `reg_a`, `reg_b`, or triggers `busy` via `ridx == 4'h2`.
- On a read (`sel && re`), the block drives `rdata` with `busy` (`ridx == 4'h3`), `reg_result` (`ridx == 4'h4`), or the package ID `0x32` (`ridx == 4'hf`) back onto the CPU read bus.

## E1 Instruction trace: BLTU
Tracing `BLTU rs1, rs2, offset` (B-type, `opcode = 1100011`, `funct3 = 110`) through RC-V:
1. **Fetch (IF):** `PC` addresses **Instruction Memory**, fetching the 32-bit `BLTU` instruction word. `PC + 4` is computed in parallel.
2. **Decode (ID):** **Instruction Decoder** extracts `rs1`, `rs2`, `funct3 = 3'b110`, and sign-extends the 13-bit B-immediate (`imm_b`). **Register File** outputs `rdata1 = R[rs1]` and `rdata2 = R[rs2]`. Control signals set `branch = 1`, `alu_src = 0`, `mem_read = 0`, `mem_write = 0`, `reg_write = 0`.
3. **Execute (EX):** **ALU / Branch Comparator** performs an unsigned comparison (`R[rs1] < R[rs2]` unsigned). If true, `branch_taken = 1` and the **Branch Adder** computes `target_pc = PC + imm_b`; otherwise `branch_taken = 0` and `next_pc = PC + 4`.
4. **Memory (MEM):** Idle (`mem_read = 0`, `mem_write = 0`); `next_pc` is selected via the PC multiplexer to update `PC` on the next clock edge.
5. **Write-Back (WB):** Idle (`reg_write = 0`); no destination register `rd` is modified.

## E2 Neighbour review
- **P49 (Performance counters) PR review:** Checked `campus-sutra/rc-v` Pull Requests for P49; pending open PR submission by neighbour (will add direct review comment link once opened).
- **P51 (Four-lane vector unit / mini GPU) PR review:** Checked `campus-sutra/rc-v` Pull Requests for P51; pending open PR submission by neighbour (will add direct review comment link once opened).

## E3 Where my block sits
The P50 multiplier sits in the **I/O layer** as a memory-mapped peripheral attached to the system data/address bus at slot 8 (`0x00020200`). The CPU's **load/store unit and address decoder** feed it control signals (`sel`, `we`, `re`, `ridx`) and operands (`wdata`), while its outputs (`rdata` carrying status and product) are read back by the **CPU register file** via the memory read bus.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 3, Unit 5).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
