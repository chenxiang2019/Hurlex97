; ==================================================================
;
;   boot.s -- 内核从这里开始
;   Moved by Chen, 2017.4.15
;
; ==================================================================

; ==================================================================
;   Hint: x86伪指令集，有一些非标准的汇编指令
; ==================================================================

; ==================================================================
; Assembler Instructions:
; equ : equal
; dd  : define the number of double word format
; ==================================================================

; ==================================================================
; 符合Multiboot规范的 OS 映象需要这样一个 magic Multiboot 头
; Multiboot 头的分布必须如下表所示：
; ==================================================================
; 偏移量  类型  域名        备注
;
;   0     u32   magic       必需
;   4     u32   flags       必需 
;   8     u32   checksum    必需 
; ==================================================================
; 我们只使用到这些就够了，更多的详细说明请参阅 GNU 相关文档
; ==================================================================

; ==================================================================
; [Need] Multiboot/Magic: 魔数，由规范决定的
; ==================================================================
MBOOT_HEADER_MAGIC equ 0x1BADB002

; ==================================================================
; flags域 指出OS映像需要引导程序提供或支持的特性，即内核配置。
; 0-15位指出需求：如果引导程序发现某些值被设置但出于某种原因不理解或不能不能满足
; 相应的需求，它必须告知用户并宣告引导失败。16-31位指出可选的特性：如果引导程序不
; 能支持某些位，它可以简单的忽略它们并正常引导。自然，所有flags字中尚未定义的位必
; 须被置为0。这样，flags域既可以用于版本控制也可以用于简单的特性选择。
; ==================================================================

; ==================================================================
; 0 号位表示所有的引导模块将按页(4KB)边界对齐
; 1 << 0: 
; 0000 0000 0000 0000 0000 0000 0000 0001 =>
; 0000 0000 0000 0000 0000 0000 0000 0010
; ==================================================================
MBOOT_PAGE_ALIGN equ 1 << 0

; ==================================================================
; 1 号位通过 Multiboot 信息结构的 mem_* 域包括可用内存的信息
; (告诉GRUB把内存空间的信息包含在Multiboot信息结构中)
; ==================================================================
MBOOT_MEM_INFO equ 1 << 1

; ==================================================================
; [Need] flags: 定义我们使用的 Multiboot 的标记
; ==================================================================
MBOOT_HEADER_FLAGS equ MBOOT_PAGE_ALIGN | MBOOT_MEM_INFO

; ==================================================================
; [Need] checksum: 是一个32位的无符号值，当与其他的magic域(也就是magic
; 和flags)相加时，要求其结果必须是32位的无符号值 0 (即magic+flags+checksum 
; = 0)
; ==================================================================
MBOOT_CHECKSUM equ -(MBOOT_HEADER_MAGIC+MBOOT_HEADER_FLAGS)

[BITS 32]                       ; 所有代码以 32-bit 的方式编译


section .text                   ; 代码段从这里开始

; ==================================================================
; 在代码段的起始位置设置符合 Multiboot 规范的标记
; ==================================================================

dd MBOOT_HEADER_MAGIC           ; GRUB 会通过这个魔数判断该映像是否支持
dd MBOOT_HEADER_FLAGS           ; GRUB 的一些加载时选项，其详细注释在定义处
dd MBOOT_CHECKSUM               ; 检测数值，其含义在定义处

[GLOBAL start]                  ; 向外部声明内核代码入口，此处提供该声明给链接器
[GLOBAL glb_mboot_ptr]          ; 向外部声明 struct multiboot * 变量
[EXTERN kern_entry]             ; 声明内核 C 代码的入口函数

; ==================================================================
; Start Function
; ==================================================================

start:
    cli                         ; 此时还没有设置好保护模式的中断处理, 
                                ; 所以必须关闭中断
    mov esp, STACK_TOP          ; 设置内核栈地址
    mov ebp, 0                  ; 帧指针修改为 0
    and esp, 0FFFFFFF0H         ; 栈地址按照16字节对齐
    
    mov [glb_mboot_ptr], ebx    ; 将 ebx 中存储的指针存入全局变量
                                ; see: multiboot.h elf.h elf.c 
    
    call kern_entry             ; 调用内核入口函数

; ==================================================================
; Stop Function
; ==================================================================

stop:
    hlt                         ; 停机指令，可以降低 CPU 功耗
    jmp stop                    ; 到这里结束，关机什么的后面再说


section .bss                    ; 未初始化的数据段从这里开始

stack:
    resb 32768                  ; 这里作为内核栈
    
glb_mboot_ptr:                  ; 全局的 multiboot 结构体指针
    resb 4

STACK_TOP equ $-stack-1         ; 内核栈顶，$ 符指代是当前地址
