# P50 program - Multiply with the MUL unit
# Rules: start at the label p50_main and finish with ret; every label you
# create starts with p50_ ; save ra (and any s registers you use) on the stack.

        .text
p50_main:
        addi    sp, sp, -16
        sw      ra, 12(sp)
        sw      s0, 8(sp)
        sw      s1, 4(sp)

        # Read A (signed decimal)
        call    rcv_read_dec
        mv      s0, a0          # s0 = A

        # Read B (signed decimal)
        call    rcv_read_dec
        mv      s1, a0          # s1 = B

        # Base address for multiplier slot 8: 0x00020200
        lui     t0, 0x20
        addi    t0, t0, 0x200   # t0 = 0x00020200 (MUL_A)

        # Write A to MUL_A (offset 0)
        sw      s0, 0(t0)

        # Write B to MUL_B (offset 4)
        sw      s1, 4(t0)

        # Write 1 to MUL_CTRL (offset 8) to start multiplication
        li      t1, 1
        sw      t1, 8(t0)

p50_wait_busy:
        # Read MUL_STATUS (offset 12)
        lw      t2, 12(t0)
        andi    t2, t2, 1
        bnez    t2, p50_wait_busy

        # Read MUL_RESULT (offset 16)
        lw      s0, 16(t0)      # s0 = product

        # Print "product = "
        la      a0, p50_msg
        call    rcv_puts

        # Print product as signed decimal
        mv      a0, s0
        call    rcv_print_dec

        # Print newline
        call    rcv_newline

        # Restore registers and return
        lw      s1, 4(sp)
        lw      s0, 8(sp)
        lw      ra, 12(sp)
        addi    sp, sp, 16
        ret

        .rodata
p50_msg:
        .asciz  "product = "
        .align  2
