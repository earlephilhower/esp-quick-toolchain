#!/bin/bash

ext=$1
for i in _fixunsdfsi.o _addsubsf3.o _fixunssfsi.o _addsubdf3.o _muldf3.o _divdf3.o _fixdfsi.o _truncdfsf2.o _extendsfdf2.o _divsi3.o _udivsi3.o _umodsi3.o _floatsisf.o _floatsidf.o _umulsidi3.o _divdi3.o _muldi3.o _mulsf3.o; do
	./xtensa-lx106-elf.x86_64/bin/xtensa-lx106-elf-gcc-ar d ./xtensa-lx106-elf${ext}/lib/gcc/xtensa-lx106-elf/9.1.0/libgcc.a $i
done
