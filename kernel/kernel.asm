; 500H     -------------
;          |user stack | 25.75K
; 6C00H    -------------
;          |kernel stack| 4k
; 7C00H    ------------
;          |   boot   | 512
; 7E00H    ------------
;          |  KERNEL  | 64K
; 17E00H   ------------
;
[section .text]

global _start

; TOP_OF_KERNEL_STACK equ 0x7C00 ;内核栈顶
TOP_OF_KERNEL_STACK equ 0x7C00 ;内核栈顶
TOP_OF_USER_STACK equ 0x6C00 ;用户栈顶
BASE_OF_KERNEL_STACK equ 6C00H ;kernel栈基地址
SELF_CS equ 7E0H ;当前程序的段基址
GDT_SEL_KERNEL_CODE equ 0x8|SA_RPL0 ;因为loader的 GDT_SEL_CODE 选择子为 8
GDT_SEL_KERNEL_DATA equ 0x10|SA_RPL0
GDT_SEL_VIDEO equ 0x18|SA_RPL3
GDT_SEL_USER_CODE equ 0x20|SA_RPL3
GDT_SEL_USER_DATA equ 0x28|SA_RPL3
GDT_SEL_TSS equ 0x30|SA_RPL0
; SELF_ES equ 17E00H ;当前程序的段基址

%include "include/pm.inc"
%include "include/func.inc"

; extern moveGdt
; extern gdt_ptr
; extern gdt
extern exception_handler
extern cstart
extern kernel_main
extern SelectorTss
extern tss
extern irq_table
extern p_proc_ready
extern is_in_int

global gdt
global gdt_ptr
global idt
global idt_ptr

global restart
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
global	hwint00
global	hwint01
global	hwint02
global	hwint03
global	hwint04
global	hwint05
global	hwint06
global	hwint07
global	hwint08
global	hwint09
global	hwint10
global	hwint11
global	hwint12
global	hwint13
global	hwint14
global	hwint15


; extern calltest

extern ss3

gdt times 128*64 db 0
GdtLen equ $-gdt

gdt_ptr dw GdtLen-1
gdt_ptr_base dd gdt
; gdt: Descriptor 0, 0, 0
; gdt_code: Descriptor 0, 0xfffff, DA_CR|DA_32|DA_LIMIT_4K|DA_DPL0
; gdt_data: Descriptor 0, 0xfffff, DA_DRW|DA_32|DA_LIMIT_4K|DA_DPL0
; gdt_video: Descriptor 0B8000h, 0xfffff, DA_DRW|DA_DPL3
; gdt_user_code: Descriptor 0, 0xfffff, DA_CR|DA_32|DA_LIMIT_4K|DA_DPL3
; gdt_user_data: Descriptor 0, 0xfffff, DA_DRW|DA_32|DA_LIMIT_4K|DA_DPL3
; gdt_tss: Descriptor 0xea13, 0x69-1, DA_386TSS
; ; gdt_tst: Gate GDT_SEL_KERNEL_CODE, 0x8aa1f, 0, DA_386CGate | DA_DPL0
; gdt_tst: dw 0x00000	 
; dw 0x8c00	 
; dw 0x0008 
; dw 0xea3f
; GdtLen equ $-gdt
; gdt_ptr dw GdtLen-1
; gdt_ptr_base       dd 0

idt:
; %rep 255
; Gate GDT_SEL_KERNEL_CODE, inval_opcode_limit, 0, DA_386IGate
; %endrep
times 256*64 db 0
IdtLen equ $-idt

idt_ptr dw IdtLen-1
idt_ptr_base dd idt

[BITS 32]
_start:
    mov esp, TOP_OF_KERNEL_STACK
    ; mov eax, SELF_CS

    ; sgdt [gdt_ptr]
	call cstart
    ; call moveGdt
    lgdt [gdt_ptr]
    lidt [idt_ptr]
    jmp GDT_SEL_KERNEL_CODE:csinit ;强制刷新

csinit:
    mov ax, GDT_SEL_TSS
    ltr ax
    jmp kernel_main
    ; push GDT_SEL_USER_DATA
    ; push TOP_OF_USER_STACK
    ; push GDT_SEL_USER_CODE
    ; push ring3
    retf
    jmp $

moveGdt:
    ; movzx eax, word[gdt_ptr]
    ; push eax ;size

    ; mov eax, dword[gdt_ptr_base]
    ; push eax ;src
    
    ; mov eax, gdt
    ; push eax ;dst
    
    ; call memcpy
    ; add esp, 12

    mov ax, GdtLen
    mov word[gdt_ptr], ax

    mov eax, gdt
    mov dword[gdt_ptr_base], eax
    ret

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

%macro	hwint_master 1
    sub esp,4
    pushad
    push ds
    push es
    push fs
    push gs
    mov dx,ss
    mov ds, dx
    mov es,dx

    in al, INT_M_CTLMASK ;屏蔽当前中断
    or al, (1<<%1)
    out INT_M_CTLMASK, al
    mov al, EOI
    out INT_M_CTL, al
    sti

    inc dword[is_in_int]
    cmp dword[is_in_int], 0
    jne ret_to_proc

    mov esp, TOP_OF_KERNEL_STACK

    push %1
	call [irq_table+4*%1]
    ; call clock_handler
	add	esp, 4

    cli
    in al, INT_M_CTLMASK ;恢复当前中断
    and al, ~(1<<%1)
    out INT_M_CTLMASK, al

    push restart
	ret
%endmacro
extern clock_handler
extern keyboard_handler
extern floppy_handler

hwint00:		; Interrupt routine for irq 0 (the clock).
hwint_master 0
    ; sub esp,4
    ; pushad
    ; push ds
    ; push es
    ; push fs
    ; push gs
    ; mov dx,ss
    ; mov ds, dx
    ; mov es,dx

    ; ; inc byte[gs:0]
    ; in al, INT_M_CTLMASK ;屏蔽当前中断
    ; or al, (1<<0)
    ; out INT_M_CTLMASK, al
    ; mov al, EOI
    ; out INT_M_CTL, al
    ; sti

    ; inc dword[is_in_int]
    ; cmp dword[is_in_int], 0
    ; jne ret_to_proc

    ; mov esp, TOP_OF_KERNEL_STACK

    ; ; sti
    ; push 0
    ; call clock_handler
    ; add esp, 4

    ; cli
    ; in al, INT_M_CTLMASK ;恢复当前中断
    ; and al, ~(1<<0)
    ; out INT_M_CTLMASK, al

; ALIGN	16
hwint01:		; Interrupt routine for irq 1 (keyboard)
	hwint_master 1

; ALIGN	16
hwint02:		; Interrupt routine for irq 2 (cascade!)
   hwint_master 2

; ALIGN	16
hwint03:		; Interrupt routine for irq 3 (second serial)
	hwint_master 3

; ALIGN	16
hwint04:		; Interrupt routine for irq 4 (first serial)
	hwint_master 4

; ALIGN	16
hwint05:		; Interrupt routine for irq 5 (XT winchester)
	hwint_master 5

; ALIGN	16
hwint06:		; Interrupt routine for irq 6 (floppy)
	hwint_master 6

; ALIGN	16
hwint07:		; Interrupt routine for irq 7 (printer)
	hwint_master 7

; ---------------------------------
%macro	hwint_slave	1
	push	%1
	; call	spurious_irq
	add	esp, 4
	iretd
%endmacro
; ---------------------------------

; ALIGN	16
hwint08:		; Interrupt routine for irq 8 (realtime clock).
	hwint_slave	8

; ALIGN	16
hwint09:		; Interrupt routine for irq 9 (irq 2 redirected)
	hwint_slave	9

; ALIGN	16
hwint10:		; Interrupt routine for irq 10
	hwint_slave	10

; ALIGN	16
hwint11:		; Interrupt routine for irq 11
	hwint_slave	11

; ALIGN	16
hwint12:		; Interrupt routine for irq 12
	hwint_slave	12

; ALIGN	16
hwint13:		; Interrupt routine for irq 13 (FPU exception)
	hwint_slave	13

; ALIGN	16
hwint14:		; Interrupt routine for irq 14 (AT winchester)
	hwint_slave	14

; ALIGN	16
hwint15:		; Interrupt routine for irq 15
	hwint_slave	15

restart:
    mov	esp, [p_proc_ready]
	lldt [esp + P_LDT_SEL]
	lea	eax, [esp + P_STACKTOP]
	mov	dword [tss + TSS3_S_SP0], eax
ret_to_proc:
    dec dword[is_in_int]
    pop gs
    pop fs
    pop es
    pop ds
    popad
    add esp,4
    iretd

ring3:
	xor eax, eax
	mov ax, GDT_SEL_USER_DATA
	mov ds, ax
	mov es, ax
	mov fs, ax
	; int 6
	; mov eax, tss
	; jmp $
	
    ; call 0x0038:0
	; call GDT_SEL_USER_DATA:calltest
	; call calltest
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



