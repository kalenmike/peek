; pk - An Assembly Project
; Copyright (c) 2026 Jet
; Licensed under the MIT License (see LICENSE for details)

%include "include/syscalls.inc"
%include "include/my_io.inc"

section .bss
    dir_buffer resb 4096    ; 4KB buffer for filenames

section .rodata
    flag_jump_table:
        dq run_pk          ; 0: Default (no flag/path)
        dq show_help       ; 1: --help or -h
        dq show_version    ; 2: --version or -v

    ; String constants for comparison
    str_help db "--help", 0
    str_h db "-h", 0
    str_version db "--version", 0
    str_v db "-v", 0

    ; Usage / Help Message
    help_msg:
        db "Peek (pk) - A minimalist x86_64 directory browser", 10, 10
        db "USAGE:", 10
        db "    pk [OPTIONS] [PATH]", 10, 10
        db "OPTIONS:", 10
        db "    -h, --help       Show this help message", 10
        db "    -v, --version    Show version and author info", 10, 10
        db "AUTHOR:", 10
        db "    Written by Kalen Michael in pure x86_64 Assembly.", 10
        db "    Repository: github.com/kalenmike/peek", 10, 0
    help_msg_l equ $ - help_msg


    ; Version Message
    version_msg:
        db "Peek (pk) version v"
        db "0.1.0-dev"
        db " (x86_64 linux)", 10
        db "Built: ", BUILD_DATE, 10
        db "Author: Kalen Michael", 10
        db "License: MIT", 10, 0
    version_msg_l equ $ - version_msg

    ; Strings for file ops
    dot db ".", 0
    dotdot db "..", 0

    ; Strings for errors
    e_open db "Error: cannot access the specified directory", 0xA
    e_open_l equ $ - e_open
    e_read db "Error: something went wrong reading the directory", 0xA
    e_read_l equ $ - e_read

section .text
    global _start           ; entry point for linker

_start:
    mov rax, [rsp]
    cmp rax, 1
    je use_default         ; no args

    ; retrieve the first argument
    mov rsi, [rsp + 16]     ; rsi = argv[1]

    ; Check for Help
    mov rdi, str_help
    call strcmp
    jz .use_index_1
    mov rdi, str_h
    call strcmp
    jz .use_index_1

    ; Check for Version
    mov rdi, str_version
    call strcmp
    jz .use_index_2
    mov rdi, str_v
    call strcmp
    jz .use_index_2

    ; If no flags match, treat it as a PATH (index 0)
    jmp .use_index_0

; Flag lookup
.use_index_0:
    mov rbx, 0
    jmp .do_jump
.use_index_1:
    mov rbx, 1
    jmp .do_jump
.use_index_2:
    mov rbx, 2
    jmp .do_jump

.do_jump:
    jmp [flag_jump_table + rbx * 8]

run_pk:
    test rsi, rsi           ; check if argument pointer is null

    ; save argument to r12
    jz use_default
    mov r12, rsi
    jmp ready

use_default:
    mov r12, dot
    
ready:
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


show_help:
    mov rsi, help_msg
    mov rdx, help_msg_l
    call print
    jmp exit

show_version:
    mov rsi, version_msg
    mov rdx, version_msg_l
    call print
    jmp exit

; Input: RSI (str1), RDI (str2)
; Output: ZF=1 if equal, ZF=0 if not
strcmp:
    push rsi
    push rdi
.loop:
    mov al, [rsi]
    mov bl, [rdi]
    cmp al, bl
    jne .done
    test al, al     ; Check for null terminator
    jz .done
    inc rsi
    inc rdi
    jmp .loop
.done:
    pop rdi
    pop rsi
    ret
