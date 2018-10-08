; 500H     ------------
;          |   stack   | 29.75K
; 7C00H    ------------
;          |   boot   | 512
; 7E00H    ------------
;          |  KERNEL  | 64K
; 17E00H   ------------
;
[section .text]

global _start

BASE_OF_STACK equ 0x7C00 ;栈顶
SELF_CS equ 7E0H ;当前程序的段基址
GDT_SEL_KERNEL_CODE equ 0x8|SA_RPL0 ;因为loader的 GDT_SEL_CODE 选择子为 8
GDT_SEL_KERNEL_DATA equ 0x10|SA_RPL0
GDT_SEL_VIDEO equ 0x18|SA_RPL3
GDT_SEL_USER_CODE equ 0x20|SA_RPL3
GDT_SEL_USER_DATA equ 0x28|SA_RPL3
GDT_SEL_TSS equ 0x30
; SELF_ES equ 17E00H ;当前程序的段基址

%include "include/pm.inc"
%include "include/func.inc"

; extern moveGdt
; extern gdt_ptr
; extern gdt
extern exception_handler
extern cstart
extern SelectorTss

global gdt
global gdt_ptr
global idt
global idt_ptr

;默认中断向量
global	divide_error
global	single_step_exception
global	nmi
global	breakpoint_exception
global	overflow
global	bounds_check
global	inval_opcode
global	copr_not_available
global	double_fault
global	copr_seg_overrun
global	inval_tss
global	segment_not_present
global	stack_exception
global	general_protection
global	page_fault
global	copr_error

gdt times 128*64 db 3
GdtLen equ $-gdt

gdt_ptr dw 0
gdt_ptr_base dd 0

idt:
; %rep 255
; Gate GDT_SEL_KERNEL_CODE, 2, 0, DA_386IGate
; %endrep
times 256*64 db 2
IdtLen equ $-idt

idt_ptr dw IdtLen-1
idt_ptr_base dd idt

[BITS 32]
_start:
    mov esp, BASE_OF_STACK
    ; mov eax, SELF_CS

    sgdt [gdt_ptr]
    call moveGdt
    lgdt [gdt_ptr]

    lidt [idt_ptr]

    jmp GDT_SEL_KERNEL_CODE:test ;强制刷新

moveGdt:
    movzx eax, word[gdt_ptr]
    push eax ;size

    mov eax, dword[gdt_ptr_base]
    push eax ;src
    
    mov eax, gdt
    push eax ;dst
    
    call MemCpy
    add esp, 12

    mov ax, GdtLen
    mov word[gdt_ptr], ax

    mov eax, gdt
    mov dword[gdt_ptr_base], eax
    ret

extern exception_handler
; 中断和异常 -- 异常
divide_error:
	push	0xFFFFFFFF	; no err code
	push	0		; vector_no	= 0
	jmp	exception
single_step_exception:
	push	0xFFFFFFFF	; no err code
	push	1		; vector_no	= 1
	jmp	exception
nmi:
	push	0xFFFFFFFF	; no err code
	push	2		; vector_no	= 2
	jmp	exception
breakpoint_exception:
	push	0xFFFFFFFF	; no err code
	push	3		; vector_no	= 3
	jmp	exception
overflow:
	push	0xFFFFFFFF	; no err code
	push	4		; vector_no	= 4
	jmp	exception
bounds_check:
	push	0xFFFFFFFF	; no err code
	push	5		; vector_no	= 5
	jmp	exception
inval_opcode:
	push	0xFFFFFFFF	; no err code
	push	6		; vector_no	= 6
	jmp	exception
copr_not_available:
	push	0xFFFFFFFF	; no err code
	push	7		; vector_no	= 7
	jmp	exception
double_fault:
	push	8		; vector_no	= 8
	jmp	exception
copr_seg_overrun:
	push	0xFFFFFFFF	; no err code
	push	9		; vector_no	= 9
	jmp	exception
inval_tss:
	push	10		; vector_no	= A
	jmp	exception
segment_not_present:
	push	11		; vector_no	= B
	jmp	exception
stack_exception:
	push	12		; vector_no	= C
	jmp	exception
general_protection:
	push	13		; vector_no	= D
	jmp	exception
page_fault:
	push	14		; vector_no	= E
	jmp	exception
copr_error:
	push	0xFFFFFFFF	; no err code
	push	16		; vector_no	= 10h
	jmp	exception

exception:
	call exception_handler
	add	esp, 4*2	; 让栈顶指向 EIP，堆栈中从顶向下依次是：EIP、CS、EFLAGS
	hlt

test:
    call cstart
    ; mov eax, GDT_SEL_USER_DATA
    ; mov ds, eax
    ; mov word[ds:0x27a00], 0x3355
    ; jmp $
    ; int 6
    mov ax, GDT_SEL_TSS
    ltr ax
    
    push GDT_SEL_USER_DATA
    push 0x7C00
    push GDT_SEL_USER_CODE
    push ring3
    retf
    jmp $

ring3:
    mov ax, GDT_SEL_VIDEO
    mov gs, ax
    mov edi, (80*14+20)*2
    mov ah, 0ch
    mov al, '3'
    mov [gs:edi], ax
    ; mov eax, GDT_SEL_USER_DATA
    ; mov ds, eax
    ; mov word[0x27a00], 0x3355
    jmp $

