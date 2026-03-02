; --- Standard File Descriptors ---
%define STDIN       0
%define STDOUT      1
%define STDERR      2

; System Call Numbers (x86_64)
%define SYS_READ     0
%define SYS_WRITE    1
%define SYS_OPEN     2
%define SYS_CLOSE    3
%define SYS_FSTAT    5
%define SYS_GETDENTS 217    ; SYS_GETDENTS64
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


; dirent64 structure offsets
%define D_INO      0    ; 8 bytes: Inode number
%define D_OFF      8    ; 8 bytes: Offset to next dirent
%define D_RECLEN   16   ; 2 bytes: Length of this entire record
%define D_TYPE     18   ; 1 byte:  File type
%define D_NAME     19   ; Variable: Filename (null-terminated)

; Directory Entry Types (d_type)
%define DT_UNKNOWN  0
%define DT_FIFO     1    ; Named pipe
%define DT_CHR      2    ; Character device
%define DT_DIR      4    ; Directory
%define DT_BLK      6    ; Block device
%define DT_REG      8    ; Regular file
%define DT_LNK      10   ; Symbolic link
%define DT_SOCK     12   ; Local-domain socket
