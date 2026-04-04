# q2.s  –  Next Greater Element  (RISC-V 64-bit, Linux)
#
# For each element in argv[1..n], print 0-based index of the
# first strictly greater element to its right, or -1.
# O(n) time, O(n) space using a monotone stack.
#
# Stack frame locals (accessed via s0 = frame pointer):
#   -8(s0)  : n           (int64)
#   -16(s0) : argv        (ptr)
#   -24(s0) : arr         (int64*, parsed values)
#   -32(s0) : result      (int64*, answers, init -1)
#   -40(s0) : stk         (int64*, index stack)
#   -48(s0) : stk_top     (int64, -1 = empty)

    .section .rodata
fmt_ld:     .string "%ld"
fmt_sp:     .string " "
fmt_nl:     .string "\n"

    .text
    .globl main
main:
    addi    sp, sp, -64
    sd      ra, 56(sp)
    sd      s0, 48(sp)
    sd      s1, 40(sp)
    sd      s2, 32(sp)
    addi    s0, sp, 64          # frame pointer

    # n = argc - 1
    addiw   a0, a0, -1
    sext.w  a0, a0
    sd      a0, -8(s0)          # n
    sd      a1, -16(s0)         # argv

    beqz    a0, .Lmain_exit

    # alloc arr[n]
    ld      a0, -8(s0)
    slli    a0, a0, 3
    call    malloc
    sd      a0, -24(s0)

    # alloc result[n]
    ld      a0, -8(s0)
    slli    a0, a0, 3
    call    malloc
    sd      a0, -32(s0)

    # alloc stk[n]
    ld      a0, -8(s0)
    slli    a0, a0, 3
    call    malloc
    sd      a0, -40(s0)

    li      t0, -1
    sd      t0, -48(s0)         # stk_top = -1

    # ── parse argv[1..n] into arr ──────────────────────────────────
    li      s1, 0               # i = 0
.Lparse:
    ld      t0, -8(s0)
    bge     s1, t0, .Lparse_done
    ld      a1, -16(s0)         # argv
    addi    t1, s1, 1
    slli    t1, t1, 3
    add     t1, a1, t1
    ld      a0, 0(t1)           # argv[i+1]
    call    atoi
    sext.w  a0, a0
    ld      t1, -24(s0)         # arr
    slli    t2, s1, 3
    add     t1, t1, t2
    sd      a0, 0(t1)           # arr[i] = value
    addi    s1, s1, 1
    j       .Lparse
.Lparse_done:

    # ── init result[] = -1 ─────────────────────────────────────────
    li      s1, 0
.Linit:
    ld      t0, -8(s0)
    bge     s1, t0, .Linit_done
    ld      t1, -32(s0)
    slli    t2, s1, 3
    add     t1, t1, t2
    li      t3, -1
    sd      t3, 0(t1)
    addi    s1, s1, 1
    j       .Linit
.Linit_done:

    # ── monotone stack sweep right → left ─────────────────────────
    ld      s1, -8(s0)
    addi    s1, s1, -1          # i = n-1
.Lsweep:
    bltz    s1, .Lsweep_done

    # while stk not empty AND arr[stk_top] <= arr[i]: pop
.Lwhile:
    ld      t0, -48(s0)         # stk_top
    bltz    t0, .Lwhile_done
    ld      t1, -40(s0)         # stk[]
    slli    t2, t0, 3
    add     t1, t1, t2
    ld      t3, 0(t1)           # top_idx
    ld      t4, -24(s0)         # arr[]
    slli    t5, t3, 3
    add     t4, t4, t5
    ld      t6, 0(t4)           # arr[top_idx]
    ld      t4, -24(s0)
    slli    t5, s1, 3
    add     t4, t4, t5
    ld      t5, 0(t4)           # arr[i]
    bgt     t6, t5, .Lwhile_done   # arr[top_idx] > arr[i]: stop
    addi    t0, t0, -1
    sd      t0, -48(s0)         # pop
    j       .Lwhile
.Lwhile_done:

    # if stk not empty: result[i] = stk[stk_top]
    ld      t0, -48(s0)
    bltz    t0, .Lpush
    ld      t1, -40(s0)
    slli    t2, t0, 3
    add     t1, t1, t2
    ld      t3, 0(t1)           # top_idx
    ld      t4, -32(s0)         # result[]
    slli    t5, s1, 3
    add     t4, t4, t5
    sd      t3, 0(t4)           # result[i] = top_idx

.Lpush:
    ld      t0, -48(s0)
    addi    t0, t0, 1
    sd      t0, -48(s0)
    ld      t1, -40(s0)
    slli    t2, t0, 3
    add     t1, t1, t2
    sd      s1, 0(t1)           # stk[stk_top] = i

    addi    s1, s1, -1
    j       .Lsweep
.Lsweep_done:

    # ── print result ───────────────────────────────────────────────
    li      s1, 0
.Lprint:
    ld      t0, -8(s0)
    bge     s1, t0, .Lprint_done
    beqz    s1, .Lprint_val
    la      a0, fmt_sp
    call    printf
.Lprint_val:
    ld      t0, -32(s0)
    slli    t1, s1, 3
    add     t0, t0, t1
    ld      a1, 0(t0)           # result[i]
    la      a0, fmt_ld
    call    printf
    addi    s1, s1, 1
    j       .Lprint
.Lprint_done:
    la      a0, fmt_nl
    call    printf

.Lmain_exit:
    ld      ra, 56(sp)
    ld      s0, 48(sp)
    ld      s1, 40(sp)
    ld      s2, 32(sp)
    addi    sp, sp, 64
    li      a0, 0               # exit code 0
    li      a7, 93              # sys_exit
    ecall
    