# P50 Multiplier (shift and add) - dossier

## U1 Digital logic

The multiplier uses an AND operation to check the least significant
bit of the multiplier.

If the current multiplier bit is 1, the multiplicand is added to
the accumulator. If it is 0, the accumulator remains unchanged.

Boolean expression:

S = Q0 · M

Here, Q0 is the least significant multiplier bit and M represents
the condition to add the multiplicand.

The circuit uses registers, an adder and control logic.

## U2 Digital components

The circuit uses an accumulator, a multiplicand shift register,
a multiplier shift register and an adder.

The multiplier register shifts right by one bit after every cycle.
The multiplicand register shifts left by one bit. The adder adds
the multiplicand to the accumulator when the current multiplier
bit is 1.

A counter tracks the number of multiplication cycles. The busy
signal indicates whether the operation is in progress.

## U3 Data representation

Test vector 1:
A = 7, B = 4
Binary: 0111 × 0100
Hexadecimal: 0x7 × 0x4
Decimal result: 28

Test vector 2:
A = 8, B = 9
Binary: 1000 × 1001
Hexadecimal: 0x8 × 0x9
Decimal result: 72

Test vector 3:
A = 1234, B = -56
Decimal result: -69104

Signed multiplication must correctly handle negative operands.
Overflow can occur if the product is stored in too few bits.
Sign extension must also be handled correctly when converting
between signed and wider values.

## U4 Computer organisation

The multiplier is a memory-mapped I/O device. The processor
communicates with it using load and store instructions.

The processor writes the operands and the start command to the
device. The multiplier performs its work independently while the
processor checks the busy flag.

The device is not a normal ALU instruction. It is accessed through
the memory and I/O system.

## U5 Processors

A CISC processor may provide a multiplication instruction that
performs multiplication internally.

A stack machine could take operands from the stack and push the
result back onto it.

A GPU can perform many independent multiplications in parallel
using multiple processing lanes.

The P50 unit performs multiplication iteratively using shift and
add operations.

## U6 Memory and I/O

P50 uses memory-mapped I/O. Its registers are mapped to addresses
in the I/O address range.

The processor writes A, B and CTRL using store instructions.
It reads STATUS and RESULT using load instructions.

The address decoder and I/O bus select the multiplier device and
transfer data between the processor and the device.

## E1 Instruction trace: BLTU

BLTU performs an unsigned comparison between two registers.

The instruction is fetched from instruction ROM using the
program counter. The instruction fields are decoded by the
instruction decoder.

The register file supplies rs1 and rs2. The branch comparator
(P09) checks whether rs1 is unsigned-less-than rs2.

The branch target adder (P02) calculates the target address.
The next-PC logic (P16) selects either the branch target or PC+4.
The PC (P14) receives the selected next address.

The branch is taken when rs1 < rs2 using unsigned comparison.

Actual signal values should be added from the simulator's
--trace output.

## E2 Neighbour review

P49 - Performance counters:
Review link: [ADD YOUR P49 REVIEW LINK]

P51 - Four-lane vector unit:
Review link: [ADD YOUR P51 REVIEW LINK]

## E3 Where my block sits

P50 belongs to the I/O device layer of the computer.
It receives operands and control signals through the I/O bus.
The processor writes its input registers and reads its status
and result registers.

## E4 Syllabus map

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [x] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
