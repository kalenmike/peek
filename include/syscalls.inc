; --- Standard File Descriptors ---
%define STDIN       0
%define STDOUT      1
%define STDERR      2

; System Call Numbers (x86_64)
%define SYS_READ     0
%define SYS_WRITE    1
%define SYS_OPEN     2
%define SYS_CLOSE    3
%define SYS_GETDENTS 217
%define SYS_EXIT     60

; File constants
%define O_RDONLY 0
%define O_WRONLY 1
%define O_RDWR   2
%define O_CREAT  64
%define O_APPEND 1024
%define O_DIRECTORY  0o200000


; Dirent64 Structure Offsets
%define d_ino_off    0
%define d_off_off    8
%define d_reclen_off 16
%define d_name_off   19
