# P04 ALU logic unit - dossier

Answer in your own words; short answers are fine. Diagrams can be photos of
hand drawings (put them next to this file and link them).

## U1 Digital logic
Give the truth table (or state table) of one part of your circuit and the
simplified Boolean expression you used. Which gates or flip-flops did you need?

I used three gates: AND (y = a·b), OR (y = a+b) and XOR (y = a⊕b). The multiplexer picks one result using op. No flip-flops were needed because the circuit has no memory; the output depends only on the current inputs.

| a | b | AND | OR | XOR |
|---|---|-----|----|-----|
| 0 | 0 | 0 | 0 | 0 |
| 0 | 1 | 0 | 1 | 1 |
| 1 | 0 | 0 | 1 | 1 |
| 1 | 1 | 1 | 1 | 0 |

## U2 Digital components
Which building blocks (adders, multiplexers, decoders, registers, memory)
does your Digital circuit use, and how are they connected?

The circuit uses AND, OR and XOR gates and one 4-to-1 multiplexer, repeated for each of the 4 bits. Inputs a and b go into all three gates at the same time. The three gate outputs go into multiplexer inputs 0, 1 and 2. Input 3 is tied to 0. The 2-bit op signal is the multiplexer's select line, and the multiplexer output is y.

| Block | How many | Connected to |
|---|---|---|
| AND gate | 1 (4 bits wide) | inputs a and b, output to mux input 0 |
| OR gate | 1 (4 bits wide) | inputs a and b, output to mux input 1 |
| XOR gate | 1 (4 bits wide) | inputs a and b, output to mux input 2 |
| Constant 0 | 1 | mux input 3 |
| 4-to-1 multiplexer | 1 (4 bits wide) | select = op, output = y |

## U3 Data representation
Pick three test vectors of your block and explain them in binary, hex and
decimal (signed where it matters). Where could overflow or sign extension go wrong?

Test vectors with a = 1100 (hex C) and b = 1010 (hex A):

| op | Operation | Result (binary) | Hex | Unsigned | Signed |
|---|---|---|---|---|---|
| 0 | AND | 1000 | 8 | 8 | -8 |
| 1 | OR | 1110 | E | 14 | -2 |
| 2 | XOR | 0110 | 6 | 6 | 6 |

Overflow cannot happen, because AND, OR and XOR work on each bit separately with no carry. Sign extension is also not a problem, because the same bit pattern is produced whether the numbers are signed or unsigned.

## U4 Computer organisation
In which step of the instruction cycle (fetch, decode, execute, memory,
write-back, interrupt) does your block do its work? Which instructions need it?

My block works in the execute step. Fetch and decode only read the instruction and select the operation (op). In execute the ALU logic unit computes the result. Instructions that need it: AND, OR, XOR and the immediate forms ANDI, ORI, XORI.

## U5 Processors
How would a CISC processor, a stack machine or a GPU do the job of your
block differently? (Look at the RISC-V vs Mano comparison in docs/ARCHITECTURE.md.)

A CISC processor could do the logic operation straight on a memory operand, so one instruction would load, AND and store. A stack machine has no register names: it pops two values from the stack, ANDs them and pushes the result. A GPU would do the same AND on many lanes at the same time, instead of one 32-bit value per instruction.

## U6 Memory and I/O
How does your block take part in a memory access or an I/O transfer? If it
does not, explain which neighbouring block does and how data reaches it.

My block does not touch memory or I/O. It only works on register values. The register-file read port (P13) and the ALU operand selector (P26) deliver a and b to it. The result goes out through the ALU result selector (P08) and the write-back selector (P25) into the register file.

## E1 Instruction trace: JALR
Trace one **JALR** instruction through the whole RC-V processor,
block by block (use docs/ARCHITECTURE.md and the simulator's --trace output).
List the blocks it passes through and the value on the main signals.

## E2 Neighbour review
Review the pull requests of P03 (PC incrementer) and P05 (Left barrel shifter). Paste the links to your review
comments here.

## E3 Where my block sits
In two or three sentences: which layer of the computer is your block in
(gates / components / datapath / control / instruction set / memory / I/O),
which blocks feed it and which blocks use its output?

My block is in the datapath layer. It is fed by the register-file read port (P13) and the ALU operand selector (P26), which give it a and b, and by the ALU control (P10), which gives it op. Its output goes to the ALU result selector (P08), which chooses between my result and the other ALU results before write-back.

## E4 Syllabus map
Tick every syllabus topic your work touched (main units: Unit 1, Unit 2).

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [ ] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [ ] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [ ] I/O interface, programmed / interrupt-driven I/O, DMA
