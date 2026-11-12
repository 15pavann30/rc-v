# P06 program - arithmetic and logical right shift
# Reads a signed decimal N and prints N, N sra 1, and N srl 1.
# Each result is printed as signed decimal followed by 8-digit hex.

        .text
p06_main:
        addi    sp, sp, -8
        sw      ra, 4(sp)
        sw      s0, 0(sp)

        call    rcv_read_dec
        mv      s0, a0

        # Print the original value.
        la      a0, p06_label_n
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_dec
        la      a0, p06_open_paren
        call    rcv_puts
        mv      a0, s0
        call    rcv_print_hex
        la      a0, p06_close_line
        call    rcv_puts

        # Arithmetic right shift: sign bit is replicated.
        la      a0, p06_label_sra
        call    rcv_puts
        srai    t0, s0, 1
        mv      a0, t0
        call    rcv_print_dec
        la      a0, p06_open_paren
        call    rcv_puts
        mv      a0, t0
        call    rcv_print_hex
        la      a0, p06_close_line
        call    rcv_puts

        # Logical right shift: zeros are shifted in from the left.
        la      a0, p06_label_srl
        call    rcv_puts
        srli    t0, s0, 1
        mv      a0, t0
        call    rcv_print_dec
        la      a0, p06_open_paren
        call    rcv_puts
        mv      a0, t0
        call    rcv_print_hex
        la      a0, p06_close_line
        call    rcv_puts

        lw      s0, 0(sp)
        lw      ra, 4(sp)
        addi    sp, sp, 8
        ret

        .rodata
p06_label_n:
        .asciz  "N       = "
p06_label_sra:
        .asciz  "N sra 1 = "
p06_label_srl:
        .asciz  "N srl 1 = "
p06_open_paren:
        .asciz  " ("
p06_close_line:
        .asciz  ")\n"
