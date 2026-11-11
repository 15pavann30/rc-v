# P18 program: Sign-extension explorer
#
# Rules:
# - Subroutine starts at p18_main and finishes with ret.
# - Do not use or modify sp or s0 through s11.
# - All labels start with p18_.
# - Safe memory allocation used for saving state and storing the byte.

        .text
        .globl  p18_main
p18_main:
        # Save return address to memory so we do not use or touch sp or s-registers
        la      t0, p18_saved_ra
        sw      ra, 0(t0)

        # Step 1: Read a 12-bit value in hexadecimal from terminal
        call    rcv_read_hex
        la      t0, p18_val12
        sw      a0, 0(t0)

        # Step 2: Sign-extend 12-bit value to 32 bits using slli (20) and srai (20)
        lw      t1, 0(t0)
        slli    t1, t1, 20
        srai    t1, t1, 20
        la      t0, p18_val_signed
        sw      t1, 0(t0)

        # Print formatted string: "sign-extended: <hex> (<dec>)\n"
        la      a0, p18_str_sign_ext
        call    rcv_puts
        la      t0, p18_val_signed
        lw      a0, 0(t0)
        call    rcv_print_hex
        la      a0, p18_str_open_paren
        call    rcv_puts
        la      t0, p18_val_signed
        lw      a0, 0(t0)
        call    rcv_print_dec
        la      a0, p18_str_close_paren
        call    rcv_puts

        # Step 3: Zero-extend 12-bit value to 32 bits using slli (20) and srli (20)
        la      t0, p18_val12
        lw      t2, 0(t0)
        slli    t2, t2, 20
        srli    t2, t2, 20
        la      t0, p18_val_unsigned
        sw      t2, 0(t0)

        # Print formatted string: "zero-extended: <hex> (<dec>)\n"
        la      a0, p18_str_zero_ext
        call    rcv_puts
        la      t0, p18_val_unsigned
        lw      a0, 0(t0)
        call    rcv_print_hex
        la      a0, p18_str_open_paren
        call    rcv_puts
        la      t0, p18_val_unsigned
        lw      a0, 0(t0)
        call    rcv_print_dec
        la      a0, p18_str_close_paren
        call    rcv_puts

        # Step 4: Read a decimal byte value (0-255) and store it in allocated memory via sb
        call    rcv_read_dec
        la      t0, p18_byte_slot
        sb      a0, 0(t0)

        # Step 5: Load byte back with lb (sign-extended) and print "lb:  <dec>\n"
        la      a0, p18_str_lb
        call    rcv_puts
        la      t0, p18_byte_slot
        lb      a0, 0(t0)
        call    rcv_print_dec
        call    rcv_newline

        # Step 6: Load byte back with lbu (zero-extended) and print "lbu: <dec>\n"
        la      a0, p18_str_lbu
        call    rcv_puts
        la      t0, p18_byte_slot
        lbu     a0, 0(t0)
        call    rcv_print_dec
        call    rcv_newline

        # Step 7: Restore return address from memory and return
        la      t0, p18_saved_ra
        lw      ra, 0(t0)
        ret

        # Static data allocation for temporary values and buffers
        .data
        .align  2
p18_saved_ra:
        .word   0
p18_val12:
        .word   0
p18_val_signed:
        .word   0
p18_val_unsigned:
        .word   0
p18_byte_slot:
        .byte   0
        .align  2

        # Read-only string constants
        .rodata
p18_str_sign_ext:
        .asciz  "sign-extended: "
p18_str_zero_ext:
        .asciz  "zero-extended: "
p18_str_open_paren:
        .asciz  " ("
p18_str_close_paren:
        .asciz  ")\n"
p18_str_lb:
        .asciz  "lb:  "
p18_str_lbu:
        .asciz  "lbu: "
        .align  2
