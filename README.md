# PEEK - An Assembly Project

> A Zero-Dependency Linux Directory Browser in **x86_64** Assembly

`pk` is a high-performance, minimalist implementation of the core Linux ls utility, written entirely in **x86_64** Assembly (NASM). Unlike standard system utilities that rely on the GNU C Library (glibc), `pk` communicates directly with the Linux kernel using the syscall interface.

> pk is 99% smaller than ls

|BIN|SIZE|
|-|-|
|ls|~140kb|
|pk|~1.2kb|


## Project Summary

This project serves as a deep dive into the Linux ABI, manual memory management, and the **getdents64** system call. It is designed for maximum efficiency, resulting in a binary size that is orders of magnitude smaller than the standard ls found in most distributions.

### Key Technical Highlights:

**Direct Kernel Communication**: Bypasses libc entirely using the **x86_64** syscall interface (AMD64 ABI).

**Manual Buffer Parsing**: Hand-rolled logic to navigate the variable-length linux_dirent64 structures returned by the kernel.

**Minimal Footprint**: A fully functional, stripped executable under 5KB.

### Main Features

#### Core Functionality
- [X] Direct Syscall Implementation: Use sys_open, sys_getdents64, sys_write, and sys_exit without external headers.
- [X] Directory Streaming: Ability to open the current directory (.) or a user-specified path passed via argv.
- [ ] Buffered I/O: Implement a stack-allocated or heap-allocated buffer to handle large directory listings efficiently.
- [X] Linear Parsing: Logic to correctly increment pointers based on the d_reclen field in the directory entry.

#### Metadata & Formatting
- [X] Basic Listing: Print filenames separated by newlines or spaces.
- [X] File Type Detection: Identify and color-code (or label) directories versus regular files using the d_type field.
- [ ] Hidden File Toggle: Implement a basic flag (e.g., -a) to show or hide files starting with a dot.
- [ ] Integer-to-ASCII (itoa): A custom routine to convert file sizes or inode numbers into human-readable strings for display.

#### Engineering Excellence
- [ ] Pure ASM Build Pipeline: A Makefile that handles assembly, linking, and symbol stripping.
- [ ] Error Handling: Robust checks for "Directory Not Found" or "Permission Denied" using kernel return codes.
- [X] Comprehensive README: Documentation detailing how to build, run, and compare binary sizes against the system ls.

## Project Structure

```
.
├── bin/            # Final stripped executable
├── build/          # Intermediate .o files
├── include/        # .inc files (syscalls, constants, struct offsets)
├── src/            # .asm files (actual logic)
├── Makefile        # Runs the build
└── README.md       # <-- You are here
```


## To build


```bash
make # assembles,links, and strips all code
make clean # deletes binary and object files for a fresh build
make -n # dry run, outputs commands without running them
make clean && make debug # build with debug signals
make install # Install to /usr/local/bin
make install PREFIX=$HOME/.local # Install to custom location
make uninstall # delete bin
```


## Zero Dependencies

```bash
$ ldd pk
	not a dynamic executable

$ file pk
lsclone: ELF 64-bit LSB executable, x86-64, version 1 (SYSV), statically linked, stripped

$ size pk
   text	  data	   bss	   dec	   hex	filename
    582	   112	  4096	  4790	  12b6	pk

$ ls -lh pk
-rwxrwxr-x 1 jet jet 1.2K Feb 28 14:34 pk
```

## How to Use

```bash
$ pk # Peek current location

$ pk ~ # Peek by Argument

$ echo "/home" | pk # Coming soon
```

### Example
```bash
$ pk
.
..
bin/
build/
include/
src/
Makefile
README.md
```

## Why Assembly?

Standard `ls` is dynamically linked to `libc.so`. When you run it, the Linux loader must map the C library into memory, resolve symbols, and initialize the runtime. 

`pk` is a **Static, Raw Binary**.
1. **No Loader Overhead**: The kernel jumps straight to our `_start` label.
2. **Predictable Memory**: We define our own 4KB buffer in the `.bss` section, avoiding the overhead of a heap allocator (malloc).
3. **Register-Based**: We use the System V ABI to pass arguments directly in registers (`rdi`, `rsi`, `rdx`), resulting in zero stack-frame overhead for core I/O.


![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)
