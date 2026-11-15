# P50 Multiplier (shift and add) - dossier

## U1 Digital logic

I took the control part of my multiplier (the `busy` flag). Inputs: `start`, `busy` (current state) and `last` (counter = 3, the last cycle).

| start | busy | last | action | busy next |
|---|---|---|---|---|
| 0 | 0 | x | idle | 0 |
| 1 | 0 | x | load A and B, clear accumulator | 1 |
| x | 1 | 0 | add-and-shift | 1 |
| x | 1 | 1 | last add-and-shift | 0 |

(A `start` while `busy = 1` is ignored.)

Simplified:

- `load = start AND (NOT busy)`
- `busy_next = load OR (busy AND (NOT last))`

The data part uses the same idea: `acc_next = acc + (b[0] ? mcand : 0)`, so one AND per bit of the adder input (or a multiplexer with 0 as the second input).

Needed: AND, OR and NOT gates, a D flip-flop for `busy`, a 2-bit counter made of flip-flops (a half adder on each bit) and a comparator or AND gate to detect counter = 3.

## U2 Digital components

- **Registers:** `MCAND` (8 bit, shifts left), `MPLIER` (4 bit, shifts right), `ACC` (8 bit, this is `result`), `CNT` (2 bit) and the `busy` flip-flop.
- **Adder:** one 8-bit adder computes `ACC + MCAND`.
- **Multiplexers:** a 2-to-1 multiplexer in front of each register chooses between "load" (A, B, 0) and "run" (shifted value or sum). Another one chooses `ACC` or `ACC + MCAND` depending on `MPLIER[0]`.
- **Control:** `load` and `busy` select the multiplexers; `rst` clears every register.
- **Connection:** clock goes to all registers; `a` and `b` go into the load inputs; `MCAND` and `ACC` go into the adder; the adder output goes back to `ACC`; `ACC` goes to the `result` pin and `busy` to the `busy` pin.

In the full-size Verilog block the same structure is used with 32 bit registers, a 5-bit counter and a register multiplexer for the read side (a 4-bit `ridx` selects A, B, STATUS, RESULT or the ID 50).

## U3 Data representation

| Vector | Binary | Hex | Decimal |
|---|---|---|---|
| Digital block: a = 12, b = 2 | `1100` x `0010` = `0001 1000` | 0x0C x 0x2 = 0x18 | 24 |
| Program: 1234 x -56 | 0x000004D2 x 0xFFFFFFC8 = `1111 1111 1111 1110 1111 0010 0001 0000` | 0xFFFEF210 | -69104 |
| Program: 65536 x 65536 | 2^16 x 2^16 = 2^32 | 0x1_0000_0000, low 32 bits 0x00000000 | 0 (overflow) |

Where it can go wrong:

- **Overflow:** RESULT is 32 bits. The true product of 65536 x 65536 needs 33 bits, so the unit returns only the low 32 bits (0), and the program prints `product = 0`. In the 4 x 4 block the product always fits in 8 bits (15 x 15 = 225).
- **Sign extension:** negative inputs are in two's complement. Shifting a 32-bit copy of A to the left for 32 cycles and adding it when the B bit is 1 gives the correct low 32 bits for signed numbers too, because two's complement arithmetic is modulo 2^32. The problem would appear if I used a wider result, then I would have to sign-extend A first.
- **Printing:** the program must print RESULT as a *signed* decimal, otherwise -69104 would be printed as 4294898192.

## U4 Computer organisation

The CPU never executes a "multiply" instruction. The block works as a memory-mapped device: the program uses normal `sw` and `lw` instructions, and the block is reached in the **memory** step of the instruction cycle (the address 0x00020200 + register is decoded and the device slot 8 is selected with `sel`). The multiplication itself then runs on its own for 32 clock cycles, in parallel to the CPU, which only polls the status register.

Instructions that need it: `sw` (write A, B and CTRL), `lw` (read STATUS and RESULT), plus `lui`/`addi` to build the address, and `andi` and `bnez` for the busy-wait loop.

## U5 Processors

- **CISC:** it would have a single `MUL` instruction (like x86 `MUL`/`IMUL`). The multiplier sits inside the ALU or is microcoded, so the program needs no addresses, no start bit and no polling.
- **Stack machine:** the program pushes A and B, then a `MUL` instruction pops both and pushes the product. There are no named registers or I/O addresses.
- **GPU:** it has many multiplier lanes working on different data at the same time (SIMD/SIMT), so thousands of products are done at once. My unit does one product at a time and takes 32 cycles. A GPU is built for throughput, mine for simplicity.
- In RC-V (RISC) the base instruction set has no multiply, so the device does the work and the program talks to it with loads and stores.

## U6 Memory and I/O

My block is an I/O device in slot 8. The CPU talks to it with memory-mapped I/O: the address decoder sets `sel` for addresses starting at 0x00020200, and the low address bits become `ridx` (0 = A, 1 = B, 2 = CTRL, 3 = STATUS, 4 = RESULT, 15 = ID 50). `we` is a store and `re` is a load. It is **programmed I/O with polling**: the program starts the unit by writing bit 0 of CTRL and then reads STATUS until `busy` is 0. There is no interrupt and no DMA, and the data goes through the CPU's registers (`wdata` in, `rdata` out).

## E1 Instruction trace: BLTU

Example: `bltu x5, x6, +16` at PC = 0x00000100, machine code `0x0062E863` (opcode `1100011`, funct3 `110`, rs1 = 5, rs2 = 6, immediate +16). Let x5 = 5 and x6 = 0xFFFFFFFF.

1. **PC and instruction memory (fetch):** PC = 0x100, the word 0x0062E863 is read; PC + 4 = 0x104 is computed.
2. **Decoder / control unit (decode):** opcode `1100011` means branch; funct3 `110` means BLTU (unsigned less than). Control signals: no register write, no memory access, ALU/comparator in unsigned compare mode.
3. **Immediate generator:** the B-type immediate bits are put back in order and sign-extended: +16.
4. **Register file:** reads rs1 = x5 = 5 and rs2 = x6 = 0xFFFFFFFF.
5. **ALU / comparator (execute):** 5 < 0xFFFFFFFF as *unsigned* numbers is true (as signed numbers x6 would be -1 and it would be false, this is the difference to BLT). The target address is PC + imm = 0x110.
6. **Branch logic and PC multiplexer:** `branch AND taken` = 1, so the PC multiplexer selects 0x110 instead of 0x104.
7. **Memory and write-back:** not used by BLTU. At the next clock edge PC = 0x110.

If x5 were not smaller than x6, the PC would continue with 0x104. The block names follow the RISC-V definition of BLTU and the signal values are the ones from the example above.

## E2 Neighbour review

Reviews of the pull requests of P49 (Performance counters) and P51 (Four-lane vector unit (mini GPU)):

- P49: review link to be added
- P51: review link to be added

## E3 Where my block sits

My block sits in the **I/O** layer (built from the components and datapath layers: registers, an adder and a small control). It is fed by the CPU through the memory bus (address decoder gives `sel` and `ridx`, the store data comes from the register file as `wdata`). Its output `rdata` goes back through the bus into a CPU register, where the program `p50.s` uses it to print the result.

## E4 Syllabus map

- [x] Logic gates, Boolean algebra, K-maps
- [x] Combinational circuits (adders, decoders, encoders, multiplexers)
- [x] Flip-flops, registers, counters
- [ ] Memory (RAM, ROM)
- [x] Number systems, complements, signed arithmetic
- [x] Bus organisation, instruction codes and formats
- [x] Instruction cycle, hardwired vs microprogrammed control
- [ ] Interrupts and the interrupt cycle
- [ ] Pipelining
- [ ] Register organisation, stack, addressing modes
- [x] RISC vs CISC, multicore, GPU
- [ ] Memory hierarchy, cache
- [x] I/O interface, programmed / interrupt-driven I/O, DMA
