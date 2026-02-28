; pk - An Assembly Project
; Copyright (c) 2026 Jet
; Licensed under the MIT License (see LICENSE for details)

%include "include/syscalls.inc"
%include "include/my_io.inc"

section .bss
    dir_buffer resb 4096    ; 4KB buffer for filenames

section .data
    dot db ".", 0
    dotdot db "..", 0
    e_open db "Error: cannot access the specified directory", 0xA
    e_open_l equ $ - e_open
    e_read db "Error: something went wrong reading the directory", 0xA
    e_read_l equ $ - e_read


section .text
    global _start           ; entry point for linker

_start:
    ; retrieve the first argument
    mov rsi, [rsp + 16]
    test rsi, rsi           ; check if argument pointer is null

    ; save argument to r12
    jz .use_default
    mov r12, rsi
    jmp .ready

.use_default:
    mov r12, dot
    
.ready:
    ; save the str_len to r13
    mov rdi, r12
    call get_str_len        ; input: rdi, output: rax
    mov r13, rax

    ; optionally print the directory we are checking
    ; mov rsi, r12
    ; mov rdx, r13
    ; call print
    ; call print_nl

    ; open directory
    mov rdi, r12
    call io_open_dir

    cmp rax, 0
    jl error_open

    mov r13, rax

    ; print .
    mov rsi, dot
    mov rdx, 1
    call print
    call print_nl

    ; print ..
    mov rsi, dotdot
    mov rdx, 2
    call print
    call print_nl

.read_dir_loop:
    mov rax, SYS_GETDENTS
    mov rdi, r13
    mov rsi, dir_buffer
    mov rdx, 4096
    syscall

    cmp rax, 0
    je close_and_exit   ; read done
    jl error_read       ; read error

    mov r14, rax
    xor r15, r15

.parse_buffer:
    cmp r15, r14
    jae .read_dir_loop  ; jump if above or equal

    ; --- Safety Check: Is Inode 0? ---
    mov rax, [dir_buffer + r15]    ; d_ino is the first 8 bytes
    test rax, rax                  ; Is it zero?
    jz .goto_next                  ; If 0, this entry is empty/garbage, skip it

    lea rdi, [dir_buffer + r15 + 19]    ; get the start of the filename

    ; print if first char is not .
    mov al, [rdi]
    cmp al, '.'
    jne .directory_check

    ; skip if only .
    mov al, [rdi +1]
    cmp al, 0
    je .goto_next

    ; skip if ..
    cmp al, '.'
    jne .print_file
    mov al, [rdi + 2]
    cmp al, 0
    je .goto_next

.directory_check:
    mov al, [dir_buffer + r15 + 18]
    cmp al, 4
    jne .print_file

.print_directory:
    push rdi
    ; TODO: DRY the get_str_len
    call get_str_len
    mov rdx, rax
    pop rsi
    call highlight

    push rax
    push '/'
    mov rsi, rsp
    mov rdx, 1
    call print
    pop rax
    pop rax

    ; TODO: DRY the print_nl
    call print_nl

    jmp .goto_next

.print_file:
    push rdi
    call get_str_len
    mov rdx, rax
    pop rsi
    call print
    call print_nl

.goto_next:
    movzx rax, word [dir_buffer + r15 + 16]  ; rax = d_reclen
    add r15, rax
    jmp .parse_buffer

exit:
    xor rdi, rdi            ; exit code 0
    call io_exit

close_and_exit:
    mov rdi, r13           ; The FD we got from SYS_OPEN
    call io_close
    jmp exit

error_open:
    ; TODO: print error message, unable to read directory
    mov rsi, e_open
    mov rdx, e_open_l
    call print
    jmp exit

error_read:
    mov rdi, r13
    call io_close
    mov rsi, e_read
    mov rdx, e_read_l
    call print
    jmp exit




