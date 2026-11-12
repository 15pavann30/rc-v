# P06 Right barrel shifter - dossier

## U1 Digital logic

A 2-to-1 multiplexer selects one of two data inputs. For each output bit,
y = (select AND d1) OR (NOT select AND d0). When select is 0, the
output is d0; when select is 1, the output is d1. The shifter is combinational,
so it needs no flip-flops or clock.

For arithmetic right shift, the fill bit is a[31] AND arith. For logical
right shift, arith=0 makes the fill bit zero.

| select | d0 | d1 | y |
|---:|---:|---:|---:|
| 0 | 0 | 0 | 0 |
| 0 | 0 | 1 | 0 |
| 0 | 1 | 0 | 1 |
| 0 | 1 | 1 | 1 |
| 1 | 0 | 0 | 0 |
| 1 | 0 | 1 | 1 |
| 1 | 1 | 0 | 0 |
| 1 | 1 | 1 | 1 |

## U2 Digital components

The 8-bit Digital circuit uses three cascaded 2-to-1 multiplexer stages,
controlled by sh[0], sh[1] and sh[2], for shifts of 1, 2 and 4 positions.
The 32-bit Verilog module uses five stages for shifts of 1, 2, 4, 8 and 16.
The fill input is selected from the sign bit in arithmetic mode, or zero in
logical mode.

## U3 Data representation

Examples for the 32-bit Verilog block:

1. Logical: a=0x00000010 (16), sh=2, arith=0 gives y=0x00000004 (4).
2. Logical: a=0x80000000 (unsigned 2147483648), sh=1, arith=0 gives
   y=0x40000000 (1073741824).
3. Arithmetic: a=0x80000000 (signed -2147483648), sh=1, arith=1 gives
   y=0xC0000000 (signed -1073741824).

A common error is filling the left side with zeros during an arithmetic shift;
that loses the sign. Another is using the wrong shift-control bit at a stage.

## U4 Computer organisation

The shifter works in the execute stage as part of the ALU datapath. RISC-V
right-shift instructions use it: SRL/SRLI shift in zeros, while SRA/SRAI
replicate the sign bit. The ALU control selects the operation.

## U5 Processors

A CISC processor may implement a shift as a complex instruction using its
own datapath and control. A stack machine would take operands from the stack
rather than a register file. A GPU can apply a similar shift operation in
parallel to many data lanes (SIMD/SIMT).

## U6 Memory and I/O

The barrel shifter does not directly read or write memory or I/O. It operates
on values in the processor datapath. For a load or store, the ALU and memory
interface handle the address and data transfer; the shifter is used when an
instruction requests a shift operation.

## E1 Instruction trace: BNE (not taken)

A BNE compares rs1 and rs2 in the branch comparator (P09). Since the branch
condition is false, the next-PC logic selects PC+4 rather than the branch
target. At a high level the instruction passes through:

1. Fetch: P14 supplies the PC and P30 reads the instruction ROM.
2. Decode: P17 extracts instruction fields; P21 classifies the opcode;
   P22/P23 generate control; P24 selects/checks control; P13 reads registers.
3. Execute: P09 compares the two register values; P02 can calculate the
   branch target; P03 calculates PC+4; P16 selects the sequential PC because
   BNE is not taken; P15 supplies the next PC.
4. Memory and write-back: no data-memory access and no general-register
   write-back are required for BNE.

The exact signal values depend on the particular BNE instruction address and
the values in rs1 and rs2; record those from the simulator trace when you run
the assigned trace.

## E2 Neighbour review

Review partners: P05 (Left barrel shifter) and P07 (Less-than unit, signed
and unsigned). Add one constructive review comment to each partner's pull
request, then paste both actual review URLs here. Do not invent review links.

- P05 review URL: TODO
- P07 review URL: TODO

## E3 Where my block sits

The right barrel shifter is a combinational datapath component inside the ALU
execution path. It receives a value from the operand-selection logic and shift
control from ALU control, then sends the shifted result to the ALU result path.

## E4 Syllabus map

- [x] Logic gates, Boolean algebra, K-maps
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
