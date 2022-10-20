section .rodata
    align 0x40
    first_15:       db  '1', 10, '2', 10, 'Fizz', 10, '4', 10, 'Buzz', 10, 'Fizz', 10, '7', 10, '8', 10, \
                        'Fizz', 10, 'Buzz', 10, '11', 10, 'Fizz', 10, '13', 10, '14', 10, 'FizzBuzz', 10
    ascii_15:       db  '15'

    fzbz_str_size   equ 39

section .bss
    numbufsz        equ (1 << 6)
    align 0x20
    num_buf:        resb numbufsz

    bufsz           equ (1 << 16)
    align 0x1000
    io_buffer:      resb bufsz

section .text
    global _start
    global buf_empty
    global buf_write_u64
    global inc_u64_str
    global fizzbuzz_main

align 0x1000
_start:
    ; initialization
    vpxor ymm0, ymm0, ymm0      ; zero out ymm0
    mov r13, 58                 ; holds buffer size
    mov r14d, 0x7A7A7542        ; Buzz (but backwards bc. endianness)
    mov r15, 0x7A7A75427A7A6946 ; FizzBuzz
    vmovdqa ymm1, [first_15]
    vmovdqa ymm2, [first_15 + 32]
    vmovdqa [io_buffer], ymm1
    vmovdqa [io_buffer + 32], ymm2
    
    mov rax, 0x7A75420A7A7A6946     ; Fizz\nBuz
    mov rdx, 0x0000000000000A7A     ; z\n
    vmovq xmm14, rax
    vmovq xmm15, rdx
    vpunpcklqdq xmm15, xmm14, xmm15

    mov rax, 0x7A69460A7A7A7542     ; Buzz\nFiz
    mov rdx, 0x0000000000000A7A     ; z\n
    vmovq xmm13, rax
    vmovq xmm14, rdx
    vpunpcklqdq xmm14, xmm13, xmm14

    mov rax, 0x3030303030303030     ; '0' repeated 8 times
    vmovq xmm1, rax
    vpbroadcastq ymm1, xmm1
    vmovdqa [num_buf], ymm1         ; set everything in num_buf to ASCII '0'
    movzx eax, word [ascii_15]
    mov word [num_buf + 0x1e], ax   ; initialize num_buf with 15

    call fizzbuzz_main
    jmp exit

align 0x40
fizzbuzz_main:
    push rbx
    push r12
    mov rbx,  2 ; number of digits
    mov r12, -1 ; number of iterations
loop_start:
    ; check if this iterations result will fit in buffer beforehand, to avoid so many bounds checks
    lea rax, [rbx + 2]
    shl rax, 3
    lea rax, [rax + fzbz_str_size + 4 + r13]
    mov r11, bufsz
    sub r11, rax
    jns loop_body
    call buf_empty
loop_body:
    call inc_u64_str
    call buf_write_u64
    call inc_u64_str
    call buf_write_u64

fizz_3: 
    mov dword [io_buffer + r13], r15d
    mov byte [io_buffer + r13 + 4], 0xA
    lea r13, [r13+5]

    call inc_u64_str
    call inc_u64_str
    call buf_write_u64

buzz_5_fizz_6:
    vmovdqu [io_buffer + r13], xmm14
    lea r13, [r13+10]

    call inc_u64_str
    call inc_u64_str
    call inc_u64_str
    call buf_write_u64
    call inc_u64_str
    call buf_write_u64

fizz_9_buzz_10:
    vmovdqu [io_buffer + r13], xmm15
    lea r13, [r13+10]

    call inc_u64_str
    call inc_u64_str
    call inc_u64_str
    call buf_write_u64

fizz_12:
    mov dword [io_buffer + r13], r15d
    mov byte [io_buffer + r13 + 4], 0xA
    lea r13, [r13+5]

    call inc_u64_str
    call inc_u64_str
    call buf_write_u64
    call inc_u64_str
    call buf_write_u64

fizzbuzz_15:
    mov qword [io_buffer + r13], r15
    mov byte [io_buffer + r13 + 8], 0xA
    lea r13, [r13+9]

    call inc_u64_str
    sub r12, 0xf
    test r12, r12
    jnz loop_start
    pop r12
    pop rbx
    ret

align 0x40
; appends a u64 string (with length in rbx) to the i/o buffer
buf_write_u64:
    mov rax, rbx
    neg rax
    vmovdqu xmm1, [num_buf + 0x20 + rax]
    vmovdqu [io_buffer + r13], xmm1
    mov rcx, rbx
    mov byte [io_buffer + rcx + r13], 0xA
    inc rcx
    lea r13, [r13+rcx]
    ret

align 0x20
; empty io buffer (write out)
buf_empty:
    mov rsi, io_buffer
    mov rdx, r13
    mov rdi, 1
    mov rax, 1
    syscall
    xor r13, r13
    ret

align 0x20
; Increment number in num_buf, and length (rbx) if needed
inc_u64_str:
    xor rdx, rdx
    dec rdx
inc_loop:
    movzx eax, byte [num_buf + 0x20 + rdx]
    cmp eax, 0x39
    jne inc_simple
    mov byte [num_buf + 0x20 + rdx], 0x30
    dec rdx
    jmp inc_loop
inc_simple:
    inc eax
    mov byte [num_buf + 0x20 + rdx], al
    lea rax, [rbx + 1]
    add rdx, rbx
    cmovs rbx, rax
    ret

align 0x20
exit:
    call buf_empty
    mov rax, 0x3c
    xor rdi, rdi
    syscall
