# q5.s  –  Palindrome check  (RISC-V 64-bit, Linux)
# O(n) time, O(1) space.
#
# Strategy: open input.txt twice.
#   fd_fwd reads forward  (one byte at a time, starts at offset 0)
#   fd_bwd reads backward (lseek to hi before each read)
# Walk lo up and hi down until they meet; mismatch → "No".
#
# RISC-V Linux syscall numbers:
#   openat = 56   (use AT_FDCWD=-100, flags=O_RDONLY=0)
#   read   = 63
#   write  = 64
#   lseek  = 62
#   exit   = 93
#
# Frame layout (s0 = fp):
#   -8(s0)  : fd_fwd
#   -16(s0) : fd_bwd
#   -24(s0) : file_size
#   -32(s0) : hi
#   -33(s0) : byte buffer fwd  (1 byte)
#   -34(s0) : byte buffer bwd  (1 byte)

    .section .rodata
filename:   .string "input.txt"
msg_yes:    .string "Yes\n"
msg_no:     .string "No\n"

    .text
    .globl main
main:
    addi    sp, sp, -48
    sd      ra, 40(sp)
    sd      s0, 32(sp)
    addi    s0, sp, 48

    # ── open fd_fwd ─────────────────────────────────────────────────
    li      a0, -100            # AT_FDCWD
    la      a1, filename
    li      a2, 0               # O_RDONLY
    li      a3, 0
    li      a7, 56              # openat
    ecall
    bltz    a0, .Lno
    sd      a0, -8(s0)

    # ── open fd_bwd ─────────────────────────────────────────────────
    li      a0, -100
    la      a1, filename
    li      a2, 0
    li      a3, 0
    li      a7, 56
    ecall
    bltz    a0, .Lno
    sd      a0, -16(s0)

    # ── get file size: lseek(fd_bwd, 0, SEEK_END=2) ─────────────────
    ld      a0, -16(s0)
    li      a1, 0
    li      a2, 2               # SEEK_END
    li      a7, 62              # lseek
    ecall
    sd      a0, -24(s0)         # file_size

    beqz    a0, .Lyes           # empty → palindrome

    # ── init lo=0, hi=file_size-1 ───────────────────────────────────
    addi    t0, a0, -1
    sd      t0, -32(s0)         # hi

    li      s1, 0               # lo (in register, updated each iter)

    # seek fd_fwd to 0
    ld      a0, -8(s0)
    li      a1, 0
    li      a2, 0               # SEEK_SET
    li      a7, 62
    ecall

.Lloop:
    ld      t1, -32(s0)         # hi
    bge     s1, t1, .Lyes       # lo >= hi → palindrome

    # read 1 byte at lo from fd_fwd (already positioned)
    ld      a0, -8(s0)
    addi    a1, s0, -33         # buffer
    li      a2, 1
    li      a7, 63              # read
    ecall
    lb      t2, -33(s0)         # ch_lo

    # seek fd_bwd to hi
    ld      a0, -16(s0)
    ld      a1, -32(s0)         # hi
    li      a2, 0               # SEEK_SET
    li      a7, 62
    ecall

    # read 1 byte at hi from fd_bwd
    ld      a0, -16(s0)
    addi    a1, s0, -34
    li      a2, 1
    li      a7, 63
    ecall
    lb      t3, -34(s0)         # ch_hi

    bne     t2, t3, .Lno        # mismatch → No

    # lo++, hi--
    addi    s1, s1, 1
    ld      t1, -32(s0)
    addi    t1, t1, -1
    sd      t1, -32(s0)

    # seek fd_fwd to new lo
    ld      a0, -8(s0)
    mv      a1, s1
    li      a2, 0
    li      a7, 62
    ecall

    j       .Lloop

.Lyes:
    li      a0, 1               # stdout
    la      a1, msg_yes
    li      a2, 4
    li      a7, 64              # write
    ecall
    j       .Ldone

.Lno:
    li      a0, 1
    la      a1, msg_no
    li      a2, 3
    li      a7, 64
    ecall

.Ldone:
    ld      ra, 40(sp)
    ld      s0, 32(sp)
    addi    sp, sp, 48
    li      a0, 0
    li      a7, 93
    ecall
    