#!Makefile

# Makefile of Hurlex97, Chen

# C sources: find .c
C_SOURCES = $(shell find . -name "*.c") 
# C objects
C_OBJECTS = $(patsubst %.c, %.o, $(C_SOURCES))
# Shell sources
S_SOURCES = $(shell find . -name "*.s")
# Shell objects 
S_OBJECTS = $(patsubst %.s, %.o, $(S_SOURCES))

CC = gcc
# ld: linker command in Unix or Unix-like system
# In computing, a linker or link editor is a computer program 
# that takes one or more object files generated by a compiler 
# and combines them into a single executable file, library file, 
# or another object file.
LD = ld
# The Netwide Assembler(NASM)
ASM = nasm

# gcc parameters: http://gcc.gnu.org/
# -c: .c file only
# -Wall: waring all; -m32: machine 32bit; -ggdb: use gdb; 
# -gstabs+: debug info in stabs+ format; 
# -nostdinc: find header files through the dir assigned by -l parm
# -fno-builtin: built in function; -fno-stack-protector: stack protect
# -I: assign the first director to search for
C_FLAGS = -c -Wall -m32 -ggdb -gstabs+ -nostdinc -fno-builtin -fno-stack-protector -I include

# ld parameters: https://linux.die.net/man/1/ld
# -T: Use scriptfile as the linker script
# -m: Emulate the emulation linker
# -nostdlib: Only search library directories explicitly specified on the command line
# Hint: ELF = Executable and Linkable Format; It can be identified by GRUB.
LD_FLAGS = -t scripts/kernel.ld -m elf_i386 -nostdlib

# NASM Assembler parameters: http://www.nasm.us/xdoc/2.12.02/html/nasmdoc0.html
# -f: Specifying the Output File Format
# -g: Enabling Debug Information
# -F: Selecting a Debug Information Format
ASM_FLAGS = -f elf -g -F stabs

# all: => assign the make target
all: $(S_OBJECTS) $(C_OBJECTS) link update_image

# make = compile the .c file and .s file + link these file into executable file
.c.o:
	@echo 编译代码文件 $< ...
	$(CC) $(C_FLAGS) $< -o $@

.s.o:
	@echo 编译汇编文件 $< ...
	$(ASM) $(ASM_FLAGS) $<
	
link:
	@echo 链接内核文件...
	$(LD) $(LD_FLAGS) $(S_OBJECTS) $(C_OBJECTS) -o hx_kernel

# make clean
.PHONY:clean
clean:
	$(RM) $(S_OBJECTS) $(C_OBJECTS) hx_kernel

# make update_image
.PHONY:update_image
update_image:
	sudo mount floppy.img /mnt/kernel
	sudo cp hx_kernel /mnt/kernel/hx_kernel
	sleep 1
	sudo umount /mnt/kernel

# make mount_image
.PHONY:mount_image
mount_image:
	sudo mount floppy.img /mnt/kernel

# make umount_image
.PHONY:umount_image
umount_image:
	sudo umount /mnt/kernel

# make qemu
.PHONY:qemu
qemu:
	qemu -fda floppy.img -boot a

# make bochs
.PHONY:bochs
bochs:
	bochs -f scripts/bochsrc.txt

# make debug
.PHONY:debug
debug:
	qemu -S -s -fda floppy.img -boot a &
	sleep 1
	cgdb -x scripts/gdbinit
