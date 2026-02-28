%include "include/syscalls.inc"

section .data
    nl db 0xA

    color_red db 0x1B, "[31m", 0
    color_red_l equ $ - color_red

    color_reset db 0x1B, "[0m", 0
    color_reset_l equ $ - color_reset

section .text

; ---------------------------------------------------------
; io_open
; Input:  rdi = file name pointer
;         rsi = permissions: rd=0, wr=1, rdwr=2, crt=64, excl=128, 
;                            trnc=512, apnd=1024, nnblk=2048
;         rdx = mode (permissions, e.g., 0644o - only used with crt)
; Output: rax = bytes read, or error code
; Clobbers: rax, rcx, r11 (standard syscall behavior)
; ---------------------------------------------------------
global io_open
io_open:
    mov rax, SYS_OPEN
    syscall         ; the kernel uses rdi, rsi, and rdx as specified above
    ret

; ---------------------------------------------------------
; io_open_read_only
; Input:  rdi = filename pointer
; Output: rax = File Descriptor
; ---------------------------------------------------------
global io_open_read_only
io_open_read_only:
    mov rsi, O_RDONLY
    xor rdx, rdx    ; Clear permissions
    call io_open
    ret

; ---------------------------------------------------------
; io_open_append
; Input:  rdi = filename pointer
; Output: rax = file descriptor
; ---------------------------------------------------------
global io_open_append
io_open_append:
    mov rsi, O_WRONLY
    or  rsi, O_APPEND    ; Combine Write + Append
    xor rdx, rdx         ; No permissions needed if not creating
    call io_open         ; Use your base open function
    ret

; ---------------------------------------------------------
; io_open_create
; Input:  rdi = filename pointer
; Output: rax = file descriptor
; ---------------------------------------------------------
global io_open_create
io_open_create:
    mov rsi, O_WRONLY
    or rsi, O_CREAT
    mov rdx, 0644o   ; Standard permissions: rw-r--r--
    call io_open
    ret

; ---------------------------------------------------------
; io_open_dir
; Input:  rdi = directory name pointer
; Output: rax = bytes read, or error code
; Clobbers: rax, rcx, r11 (standard syscall behavior)
; ---------------------------------------------------------
global io_open_dir
io_open_dir:
    mov rsi, O_DIRECTORY
    xor rdx, rdx
    jmp io_open

; ---------------------------------------------------------
; io_close
; Input:  rdi = file descriptor
; ---------------------------------------------------------
global io_close
io_close:
    mov rax, SYS_CLOSE
    syscall
    ret

; ---------------------------------------------------------
; io_write
; Input:  rdi = file descriptor
;         rsi = pointer to data to write
;         rdx = bytes to write
; Output: rax = bytes written, or error code
; Clobbers: rax, rcx, r11 (standard syscall behavior)
; ---------------------------------------------------------
global io_write
io_write:
    mov rax, SYS_WRITE
    syscall 
    ret

; ---------------------------------------------------------
; io_read
; Input:  rdi = file descriptor (0 for keyboard/stdin)
;         rsi = pointer to a buffer (where to store the text)
;         rdx = maximum number of bytes to read
; Output: rax = number of bytes actually read
; ---------------------------------------------------------
global io_read
io_read:
    mov rax, SYS_READ
    syscall
    ret

; ---------------------------------------------------------
; io_close
; Input:  rdi = exit code (0 for success)
; ---------------------------------------------------------
global io_exit
io_exit:
    mov rax, SYS_EXIT
    syscall

; ---------------------------------------------------------
; get_str_length
; Input:  rdi = pointer to null-terminated string
; Output: rax = string length (number of bytes)
; ---------------------------------------------------------
global get_str_len
get_str_len:
    xor rax, rax    ; Clear the counter

.loop:
    cmp byte [rdi + rax], 0 ; Input is RDI
    je .finished
    inc rax
    jmp .loop

.finished:
    ret

; ---------------------------------------------------------
; print
; Input:  rsi = pointer to data to write
;         rdx = bytes to write
; Output: rax = bytes written, or error code
; Clobbers: rax, rcx, r11 (standard syscall behavior)
; ---------------------------------------------------------
global print
print:
    mov rdi, STDOUT
    jmp io_write

; ---------------------------------------------------------
; print_nl
; Prints a new line char
; ---------------------------------------------------------
global print_nl
print_nl:
    mov rdi, STDOUT
    mov rsi, nl
    mov rdx, 1
    jmp io_write

; ---------------------------------------------------------
; highlight
; Input:  rsi = pointer to data to write
;         rdx = bytes to write
; Output: rax = bytes written, or error code
; Clobbers: rax, rcx, r11 (standard syscall behavior)
; ---------------------------------------------------------
global highlight
highlight:
    push r12
    push r13

    ; Save the string
    mov r12, rsi
    mov r13, rdx

    ; Start the highlight
    mov rsi, color_red
    mov rdx, color_red_l
    call print

    ; Print the string
    mov rsi, r12
    mov rdx, r13
    call print

    ; End the highlight
    mov rsi, color_reset
    mov rdx, color_reset_l
    call print

    pop r13
    pop r12
    ret
