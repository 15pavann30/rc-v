p58_main:
    addi sp, sp, -32
    sw   ra, 28(sp)
    sw   s1, 24(sp)
    sw   s2, 20(sp)
    sw   s3, 16(sp)
    sw   s4, 12(sp)
    call rcv_read_dec            # N comes back in a0
    mv   s1, a0
    li   s4, 2                   # run the loop twice
p58_outer:
    li   t0, BPRED_CLEAR
    sw   zero, 0(t0)             # clear the counts
    mv   t1, s1
p58_loop:
    addi t1, t1, -1
    bnez t1, p58_loop            # the ONLY branch in the counted section
    li   t0, BPRED_BRANCHES
    lw   s2, 0(t0)               # read both counts before any other branch
    li   t0, BPRED_CORRECT
    lw   s3, 0(t0)
    addi s4, s4, -1
    bnez s4, p58_outer           # this branch is outside the counted section
    la   a0, p58_s_br
    call rcv_puts
    mv   a0, s2
    call rcv_print_dec
    call rcv_newline
    la   a0, p58_s_co
    call rcv_puts
    mv   a0, s3
    call rcv_print_dec
    call rcv_newline
    lw   ra, 28(sp)
    lw   s1, 24(sp)
    lw   s2, 20(sp)
    lw   s3, 16(sp)
    lw   s4, 12(sp)
    addi sp, sp, 32
    ret

p58_s_br: .asciz "branches: "
p58_s_co: .asciz "correct: "
