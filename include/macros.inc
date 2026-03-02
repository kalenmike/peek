; --- Macro: Append '/' ---
%macro append_slash 0
    mov byte [rdi], 0x2F
    inc rdi
%endmacro

; --- Macro: Append '\n' ---
%macro append_nl 0
    mov byte [rdi], 0x0A
    inc rdi
%endmacro

; --- Macro: Append '/' and '\n' ---
%macro append_slash_nl 0
    mov word [rdi], 0x0A2F
    add rdi, 2
%endmacro
