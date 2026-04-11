# Next Greater Element – RISC-V 64

.section .rodata
fmt_num: .string "%ld"
fmt_sp:  .string " "
fmt_nl:  .string "\n"

.text
.globl main

main:
    addi sp, sp, -64
    sd ra, 56(sp)
    sd s0, 48(sp)
    sd s1, 40(sp)
    sd s2, 32(sp)
    addi s0, sp, 64

# n = argc - 1
    addi a0, a0, -1
    sd a0, -8(s0)
    sd a1, -16(s0)

    beqz a0, exit

# allocate arr
    ld a0, -8(s0)
    slli a0, a0, 3
    call malloc
    sd a0, -24(s0)

# allocate result
    ld a0, -8(s0)
    slli a0, a0, 3
    call malloc
    sd a0, -32(s0)

# allocate stack
    ld a0, -8(s0)
    slli a0, a0, 3
    call malloc
    sd a0, -40(s0)

    li t0, -1
    sd t0, -48(s0)

# -------- parse argv ----------
    li s1, 0
parse:
    ld t0, -8(s0)
    bge s1, t0, parse_done

    ld a1, -16(s0)
    addi t1, s1, 1
    slli t1, t1, 3
    add t1, a1, t1
    ld a0, 0(t1)
    call atoi

    ld t1, -24(s0)
    slli t2, s1, 3
    add t1, t1, t2
    sd a0, 0(t1)

    addi s1, s1, 1
    j parse

parse_done:

# -------- init result ----------
    li s1, 0
init:
    ld t0, -8(s0)
    bge s1, t0, init_done

    ld t1, -32(s0)
    slli t2, s1, 3
    add t1, t1, t2
    li t3, -1
    sd t3, 0(t1)

    addi s1, s1, 1
    j init

init_done:

# -------- stack sweep ----------
    ld s1, -8(s0)
    addi s1, s1, -1

sweep:
    bltz s1, sweep_done

while:
    ld t0, -48(s0)
    bltz t0, push

    ld t1, -40(s0)
    slli t2, t0, 3
    add t1, t1, t2
    ld t3, 0(t1)

    ld t4, -24(s0)
    slli t5, t3, 3
    add t4, t4, t5
    ld t6, 0(t4)

    ld t4, -24(s0)
    slli t5, s1, 3
    add t4, t4, t5
    ld t5, 0(t4)

    bgt t6, t5, set_result

    addi t0, t0, -1
    sd t0, -48(s0)
    j while

set_result:
    ld t1, -32(s0)
    slli t2, s1, 3
    add t1, t1, t2
    sd t3, 0(t1)

push:
    ld t0, -48(s0)
    addi t0, t0, 1
    sd t0, -48(s0)

    ld t1, -40(s0)
    slli t2, t0, 3
    add t1, t1, t2
    sd s1, 0(t1)

    addi s1, s1, -1
    j sweep

sweep_done:

# -------- print ----------
    li s1, 0

print_loop:
    ld t0, -8(s0)
    bge s1, t0, print_done

    beqz s1, print_num

    la a0, fmt_sp
    call printf

print_num:
    ld t1, -32(s0)
    slli t2, s1, 3
    add t1, t1, t2
    ld a1, 0(t1)

    la a0, fmt_num
    call printf

    addi s1, s1, 1
    j print_loop

print_done:
    la a0, fmt_nl
    call printf

exit:
    li a0, 0
    li a7, 93     # Linux RISC-V exit syscall
    ecall
    