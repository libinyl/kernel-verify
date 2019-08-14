OBJDIR := obj

ifeq ($(V),1)
override V =
endif
ifeq ($(V),0)
override V = @
endif

LABSETUP ?= ./

TOP = .

# QEMU 选项
QEMU := qemu-system-i386

# gcc 选项
GCCPREFIX := i386-elf-
CC	:= $(GCCPREFIX)gcc -pipe
AS	:= $(GCCPREFIX)as
LD	:= $(GCCPREFIX)ld
OBJCOPY	:= $(GCCPREFIX)objcopy
OBJDUMP	:= $(GCCPREFIX)objdump
NM	:= $(GCCPREFIX)nm

# 本地命令
NCC	:= gcc $(CC_VER) -pipe
NATIVE_CFLAGS := $(CFLAGS) $(DEFS) $(LABDEFS) -I$(TOP) -MD -Wall
TAR	:= gtar
PERL:= perl


# 编译器选项
# -fno-builtin is required to avoid refs to undefined functions in the kernel.
# Only optimize to -O1 to discourage inlining, which complicates backtraces.
CFLAGS := $(CFLAGS) $(DEFS) $(LABDEFS) -O1 -fno-builtin -I$(TOP) -MD
CFLAGS += -fno-omit-frame-pointer
CFLAGS += -std=gnu99
CFLAGS += -static
CFLAGS += -Wall -Wno-format -Wno-unused -Werror -gstabs -m32
# -fno-tree-ch prevented gcc from sometimes reordering read_ebp() before
# mon_backtrace()'s function prologue on gcc version: (Debian 4.7.2-5) 4.7.2
CFLAGS += -fno-tree-ch

# 如果 -fno-stack-protector 选项存在就加上.
CFLAGS += $(shell $(CC) -fno-stack-protector -E -x c /dev/null >/dev/null 2>&1 && echo -fno-stack-protector)

# 连接器选项
LDFLAGS := -m elf_i386

GCC_LIB := $(shell $(CC) $(CFLAGS) -print-libgcc-file-name)

# Lists that the */Makefrag makefile fragments will add to
OBJDIRS :=

# Make sure that 'all' is the first target
all: $(OBJDIR)/boot/boot
	

# Eliminate default suffix rules
.SUFFIXES:

# Delete target files if there is an error (or make is interrupted)
.DELETE_ON_ERROR:

# .PRECIOUS: %.o $(OBJDIR)/boot/%.o $(OBJDIR)/kern/%.o \
# 	   $(OBJDIR)/lib/%.o $(OBJDIR)/fs/%.o $(OBJDIR)/net/%.o \
# 	   $(OBJDIR)/user/%.o

KERN_CFLAGS := $(CFLAGS) -DJOS_KERNEL -gstabs
USER_CFLAGS := $(CFLAGS) -DJOS_USER -gstabs


# $(OBJDIR)/.vars.%: FORCE
# 	$(V)echo "$($*)" | cmp -s $@ || echo "$($*)" > $@
# .PRECIOUS: $(OBJDIR)/.vars.%
# .PHONY: FORCE


include boot/Makefrag




clean:
	rm -rf $(OBJDIR) .gdbinit jos.in qemu.log

# This magic automatically generates makefile dependencies
# for header files included from C source files we compile,
# and keeps those dependencies up-to-date every time we recompile.
# See 'mergedep.pl' for more information.
# $(OBJDIR)/.deps: $(foreach dir, $(OBJDIRS), $(wildcard $(OBJDIR)/$(dir)/*.d))
# 	@mkdir -p $(@D)
# 	@$(PERL) mergedep.pl $@ $^

# -include $(OBJDIR)/.deps

# always:
# 	@: