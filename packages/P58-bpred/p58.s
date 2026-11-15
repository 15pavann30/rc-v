# P58 program - 2-bit branch predictor demo (placeholder until README task is known)

        .text
p58_main:
        addi    sp, sp, -32
        sw      ra, 28(sp)
        sw      s0, 24(sp)
        sw      s1, 20(sp)
        sw      s2, 16(sp)

        li      s0, 1               # counter state 0..3, start weakly not-taken
        li      s1, 0               # number of correct predictions
        la      s2, p58_seq         # pointer into outcome list

p58_loop:
        lbu     t0, 0(s2)           # actual outcome (1 taken, 0 not taken)
        li      t1, 255
        beq     t0, t1, p58_done    # 255 marks the end of the list

        sltiu   t2, s0, 2           # 1 if state < 2
        xori    t2, t2, 1           # t2 = prediction (1 if state >= 2)
        bne     t2, t0, p58_upd     # wrong prediction: don't count
        addi    s1, s1, 1

p58_upd:
        beqz    t0, p58_dec
        li      t3, 3
        beq     s0, t3, p58_next    # saturate at 3
        addi    s0, s0, 1
        j       p58_next
p58_dec:
        beqz    s0, p58_next        # saturate at 0
        addi    s0, s0, -1
p58_next:
        addi    s2, s2, 1
        j       p58_loop

p58_done:
        addi    t0, s1, '0'         # print the correct count as one digit
        sb      t0, 0(sp)
        li      t1, 10
        sb      t1, 1(sp)
        sb      zero, 2(sp)
        mv      a0, sp
        call    rcv_puts

        lw      ra, 28(sp)
        lw      s0, 24(sp)
        lw      s1, 20(sp)
        lw      s2, 16(sp)
        addi    sp, sp, 32
        ret

        .rodata
p58_seq:
        .byte   1, 1, 0, 1, 1, 0, 1, 1, 255
        .align  2
