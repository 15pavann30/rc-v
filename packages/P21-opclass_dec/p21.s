# P21 program - palindrome checker
# Rules: start at the label p21_main and finish with ret; every label you
# create starts with p21_ ; save ra (and any s registers you use) on the stack.
# You may call the library routines in sw/lib/rcv_lib.s (rcv_puts, rcv_getc, ...).

        .text
p21_main:
        addi    sp, sp, -4
        sw      ra, 0(sp)

        la      t0, p21_str          # t0 = pointer to first char
        mv      t1, t0
p21_len:                             # scan forward to the terminating 0
        lbu     t2, 0(t1)
        beqz    t2, p21_end
        addi    t1, t1, 1
        j       p21_len
p21_end:
        addi    t1, t1, -1           # t1 = pointer to last char

p21_cmp:
        bgeu    t0, t1, p21_yes      # pointers met/crossed -> palindrome
        lbu     t2, 0(t0)
        lbu     t3, 0(t1)
        bne     t2, t3, p21_no       # mismatch -> not a palindrome
        addi    t0, t0, 1
        addi    t1, t1, -1
        j       p21_cmp

p21_yes:
        la      a0, p21_msg_yes
        j       p21_print
p21_no:
        la      a0, p21_msg_no
p21_print:
        jal     ra, rcv_puts

        lw      ra, 0(sp)
        addi    sp, sp, 4
        ret

        .rodata
p21_str:
        .asciz  "racecar"
p21_msg_yes:
        .asciz  "Palindrome\n"
p21_msg_no:
        .asciz  "Not a palindrome\n"
        .align  2
