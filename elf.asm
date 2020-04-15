bits 64
org 0x400000

ELFCLASS64    equ 2
ELFDATA2LSB   equ 1
EV_CURRENT    equ 1
ELFOSABI_NONE equ 0
ET_EXEC       equ 2
EM_X86_64     equ 62

PT_LOAD    equ 1
PT_DYNAMIC equ 2
PT_INTERP  equ 3

PF_X equ (1 << 0)
PF_W equ (1 << 1)
PF_R equ (1 << 2)

DT_NULL    equ 0
DT_NEEDED  equ 1
DT_HASH    equ 4
DT_STRTAB  equ 5
DT_SYMTAB  equ 6
DT_RELA    equ 7
DT_RELASZ  equ 8
DT_RELAENT equ 9
DT_STRSZ   equ 10
DT_SYMENT  equ 11

%define ELF64_ST_INFO(b,t) (((b)<<4)+((t)&0xf))

R_X86_64_JUMP_SLOT equ 7

STB_GLOBAL equ 1

STT_FUNC equ 2

%define ELF64_R_INFO(s,t) (((s)<<32)+((t)&0xffffffff))

EHSIZE    equ 64
PHENTSIZE equ 56
SYMENT    equ 24
RELAENT   equ 24

; Elf64_Ehdr
	db 0x7f,"ELF"    ; ei_mag
	db ELFCLASS64    ; ei_class
	db ELFDATA2LSB   ; ei_data
	db EV_CURRENT    ; ei_version
	db ELFOSABI_NONE ; ei_osabi
	db 0             ; ei_abiversion
	db 0,0,0,0,0,0,0 ; ei_pad
	dw ET_EXEC       ; ei_pad
	dw EM_X86_64     ; e_machine
	dd EV_CURRENT    ; e_version
	dq entry         ; e_entry
	dq phoff - $$    ; e_phoff
	dq 0             ; e_shoff
	dd 0             ; e_flags
	dw EHSIZE        ; e_ehsize
	dw PHENTSIZE     ; e_phentsize
	dw 3             ; e_phnum
	dw 0             ; e_shentsize
	dw 0             ; e_shnum
	dw 0             ; e_shstrndx

; Elf64_Phdr[]
phoff:

	; Elf64_Phdr PT_INTERP
	dd PT_INTERP      ; p_type
	dd PF_R|PF_W|PF_X ; p_flags
	dq interp - $$    ; p_offset
	dq interp         ; p_vaddr
	dq interp         ; p_paddr
	dq interp_len     ; p_filesz
	dq interp_len     ; p_memsz
	dq 0              ; p_align

	; Elf64_Phdr PT_LOAD
	dd PT_LOAD        ; p_type
	dd PF_R|PF_W|PF_X ; p_flags
	dq 0              ; p_offset
	dq $$             ; p_vaddr
	dq $$             ; p_paddr
	dq file_len       ; p_filesz
	dq file_len       ; p_memsz
	dq 0x1000         ; p_align

	; Elf64_Phdr PT_DYNAMIC
	dd PT_DYNAMIC     ; p_type
	dd PF_R|PF_W|PF_X ; p_flags
	dq dynamic - $$   ; p_offset
	dq dynamic        ; p_vaddr
	dq dynamic        ; p_paddr
	dq dynamic_len    ; p_filesz
	dq dynamic_len    ; p_memsz
	dq 0x0            ; p_align

interp     db  "/lib64/ld-linux-x86-64.so.2",0
interp_len equ $ - interp

dynamic:
	dq DT_NEEDED,  libc_name - strtab
	dq DT_STRTAB,  strtab
	dq DT_STRSZ,   strtab_len
	dq DT_SYMTAB,  symtab
	dq DT_SYMENT,  SYMENT
	dq DT_HASH,    hashtab
	dq DT_RELA,    relatab
	dq DT_RELASZ,  relatab_len
	dq DT_RELAENT, RELAENT
	dq DT_NULL,    0
dynamic_len equ $ - dynamic

strtab:
	db 0
	libc_name db "libc.so.6",0
	exit_name db "exit",0
strtab_len equ $ - strtab

symtab:

	dd 0 ; st_name
	db 0 ; st_info
	db 0 ; st_other
	dw 0 ; st_shndx
	dq 0 ; st_value
	dq 0 ; st_size

	dd exit_name - strtab
	db ELF64_ST_INFO(STB_GLOBAL,STT_FUNC)
	db 0
	dw 0
	dq 0
	dq 0

hashtab:
	dd 1   ; nbucket
	dd 2   ; nchain
	dd 1   ; bucket[]
	dd 0,0 ; chain[]

relatab:
	dq exit_addr
	dq ELF64_R_INFO(1,R_X86_64_JUMP_SLOT)
	dq 0
relatab_len equ $ - relatab

entry:
	mov rdi, 42
	call exit_call

exit_call:
	mov rax, qword $
	exit_addr equ $ - 8
	call rax

file_len equ $ - $$
