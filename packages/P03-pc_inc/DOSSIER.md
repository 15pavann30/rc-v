# P03: 8-Bit PC Incrementer (`pc + 4`) — Dossier

## 1. Student Information
- **Name:** Shreyansh Kesarwani
- **Roll Number:** 26570058
- **Date:** November 15, 2026

---

## 2. Task Overview
This task implements an 8-bit Program Counter (PC) incrementer (`pc4 = pc + 4`) in the Digital logic simulator using only basic allowed logic gates (`NOT`, `XOR`, `AND`) and 8-bit bit splitters/mergers. Instead of using a full 8-bit ripple-carry adder, the circuit optimizes gate count by leveraging the binary representation of `+4` (`00000100₂`) and cascaded half-adders.

---

## 3. Design Questions & Explanations

### Q1. Notice bits 0 and 1 never change: why?
- **Binary Addition of 4:** Incrementing the PC by `4` corresponds to adding `00000100₂` in binary. Because bit 0 (`2⁰`) and bit 1 (`2¹`) of the constant `4` are both `0`, adding `0` to `pc[0]` and `pc[1]` produces no change (`pc[0] + 0 = pc[0]` and `pc[1] + 0 = pc[1]`) and generates no carry into bit 2.
- **Byte-Alignment Context:** In 32-bit word-aligned instruction architectures (such as RISC-V), instruction addresses are multiples of 4 bytes, meaning the lowest two bits of a valid PC are always `00`.
- **Hardware Optimization:** Because bits 0 and 1 never change, they are wired directly from the `pc` splitter to the `pc4` merger without any logic gates.

### Q2. How do half-adders implement the remaining bits (bits 2 through 7)?
- **Bit 2 (`NOT` Gate):** Adding `1` at bit position 2 (`2² = 4`) is equivalent to a half-adder with a constant carry-in of `1`:
  - $\text{Sum}_2 = \text{pc}[2] \oplus 1 = \overline{\text{pc}[2]}$ (implemented with **1 `NOT` gate**)
  - $\text{Carry}_3 = \text{pc}[2] \cdot 1 = \text{pc}[2]$ (tapped directly before the `NOT` gate as carry-in to bit 3)
- **Bits 3 to 6 (Cascaded Half-Adders):** Each bit $i \in \{3, 4, 5, 6\}$ uses one `XOR` gate and one `AND` gate to propagate the carry forward:
  - $\text{pc4}[i] = \text{pc}[i] \oplus \text{Carry}_i$ (`XOR` gate)
  - $\text{Carry}_{i+1} = \text{pc}[i] \cdot \text{Carry}_i$ (`AND` gate)
- **Bit 7 (`XOR` Gate Only):** The most significant bit computes $\text{pc4}[7] = \text{pc}[7] \oplus \text{Carry}_7$ using a final `XOR` gate; no `AND` gate is needed because any carry-out beyond bit 7 is discarded in 8-bit arithmetic.

---

## 4. Component Summary
- **NOT Gates:** 1 (for bit 2 inversion)
- **XOR Gates:** 5 (for sum outputs on bits 3, 4, 5, 6, and 7)
- **AND Gates:** 4 (for carry generation on bits 3, 4, 5, and 6)
- **Wiring Parts:** Two 8-bit splitters/mergers configured with `Spreading = 3`

---

## 5. Verification & Layout Notes
- Configured `Spreading = 3` on both the `pc` splitter and `pc4` merger to separate bit lines cleanly and prevent wire overlaps.
- Verified that all 10 logic gates use standard IEEE 91-1984 shapes and every gate input/output is explicitly connected without floating wires.
