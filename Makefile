# Omit default rule to rebuild itself
.PHONY: Makefile

# General rule is that CAPITAL variables are constants and can be used
# via $(VARNAME), while lowercase variables are dynamic and need to be
# used via $(call varname,$@) (note no space between comma and $@)

# Directory paths
PWD := $(shell pwd)

REPODIR := $(PWD)/repo
PATCHDIR := $(PWD)/patches
POSTDIR := $(PWD)/post
PKGDIR := $(PWD)/package

ARDUINO ?= $(PWD)/arduino

# Version
SUBREL ?= -testing
REL ?= 4.0.0

# latest GCC release. patch is usually always 0 for latest releases, encoded nonetheless
GCC ?= 14.4

rev = $(shell git -C $(1) rev-parse --short HEAD)
REV ?= $(call rev,$(PWD))

# arduino .json version. probably *should* conform with semver spec, but currently isnt
# assuming builtin tool search prefers boards package over any other, and matching happens lexicographically
# (note that this is THE format used in the esp8266/Arduino package index .json; SUBREL is empty for release)
VERSION := $(REL)$(SUBREL)-gcc$(GCC)-$(REV)

# fixed time value for internal operations on files / fixed package versions
DATESTAMP ?= $(shell date --utc +%y%m%d)
SOURCE_DATE_EPOCH ?= $(shell date --utc --date=$(DATESTAMP) +%s)

# For downloading FROM Github, only GHUSER must be set
# For uploading TO Github, both GHUSER and GHTOKEN must be set
# Guard for both to avoid duplicating errors down below
GHUSER ?= $(or $(shell cat .ghuser),$(error Need to specify Github username on the command line as "GHUSER=xxxx" or in .ghuser))
GHTOKEN ?= $(or $(shell cat .ghtoken),$(error Need to specify Github Personal Access Token on the command line "GHTOKEN=xxxx" or in .ghtoken))

# Different GCC versions depend on different support libraries & packages versions
ifeq ($(GCC), 4.8)
    ISL_VER       := 0.12.2
    GCC_REF       := call0-4.8.2
    GCC_PKGREL    := 40802
    GCC_REPO      := https://github.com/$(GHUSER)/gcc-xtensa.git
    GCC_DIR       := gcc
    BINUTILS_REF  := master
    BINUTILS_REPO := https://github.com/$(GHUSER)/binutils-gdb-xtensa.git
    BINUTILS_DIR  := binutils-gdb
else ifeq ($(GCC), 4.9)
    ISL_VER       := 0.12.2
    GCC_REF       := call0-4.9.2
    GCC_PKGREL    := 40902
    GCC_REPO      := https://github.com/$(GHUSER)/gcc-xtensa.git
    GCC_DIR       := gcc
    BINUTILS_REF  := master
    BINUTILS_REPO := https://github.com/$(GHUSER)/binutils-gdb-xtensa.git
    BINUTILS_DIR  := binutils-gdb
else ifeq ($(GCC), 5.2)
    ISL_VER       := 0.12.2
    GCC_REF       := xtensa-ctng-esp-5.2.0
    GCC_REPO      := https://github.com/$(GHUSER)/gcc-xtensa.git
    GCC_DIR       := gcc
    BINUTILS_REF  := master
    BINUTILS_REPO := https://github.com/$(GHUSER)/binutils-gdb-xtensa.git
    BINUTILS_DIR  := binutils-gdb
else ifeq ($(GCC), 7.2)
    ISL_VER       := 0.16.1
    GCC_REF       := xtensa-ctng-7.2.0
    GCC_REPO      := https://github.com/$(GHUSER)/gcc-xtensa.git
    GCC_DIR       := gcc
    BINUTILS_REF  := master
    BINUTILS_REPO := https://github.com/$(GHUSER)/binutils-gdb-xtensa.git
    BINUTILS_DIR  := binutils-gdb
else ifeq ($(GCC), 9.1)
    ISL_VER       := 0.18
    GCC_REF       := gcc-9_1_0-release
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_32
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else ifeq ($(GCC), 9.2)
    ISL_VER       := 0.18
    GCC_REF       := gcc-9_2_0-release
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_32
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else ifeq ($(GCC), 9.3)
    ISL_VER       := 0.18
    GCC_REF       := releases/gcc-9.3.0
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_32
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else ifeq ($(GCC), 10.1)
    ISL_VER       := 0.18
    GCC_REF       := releases/gcc-10.1.0
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_32
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else ifeq ($(GCC), 10.2)
    ISL_VER       := 0.18
    GCC_REF       := releases/gcc-10.2.0
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_32
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else ifeq ($(GCC), 10.3)
    ISL_VER       := 0.18
    GCC_REF       := releases/gcc-10.3.0
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_32
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else ifeq ($(GCC), 11.1)
    ISL_VER       := 0.18
    GCC_REF       := releases/gcc-11.1.0
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_32
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else ifeq ($(GCC), 14.4)
    ISL_VER       := 0.24
    GCC_REF       := releases/gcc-14.4.0
    GCC_REPO      := https://gcc.gnu.org/git/gcc.git
    GCC_DIR       := gcc-gnu
    BINUTILS_REF  := binutils-2_47
    BINUTILS_REPO := https://sourceware.org/git/binutils-gdb.git
    BINUTILS_DIR  := binutils-gdb-gnu
else
    $(error Need to specify a supported GCC version "GCC={4.8, 4.9, 5.2, 7.2, 9.3, 10.1, 10.2, 10.3, 14.4}")
endif

# gcc version below 5 have a special treatment
GCC_MAJOR := $(firstword $(subst ., ,$(GCC)))

# PlatformIO MINOR semantic version component, encoding current GCC release
# xxx: pio version integer encoding / decoding is limited to 2...6 digit range
# although, failing it would just print an ugly version instead of a nice one
piominor = $(shell printf "%d%02d%02d" $(subst ., ,$(1)))
GCC_PKGREL ?= $(call piominor,$(GCC))

# MAJOR follows our REL major integer
# MINOR encodes specific GCC version aka "original package version"
# PATCH is just DATESTAMP
PKGREL_MAJOR ?= $(firstword $(subst ., ,$(REL)))

# PlatformIO package release version
PKGREL ?= $(PKGREL_MAJOR).$(GCC_PKGREL).$(DATESTAMP)$(SUBREL)+git$(REV)

# cross-compilation triple
TARGET_ARCH := xtensa-lx106-elf

# external dependencies based on git, helpfully named for variable extraction

gcc_DIR := $(GCC_DIR)
gcc_REPO = $(GCC_REPO)
gcc_REF := $(GCC_REF)

binutils_DIR := $(BINUTILS_DIR)
binutils_REPO := $(BINUTILS_REPO)
binutils_REF := $(BINUTILS_REF)

# shared newlib package, expected to be built once after linux toolchain is ready
newlib_DIR := newlib
newlib_REPO := https://github.com/$(GHUSER)/newlib-xtensa.git
newlib_REF := xtensa-4_5_0-lock-arduino

# shared hal package, expected to be built once after linux toolchain is ready
lx106-hal_DIR := lx106-hal
lx106-hal_REPO := https://github.com/$(GHUSER)/lx106-hal.git
lx106-hal_REF := e4bcc63c9c016e4f8848e7e8f512438ca857531d

# extra packages intended for the target system, no need for cross-toolchain
# TODO: split into a separate mkfile and build both lfs versions, let arduino repo handle seamless migration
# MKSPIFFS must stay at 0.2.0 until Arduino boards.txt.py fixes non-page-aligned sizes
mkspiffs_REPO := https://github.com/$(GHUSER)/mkspiffs.git
mkspiffs_REF := 0.2.0
mkspiffs_VER := $(mkspiffs_REF)
mkspiffs_DIR := mkspiffs

# MKLITTLEFS must be in sync with the Arduino littlefs version
# 4.x.x pins littlefs==2.9.3, which cannot be read by littlefs<2.6.0
mklittlefs_REPO := https://github.com/$(GHUSER)/mklittlefs.git
mklittlefs_REF := 4.0.2-littlefs251
mklittlefs_VER := 4.0.2
mklittlefs_DIR := mklittlefs

# DEPRECATED 0.4.13 w/ cross-compilation adjustments
esptool_REPO := https://github.com/$(GHUSER)/esptool-ck.git
esptool_REF := f80ae31d3b99eee41bd6a7fe6fdf4f889c1dc59b
esptool_VER := 0.4.13
esptool_DIR := esptool

# external dependencies fetched as release blobs
PACKAGES := gmp isl libexpat mpc mpfr ncurses

# GNU GDB & the rest of external dependencies which are used for binutils and gcc builds
isl_VER := $(ISL_VER)
isl_URL := https://gcc.gnu.org/pub/gcc/infrastructure/isl-$(isl_VER).tar.bz2
isl_DIR := isl-$(isl_VER)

gmp_VER := 6.3.0
gmp_URL := https://gcc.gnu.org/pub/gcc/infrastructure/gmp-$(gmp_VER).tar.bz2
gmp_DIR := gmp-$(gmp_VER)

mpfr_VER := 4.2.2
mpfr_URL := https://gcc.gnu.org/pub/gcc/infrastructure/mpfr-$(mpfr_VER).tar.bz2
mpfr_DIR := mpfr-$(mpfr_VER)

mpc_VER := 1.3.1
mpc_URL := https://gcc.gnu.org/pub/gcc/infrastructure/mpc-$(mpc_VER).tar.gz
mpc_DIR := mpc-$(mpc_VER)

# libexpat release tagging works a bit weird
libexpat_VER := 2.9.0
libexpat_REV := R_$(subst .,_,$(libexpat_VER))
libexpat_URL := https://github.com/libexpat/libexpat/releases/download/$(libexpat_REV)/expat-$(libexpat_VER).tar.bz2
libexpat_DIR := expat-$(libexpat_VER)

# ncurses releases are sometimes just periodic snapshots
ncurses_VER := 41553966d3ac468f9fff0b63f98841aefb0cb04e
ncurses_URL := https://github.com/ThomasDickey/ncurses-snapshots/archive/$(ncurses_VER).zip
ncurses_DIR := ncurses-snapshots-$(ncurses_VER)

# TODO: only used for gcc4.x builds
cloog_VER := 0.18.1
cloog_URL := https://gcc.gnu.org/pub/gcc/infrastructure/cloog-$(cloog_VER).tar.gz
cloog_DIR := cloog-$(cloog_VER)

ifeq ($(GCC_MAJOR), 4)
	PACKAGES += cloog
endif

# LTO doesn't work on 4.8, may not be useful later
lto ?= false
LTO := $(or $(lto),false)

# Currently supported targets
BUILD_TARGETS := LINUX LINUX32 ARM64 RPI WIN64 WIN32 MACOSARM MACOSX86

# Assume .gz is the compression of choice for most systems
# * .zst is the fastest compression and on par with .gz size;
#   arduino-cli implements this in the shipped binary and expected to work
#   platformio depends on technically optional, but common enough libzstd support in the tarfile module
# * .bz2 is moderately better at compression than .gz, but is slower
#   like .gz, supported by both build systems
# * .xz is much better at compression than all options above, but awfully slow
#   like .gz & .bz2, supported by both build systems

# ref. https://reproducible-builds.org/docs/archives
# remove any extra attributes and use fixed filemode and ownership info
tar_PRE := :
tar_CMD := tar
tar_OPT := \
	--sort=name \
	--mtime='@$(SOURCE_DATE_EPOCH)' \
	--owner=0 \
	--group=0 \
	--numeric-owner \
	--pax-option=exthdr.name=%d/PaxHeaders/%f,delete=atime,delete=ctime \
	--gzip \
	--create \
	--file
tar_EXT := .tar.gz

# .zip only for Windows targets
# ref. https://reproducible-builds.org/docs/archives/#zip-files
zip_PRE := \
	find ./ -print0 | xargs -0r touch --time=mtime --no-dereference --date='@$(SOURCE_DATE_EPOCH)'
zip_CMD := zip
zip_OPT := \
	--quiet \
	--recurse-paths \
	--strip-extra
zip_EXT := .zip

# Define the build and output naming, don't use directly (see below)
# Currently not using ..._STATIC / -Wl,-static, its up to the tools
#
# ..._HOST    - build system target triplet
# ..._AHOST   - arduino manifest architecture name
# ..._ASYS    - platformio manifest system name(s)
# ..._EXT     - toolchain name suffix
# ..._EXE     - toolchain executable files suffix
# ..._MKTGT   - tool target os hint
# ..._ARCHIVE - release archive&compression tool (optional, see $(ARCHIVE); TAR by default)
#
LINUX_HOST   := x86_64-linux-gnu
LINUX_AHOST  := x86_64-pc-linux-gnu
LINUX_ASYS   := linux_x86_64
LINUX_EXT    := .x86_64
LINUX_EXE    :=
LINUX_MKTGT  := linux

LINUX32_HOST   := i686-linux-gnu
LINUX32_AHOST  := i686-pc-linux-gnu
LINUX32_ASYS   := linux_i686
LINUX32_EXT    := .i686
LINUX32_EXE    :=
LINUX32_MKTGT  := linux

ARM64_HOST   := aarch64-linux-gnu
ARM64_AHOST  := aarch64-linux-gnu
ARM64_ASYS   := linux_aarch64
ARM64_EXT    := .arm64
ARM64_EXE    :=
ARM64_MKTGT  := linux

RPI_HOST   := arm-linux-gnueabihf
RPI_AHOST  := arm-linux-gnueabihf
RPI_ASYS   := linux_armv6l linux_armv7l
RPI_EXT    := .rpi
RPI_EXE    :=
RPI_MKTGT  := linux

WIN64_HOST    := x86_64-w64-mingw32
WIN64_AHOST   := x86_64-mingw32
WIN64_ASYS    := windows_amd64
WIN64_EXT     := .win64
WIN64_EXE     := .exe
WIN64_MKTGT   := windows
WIN64_ARCHIVE := zip

WIN32_HOST    := i686-w64-mingw32
WIN32_AHOST   := i686-mingw32
WIN32_ASYS    := windows_x86
WIN32_EXT     := .win32
WIN32_EXE     := .exe
WIN32_MKTGT   := windows
WIN32_ARCHIVE := zip

MACOSX86_HOST   := x86_64-apple-darwin20.4
MACOSX86_AHOST  := x86_64-apple-darwin
MACOSX86_ASYS   := darwin_x86_64
MACOSX86_EXT    := .macosx86
MACOSX86_EXE    :=
MACOSX86_MKTGT  := macosx86

# 1. --disable-lto , per immediately broken mpfr & lto-plugin builds
#    also disabled in pico toolchain, which uses the same osxcross dist
# 2. macOS cross tools have to be explicitly stated when configuring build env
#    host & target arch autodetection does not work for some reason and uses local gcc instead
MACOSX86_CC := $(MACOSX86_HOST)-cc
MACOSX86_CXX := $(MACOSX86_HOST)-c++
MACOSX86_STRIP := $(MACOSX86_HOST)-strip

MACOSX86_CONFIGURE_FLAGS := \
	--disable-lto \
	CC=$(MACOSX86_CC) \
	CXX=$(MACOSX86_CXX)

# 3. bump default deployment target from 10.9 to 10.13, to fix at least one instance of syscall incompatibility
#    alternative would be to keep the original target and to hide `utimensat` through `./configure ac_cv_func_utimensat=no ...`
#    since ./configure function detection does not care about SDK target warnings
#    (nb. MACOSARM SDK target is already higher than 10.13, and this error was already ignored when previously building w/ gcc instead of clang)
# >   CC       rename.o
# > /workdir/repo/binutils-gdb-gnu/binutils/rename.c:176:12: error: 'utimensat' is only available on macOS 10.13 or newer [-Werror,-Wunguarded-availability-new]
# >  result = utimensat (AT_FDCWD, destination, times, 0);
# >           ^~~~~~~~~
MACOSX86_SETENV := \
	MACOSX_DEPLOYMENT_TARGET="10.13"

MACOSARM_HOST   := aarch64-apple-darwin20.4
MACOSARM_AHOST  := arm64-apple-darwin
MACOSARM_ASYS   := darwin_arm64
MACOSARM_EXT    := .macosarm
MACOSARM_EXE    :=
MACOSARM_MKTGT  := macosarm

# 4. strip cannot happen, some build scripts forcibly remove signature data
# > aarch64-apple-darwin20.4-strip: warning: changes being made to the file will invalidate the code signature in ...
MACOSARM_CC := $(MACOSARM_HOST)-cc
MACOSARM_CXX := $(MACOSARM_HOST)-c++
MACOSARM_STRIP := touch

MACOSARM_CONFIGURE_FLAGS := \
	--disable-lto \
	CC=$(MACOSARM_CC) \
	CXX=$(MACOSARM_CXX) \
	STRIP=$(MACOSARM_STRIP)

# For .foo.%.bar recipe, where % is target architecture
# (vs. $*, useful for both implicit and explicit targets)
stem = $(subst .,,$(suffix $(basename $(1))))
arch = $(call stem,$(1))

# Call with $@ to get the appropriate variable for this architecture
host   = $($(call arch,$(1))_HOST)
ahost  = $($(call arch,$(1))_AHOST)
asys   = $($(call arch,$(1))_ASYS)
ext    = $($(call arch,$(1))_EXT)
exe    = $($(call arch,$(1))_EXE)
mktgt  = $($(call arch,$(1))_MKTGT)

archivepre = $(or $($($(call arch,$(1))_ARCHIVE)_PRE),$(tar_PRE))
archivecmd = $(or $($($(call arch,$(1))_ARCHIVE)_CMD),$(tar_CMD))
archiveopt = $(or $($($(call arch,$(1))_ARCHIVE)_OPT),$(tar_OPT))
archiveext = $(or $($($(call arch,$(1))_ARCHIVE)_EXT),$(tar_EXT))

# DO NOT generate log files w/ NOLOG=1
# expected to be at the end of *some* command printing to stdout/stderr
ifeq ($(NOLOG),)
	log_stage = > log$(1) 2>&1
	log = >> log$(1) 2>&1
else
	log_stage :=
	log :=
endif

# sometimes called for setenv
archsetenv = $($(call arch,$(1))_SETENV)

# sometimes called for ./configure
configure_flags = $($(call arch,$(1))_CONFIGURE_FLAGS)

# The build directory per architecture
arena = $(PWD)/arena$(call ext,$(1))
# This installation directory for this architecture
install = $(PWD)/$(TARGET_ARCH)$($(call arch,$(1))_EXT)
# Shared libraries build prefix
cross = $(call arena,$(1))/cross
ldflags = -L$(call cross,$(1))/lib
cflags = -I$(call cross,$(1))/include

# GCC et. al configure options
CONFIGURE := \
	--disable-__cxa_atexit \
	--disable-bootstrap \
	--disable-libgomp \
	--disable-libmudflap \
	--disable-libstdcxx-verbose \
	--disable-multilib \
	--disable-nls \
	--disable-shared \
	--enable-languages=c,c++ \
	--enable-lto \
	--enable-static=yes \
	--enable-threads=no \
	--with-newlib

DUMPMACHINE := $(shell gcc -dumpmachine)
configure = \
	$(CONFIGURE) \
	--build=$(DUMPMACHINE) \
	--host=$(call host,$(1)) \
	$(call configure_flags,$(1))

configure_cross = \
	--target=$(call host,$(1)) \
	--prefix=$(call arena,$(1))/cross \
	$(call configure,$(1))

configure_target = \
	--target=$(TARGET_ARCH) \
	--prefix=$(call install,$(1)) \
	$(call configure,$(1))

# previously applied through patches/gcc$(GCC)/gcc-eh-alloc.patch
ifeq ($(GCC), 14.4)
CONFIGURE_EH_POOL := \
	--enable-libstdcxx-static-eh-pool \
	--with-libstdcxx-eh-pool-obj-count=4
else
CONFIGURE_EH_POOL :=
endif

# shared gmp stack dependency

# ./configure cannot test .s w/ osxcross toolchain
MACOSX86_GMP_CONFIGURE_FLAGS := --disable-assembly
MACOSARM_GMP_CONFIGURE_FLAGS := $(MACOSX86_GMP_CONFIGURE_FLAGS)

configure_gmp = \
	$(call configure_cross,$(1)) \
	$($(call arch,$(1))_GMP_CONFIGURE_FLAGS)

configure_with_gmp = \
	--with-gmp=$(call arena,$(1))/cross \
	--with-mpfr=$(call arena,$(1))/cross \
	--with-mpc=$(call arena,$(1))/cross

# graphite support for binutils & gcc
configure_with_isl = \
	--with-isl=$(call arena,$(1))/cross

# --without-termlib
#   merge tinfo.a and ncurses.a, since there is no pkgconfig to hint the linker about the 2nd one,
#   binutils would break when attempting to test it w/o linking *both* tinfo.a and ncurses.a
#   (...but even then, host ncursesw.a might precedence if not careful)
#
# --enable-termcap
#   fallback support so we don't depend on tinfo database
#   note that this *must* read existing database from somewhere, either host or cross that was previously built w/o fallbacks
#
# --enable-widec
#   enabled by default since ncurses-6.5, ensure existing database files *could* be
#   converted into fallback (verify arena*/ncurses/ncurses/fallback.c after build)
#   currently, this only affects xterm* terminfos
#
CONFIGURE_NCURSES := \
	--disable-home-terminfo \
	--disable-overwrite \
	--disable-stripping \
	--enable-pc-files \
	--enable-symlinks \
	--enable-widec \
	--with-build-cppflags=-D_GNU_SOURCE \
	--with-normal \
	--without-ada \
	--without-big-core \
	--without-debug \
	--without-manpages \
	--without-profile \
	--without-shared \
	--without-tack \
	--without-termlib \
	--without-tests

# --enable-sp-funcs --enable-term-driver
#   available since ncurses-5.8
#
#   > compile  with  terminal-driver. That is used in the
#   > MinGW  port,  and (being somewhat more complicated)
#   > is  an experimental alternative to the conventional
#   > termlib   internals.  Currently,  it  requires  the
#   > sp-funcs feature to be enabled.
#
WIN32_NCURSES_CONFIGURE_FLAGS := \
	--enable-sp-funcs \
	--enable-term-driver

WIN64_NCURSES_CONFIGURE_FLAGS := $(WIN32_NCURSES_CONFIGURE_FLAGS)

configure_ncurses = \
	$(call configure_cross,$(1)) \
	$($(call arch,$(1))_NCURSES_CONFIGURE_FLAGS) \
	$(CONFIGURE_NCURSES) \

# initialize ncurses for host so database & tic could be used later instead of the container one
NCURSES_CONFIGURE_FLAGS_WITH_PROGS := \
	--program-prefix="" \
	--with-fallbacks="" \
	--without-cxx-binding \
	--without-form \
	--without-menu \
	--without-panel \
	--with-progs

# generate static libraries fallbacks built in via termcap
NCURSES_CONFIGURE_FLAGS_WITH_FALLBACKS := \
	--enable-termcap \
	--without-progs \
	--disable-database \
	--disable-db-install \
	--with-fallbacks=xterm,xterm-256color,screen-256color,linux,vt100

CONFIGURE_LIBEXPAT := \
	--without-docbook \
	--without-xmlwf \
	--without-examples \
	--without-tests

CONFIGURE_BINUTILS := \
	--disable-gdb \
	--disable-libquadmath \
	--disable-nls \
	--disable-sim \
	--enable-serial-configure \
	--without-curses \
	--without-python

configure_binutils = \
	$(call configure_target,$(1)) \
	$(call configure_with_gmp,$(1)) \
	$(call configure_with_isl,$(1)) \
	$(CONFIGURE_BINUTILS)

# statically link w/ build host gcc & libstdc++, dont require bundling them near the binar{y,ies}
# TODO: c1a5d03a89a455d79f025c66dce83342de4d26ce introduces --with-static-standard-libraries
# TODO: actually useful for binutils as a whole OR as OR ld OR ... ?
WIN32_BINUTILS_LDFLAGS := \
	-static-libgcc \
	-static-libstdc++

WIN64_BINUTILS_LDFLAGS := $(WIN32_BINUTILS_LDFLAGS)

setenv_binutils = \
	export LDFLAGS="$($(call arch,$(1))_BINUTILS_LDFLAGS) $$LDFLAGS"

# fully static builds broken w/ glibc as libc, just embed up-to-date ncurses & libexpat for the time being
# using something similar to crosstools-ng approach at linking libc & libstdcxx, but just for `ncurses'
CONFIGURE_GDB := \
	--disable-binutils \
	--disable-gas \
	--disable-ld \
	--disable-libquadmath \
	--disable-nls \
	--disable-sim \
	--enable-gdb \
	--enable-serial-configure \
	--enable-tui \
	--with-curses \
	--without-included-gettext \
	--without-python \
	--without-x

# circa July 2020, ncurses separates symbol names for static and dynamic library versions
# neither ./configure --with-build-cppflags=... nor make CPPFLAGS=... work as expected
# ensure this is exported before ./configure (aka toplevel) and make (nested ./configure dispatch)
GDB_CPPFLAGS := -DNCURSES_STATIC

setenv_gdb = \
	export CPPFLAGS="$(GDB_CPPFLAGS) $${CPPFLAGS}"

# --disable-source-highlight
#   ref. https://github.com/crosstool-ng/crosstool-ng/blob/master/scripts/build/debug/300-gdb.sh
#   > libsource-highlight is a dynamic library that uses exception
#   > exceptions are handled by libstdc++
#   > this combination is very buggy, so configure don't use it and abort
#
WIN32_GDB_CONFIGURE_FLAGS := \
	--disable-source-highlight

WIN64_GDB_CONFIGURE_FLAGS := $(WIN32_GDB_CONFIGURE_FLAGS)

configure_gdb = \
	$(call configure_target,$(1)) \
	$(call configure_with_gmp,$(1)) \
	$($(call arch,$(1))_GDB_CONFIGURE_FLAGS) \
	$(CONFIGURE_GDB)

# Newlib configuration common flags
CONFIGURE_NEWLIB := \
	--disable-newlib-supplied-syscalls \
	--disable-newlib-wide-orient \
	--disable-option-checking \
	--disable-shared \
	--enable-multilib \
	--enable-newlib-io-c99-formats \
	--enable-newlib-nano-formatted-io \
	--enable-newlib-reent-small \
	--enable-target-optspace \
	--with-newlib \
	--without-libgloss

# Configuration for newlib normal build
configure_newlib = \
	--target=$(TARGET_ARCH) \
	--prefix=$(call install,$(1)) \
	$(CONFIGURE_NEWLIB)

# The branch in which to store the new toolchain
INSTALL_BRANCH ?= master

# Environment variables for configure and building targets.  Only use $(call setenv,$@)
ifeq ($(LTO),true)
	CFFT_LTO := -flto -Wl,-flto
else ifeq ($(LTO),false)
	CFFT_LTO :=
else
    $(error Need to specify LTO={true,false} on the command line)
endif

CFFT := -mlongcalls $(CFFT_LTO) -Os -g -free -fipa-pta

# Generic opts passed to both CC and CXX
SHARED_OPT_FLAGS := -pipe -g -O2

# arenaX/cross used as system root for building host tools
# linux installation path used as build tools root
SHARED_PATH_BIN := $(call cross,.stage.LINUX.stage)/bin:$(call install,.stage.LINUX.stage)/bin

# Sets the environment variables for a subshell while building
# PATH allows both target cross/ tools and host tools built within the context of cross/
# PKG_CONFIG_... should prevent host system pollution while building & installing packages for cross/
setenv = export \
	$(call archsetenv,$(1)) \
	CFLAGS_FOR_TARGET="$(CFFT)" \
	CXXFLAGS_FOR_TARGET="$(CFFT)" \
	CFLAGS="$(call cflags,$(1)) $(SHARED_OPT_FLAGS) $${CFLAGS}" \
	CXXFLAGS="$(SHARED_OPT_FLAGS) $${CXXFLAGS}" \
	LDFLAGS="$(call ldflags,$(1)) $${LDFLAGS}" \
	PATH="$(call cross,$(1))/bin:$(SHARED_PATH_BIN):$${PATH}" \
	PKG_CONFIG_PATH="" \
	PKG_CONFIG_LIBDIR="$(call cross,$(1))/lib/pkgconfig" \
	PKG_CONFIG_SYSROOT_DIR="$(call cross,$(1))/" \
	LD_LIBRARY_PATH="$(call cross,$(1))/lib:$${LD_LIBRARY_PATH}"

# in case host triplet is missing / cannot be discovered, ensure these are exported
# for some cases, explicit variables are required before and after ./configure
# defaults to gcc-gnu toolchain, modify through target variable when necessary
setenv_cc = export CC=$(or $($(call arch,$(1))_CC),$(call host,$(1))-gcc)
setenv_cxx = export CXX=$(or $($(call arch,$(1))_CXX),$(call host,$(1))-g++)

# *expected* to be available, but not always needed. exported by default, assume targets override when necessary
setenv_strip = export STRIP=$(or $($(call arch,$(1))_STRIP),$(call host,$(1))-strip)

setenv_cross = \
	$(call setenv_cc,$(1)) \
	&& $(call setenv_cxx,$(1)) \
	&& $(call setenv_strip,$(1)) \
	&& $(call setenv,$(1))

# package 1) name 2) desc 3) version 4) architecture(s)
# multiple architectures expected to be passed as a simple words list
__json_space:=$(subst ,, )
__json_sep:=$(subst ,,,\n    )
define make_package_json
{ echo '{'; \
	echo  '  "name": "'$(1)'",'; \
	echo  '  "description": "'$(2)'",'; \
	echo  '  "version": "'$(3)'",'; \
	echo  '  "repository": {'; \
	echo  '    "type": "git",'; \
	echo  '    "url": "https://github.com/$(GHUSER)/esp-quick-toolchain.git"'; \
	echo  '  },'; \
	echo  '  "system": ['; \
	echo  '    $(subst $(__json_space),$(__json_sep),$(patsubst %,"%",$(4)))'; \
	echo  '  ]'; \
	echo '}'; } > package.json
endef

# Generates a JSON fragment for an uploaded release artifact
# archive 1) filename 2) host (aka architecture aka system aka AHOST)
define make_releases_json
archivename=$$(basename $(1)) \
 && archivesize=$$(stat -c%s $(1)) \
 && archivesha256=$$(sha256sum $(1) | cut -f1 -d" ") \
 && { echo '{'; \
	 echo '  "host": "'$(2)'",'; \
	 echo '  "url": "https://github.com/$(GHUSER)/esp-quick-toolchain/releases/download/$(REL)$(SUBREL)/'$${archivename}'",'; \
	 echo '  "archiveFileName": "'$${archivename}'",'; \
	 echo '  "checksum": "SHA-256:'$${archivesha256}'",'; \
	 echo '  "size": "'$${archivesize}'"'; \
	 echo '}'; } > $(1).json
endef

# The recipes begin here.

# Leave jobserver to the submake calls
.NOTPARALLEL:

# Targeted .stage.* are chained together and finish by stamping .stage.%.done

.stage.%.done: .stage.%.post
	echo DONE: $(call arch,$@)
	@rm -vf .stage.$(call arch,$@).*
	touch $@

# WARN: .stage.% is ambiguous, .stage.%.% does not seem to be working
# TODO: attach .PRECIOUS: to ALL .stage'd targets?
# in current case, avoid anything depending on .done accidentally
# removing it as an intermediate, all while keeping it an intermediate

.PRECIOUS: .stage.%.done

# Build all toolchain versions

.PHONY: all .stage.init .stage.clean .stage.git .stage.packages

.stage.git: .git.checkout
	@echo $@

.stage.packages: .package.unpack
	@echo $@

.stage.init: .stage.git .stage.packages .stage.patch
	@echo $@

.stage.clean: $(BUILD_TARGETS:%=.stage.%.clean)
	@echo $@
ifneq ($(NOCLEAN),)
	rm -vf log.stage.*
endif

default: all

all:
	$(MAKE) .stage.init $(call log_stage,.stage.init)
	$(MAKE) .stage.clean
	$(MAKE) .stage.LINUX.done
	$(MAKE) $(patsubst %,.stage.%.done,$(filter-out LINUX,$(BUILD_TARGETS)))

.PHONY: LINUX

LINUX:
	$(MAKE) .stage.init $(call log_stage,.stage.init)
	$(MAKE) .stage.LINUX.clean
	$(MAKE) .stage.LINUX.done

BUILD_TARGETS_WITHOUT_LINUX := $(filter-out LINUX,$(BUILD_TARGETS))

.PHONY: $(BUILD_TARGETS_WITHOUT_LINUX)

$(BUILD_TARGETS_WITHOUT_LINUX):
	$(MAKE) .stage.init $(call log_stage,.stage.init)
	$(MAKE) .stage.LINUX.clean .stage.$(@).clean
	$(MAKE) .stage.LINUX.done
	$(MAKE) .stage.$(@).done

.PHONY: clean .clean.%.arena .clean.%.install .stage.%.clean

clean:

# Clean all temporary build and arena directories

.clean.%.arena:
	@echo $@
ifneq ($(NOCLEAN),)
	rm -rf $(call arena,$@)
endif

.clean.%.install:
	@echo $@
ifneq ($(NOCLEAN),)
	rm -rf $(call install,$@)
endif

# Clean all files generated during TARGET stage
.PHONY: .stage.%.clean

.stage.%.clean: .clean.%.arena .clean.%.install
	@echo STAGE: $@
ifneq ($(NOCLEAN),)
	rm -vf $(patsubst .stage.%.clean,.stage.%*,$@)
	rm -vf $(patsubst .stage.%.clean,log.stage.%*,$@)
	rm -vrf $(PKGDIR)/pkg.$(call arch,$@)*
	rm -vf $(PKGDIR)/$(call host,$@)*
endif

clean: $(BUILD_TARGETS:%=.stage.%.clean)

# Reset git repos to the initial state

__gitrepo = $(or $($(1)_REPO),$(error no git repo for $(1)))
gitrepo = $(call __gitrepo,$(call stem,$(1)))

__gitref = $(or $($(1)_REF),$(error no git ref for $(1)))
gitref = $(call __gitref,$(call stem,$(1)))

__gitdir = $(or $($(1)_DIR),$(error no git dir for $(1)))
gitdir = $(call __gitdir,$(call stem,$(1)))

# GIT repos that would be cloned and checked out at the specific ref
REPOS := gcc binutils newlib lx106-hal mkspiffs mklittlefs esptool

.PHONY: .git.info .git.%.info .git.%.clone .git-reset-and-clean .git.%.reset-and-clean .git.fetch .git.%.fetch .git.checkout .git.%.checkout

.git.info: $(REPOS:%=.git.%.info)

.git.%.info:
	@echo '{ "name": "$(call stem,$@)"',
	@echo '  "url": "$(call gitrepo,$@)"',
	@echo '  "ref": "$(call gitref,$@)"',
	@echo '  "dir": "$(REPODIR)/$(call gitdir,$@)" }'

.git.%.clone:
	@echo $@
	test -r $(REPODIR)/$(call gitdir,$@)/.git || \
		(rm -rf $(REPODIR)/$(call gitdir,$@) \
			&& mkdir -p $(REPODIR)/$(call gitdir,$@) \
			&& cd $(REPODIR)/$(call gitdir,$@) \
			&& git init \
			&& git remote add origin $(call gitrepo,$@) \
			&& git fetch --recurse-submodules=yes origin $(call gitref,$@) \
			&& git checkout --recurse-submodules $(call gitref,$@))

# Completely clean out a git directory, removing any untracked files
.git.reset-and-clean: $(REPOS:%=.git.%.reset-and-clean)

.git.%.reset-and-clean:
	@echo $@
	-(test -r $(REPODIR)/$(call gitdir,$@)/.git \
		&& cd $(REPODIR)/$(call gitdir,$@) \
		&& git reset --hard --recurse-submodules \
		&& git clean -x -f -d )

clean: .git.reset-and-clean

# Sync with the remote and checkout any required tags or branches for existing clone
.git.pull: $(REPOS:%=.git.%.pull)

.git.%.pull:
	@echo $@
	test -r $(REPODIR)/$(call gitdir,$@)/.git
	# do not assume that % ref is a branch, attempt to fetch something first
	(cd $(REPODIR)/$(call gitdir,$@) \
		&& git reset --hard --recurse-submodules \
		&& git clean -x -f -d \
		&& ( git checkout $(call gitref,$@) \
			|| ( git fetch origin $(call gitref,$@) && git checkout $(call gitref,$@) )))
	# in case gitref above was already a branch, first checkout already switched into it
	# in case it was fetched, checkout creates a brand new local refs/heads/...
	(cd $(REPODIR)/$(call gitdir,$@) \
		&& ( git show-ref --quiet --verify "refs/heads/$(call gitref,$@)" \
				&& git pull --recurse-submodules \
				|| : ))

# Checkout any required tags or branches w/o syncing with the remote
.git.checkout: $(REPOS:%=.git.%.checkout)

.git.%.checkout: $(if $(NOFETCH),,.git.%.clone)
	@echo $@
	test -r $(REPODIR)/$(call gitdir,$@)/.git
	(cd $(REPODIR)/$(call gitdir,$@) \
		&& git reset --hard --recurse-submodules \
		&& git clean -x -f -d \
		&& git checkout $(call gitref,$@) )

# TODO: tarball support for humongous repos (gcc, binutils, etc.)
# 		while very useful for development, not so much for just building
# 		current archive unpack impl should behave similarly to git-clean

# Packages usually just fetched & unpacked, there is no patching being done
__pkgurl = $(or $($(1)_URL),$(error no package url for $(1)))
pkgurl = $(call __pkgurl,$(call stem,$(1)))

__pkgver = $(or $($(1)_VER),$(error no package version for $(1)))
pkgver = $(call __pkgver,$(call stem,$(1)))

# expected output directory, should exist after recipe completes
__pkgdir = $(or $($(1)_DIR),$(error no package dir for $(1)))
pkgdir = $(call __pkgdir,$(call stem,$(1)))

# package top directory is not the same as the expected one, make sure to rename it
pkgtopdir = $($(call stem,$(1))_TOPDIR)

# note that current url schemes allow to extract it directly from the path
__pkgarchive = $(or $($(1)_ARCHIVE),$(lastword $(subst /, ,$(call __pkgurl,$(1)))))
pkgarchive = $(call __pkgarchive,$(call stem,$(1)))

pkgsha = $($(call stem,$(1))_SHA)

__pkgsuffix = $(suffix $(call __pkgarchive,$(1)))
__pkgfullsuffix = $(findstring .tar,$(call __pkgarchive,$(1)))$(call __pkgsuffix,$(1))
__pkgext = $(or $(call __pkgfullsuffix,$(1)),$(error no known archive extension for $(1)))
pkgext = $(call __pkgext,$(call stem,$(1)))

.PHONY: .package.info .package.%.info .package.fetch .package.%.fetch .package.unpack .package.%.unpack .package.clean .package.%.clean

.package.info: $(PACKAGES:%=.package.%.info)

.package.%.info:
	@echo '{ "name": "$(call stem,$@)",'
	@echo '  "url": "$(call pkgurl,$@)"',
	@echo '  "version": "$(call pkgver,$@)"',
	@echo '  "dir": "$(REPODIR)/$(call pkgdir,$@)"',
	@echo '  "topdir": "$(REPODIR)/$(or $(call pkgtopdir,$@),$(call pkgdir,$@))"',
	@echo '  "archive": "$(REPODIR)/$(call pkgarchive,$@)"',
	@echo '  "extension": "$(call pkgext,$@)" }'

# Fetch package urls & unpack archives
.package.fetch: $(PACKAGES:%=.package.%.fetch)

.package.%.fetch:
	@echo $@
	mkdir -p $(REPODIR)/
	test -r $(REPODIR)/$(call pkgarchive,$@) \
		|| wget -v -O $(REPODIR)/$(call pkgarchive,$@) $(call pkgurl,$@)
	test -z "$(call pkgsha,$@)" \
		|| ( cd $(REPODIR) && ( echo "$(call pkgsha,$@)  $(call pkgarchive,$@)" | sha256sum --check ))

.package.unpack: $(PACKAGES:%=.package.%.unpack)

.package.%.unpack: $(if $(NOFETCH),,.package.%.fetch)
	@echo $@
	mkdir -p $(REPODIR)/
	test -r $(REPODIR)/$(call pkgarchive,$@)
	rm -rf $(REPODIR)/$(call pkgdir,$@)
	if [ -n "$(call pkgtopdir,$@)" ]; then \
		rm -rf $(REPODIR)/$(call pkgtopdir,$@); \
	fi
	(cd $(REPODIR) && \
		archive="$(call pkgarchive,$@)"; \
		ext="$(call pkgext,$@)"; \
		case "$$ext" in \
			(.t*) tar xf $$archive ;; \
			(.zip) unzip -qu $$archive ;; \
			(*) echo "-ERROR Unknown archive type" >&2; exit 1 ;; \
		esac )
	if [ -n "$(call pkgtopdir,$@)" ]; then \
		mv -v $(REPODIR)/$(call pkgtopdir,$@) $(REPODIR)/$(call pkgdir,$@); \
	fi
	test -d $(REPODIR)/$(call pkgdir,$@)

.package.clean: $(PACKAGES:%=.package.%.clean)

.package.%.clean:
	@echo $@
ifneq ($(NOCLEAN),)
	-rm -r $(call pkgdir,$@)
endif

clean: .package.clean

# Checkout and reset, then apply patches to the local GIT repos
patch = \
	test -r "$(1)" || continue ; \
    (set -x; patch -s -p1 -i $(1))

# Dirty-force HAL definition for binutils & gcc
LX106_HAL_CORE_ISA_H := $(REPODIR)/$(lx106-hal_DIR)/include/xtensa/config/core-isa.h
LX106_HAL_SYSTEM_H := $(REPODIR)/$(lx106-hal_DIR)/include/xtensa/config/system.h
LX106_HAL_XTENSA_CONFIG_H := \
	$(LX106_HAL_CORE_ISA_H) \
	$(LX106_HAL_SYSTEM_H)

$(LX106_HAL_XTENSA_CONFIG_H): .stage.lx106-hal.patch

OVERLAY_XTENSA_CONFIG_H := $(REPODIR)/xtensa-config.h
$(OVERLAY_XTENSA_CONFIG_H): $(LX106_HAL_XTENSA_CONFIG_H)
	test -r "$(OVERLAY_XTENSA_CONFIG_H)" \
		&& (cat $^ | diff -q $(OVERLAY_XTENSA_CONFIG_H) - || cat $^ > $@) \
		|| (cat $^ > $@)

.PHONY: .stage.%.patch

.stage.gcc.patch: $(OVERLAY_XTENSA_CONFIG_H) .git.gcc.checkout
	@echo STAGE: $@
	(cd $(REPODIR)/$(gcc_DIR) && \
		for p in $(PATCHDIR)/gcc-*.patch $(PATCHDIR)/gcc$(GCC)/gcc-*.patch; do \
			$(call patch,$$p); \
		done )
	(cd $(REPODIR)/$(gcc_DIR) \
		&& cp -v $(OVERLAY_XTENSA_CONFIG_H) include/xtensa-config.h)
ifeq ($(GCC_MAJOR), 4)
	# external dependency built as part of the tree
	(cd $(REPODIR)/$(gcc_DIR) \
		&& rm -rf cloog \
		&& ln -sf ../cloog-$(CLOOG_VER) cloog \
		&& echo " LINK $(gcc_DIR)/cloog <- cloog-$(CLOOG_VER)" )
endif

.stage.binutils.patch: $(OVERLAY_XTENSA_CONFIG_H) .git.binutils.checkout
	@echo STAGE: $@
	(cd $(REPODIR)/$(binutils_DIR) && \
		for p in $(PATCHDIR)/bin-*.patch $(PATCHDIR)/gcc$(GCC)/bin-*.patch; do \
			$(call patch,$$p); \
		done )
	(cd $(REPODIR)/$(binutils_DIR) \
		&& cp -va $(OVERLAY_XTENSA_CONFIG_H) include/xtensa-config.h)

# Recent newlib ships minimal HAL core-isa.h for lx6/lx7 (aka esp32), make sure it is for lx106
LX106_HAL_CORE_ISA_H := $(REPODIR)/$(lx106-hal_DIR)/include/xtensa/config/core-isa.h
$(LX106_HAL_CORE_ISA_H): .stage.lx106-hal.patch

NEWLIB_CORE_ISA_H := $(REPODIR)/$(newlib_DIR)/newlib/libc/machine/xtensa/include/xtensa/config/core-isa.h
OVERLAY_CORE_ISA_H := $(REPODIR)/core-isa.h

$(NEWLIB_CORE_ISA_H): $(OVERLAY_CORE_ISA_H)

$(OVERLAY_CORE_ISA_H): $(LX106_HAL_CORE_ISA_H)
	test -r "$(OVERLAY_CORE_ISA_H)" \
		&& (diff -q $< $@ || cp $< $@) \
		|| (cp $< $@)

.PHONY: .clean.overlay-core-isa-h

.clean.overlay-core-isa-h: | $(OVERLAY_CORE_ISA_H)
	-rm -fv $(OVERLAY_CORE_ISA_H)

clean: .clean.overlay-core-isa-h

.stage.newlib.patch: $(OVERLAY_CORE_ISA_H) .git.newlib.checkout
	@echo STAGE: $@
	(cd $(REPODIR)/$(newlib_DIR) && \
		for p in $(PATCHDIR)/lib-*.patch $(PATCHDIR)/gcc$(GCC)/lib-*.patch; do \
			$(call patch,$$p); \
		done )
	(set -x; cp -va $(OVERLAY_CORE_ISA_H) $(NEWLIB_CORE_ISA_H))

.stage.lx106-hal.patch: .git.lx106-hal.checkout
	(cd $(REPODIR)/$(lx106-hal_DIR) && \
		for p in $(PATCHDIR)/hal-*.patch; do \
			$(call patch,$$p); \
		done )
	# HAL Makefile.am was patched above
	(cd $(REPODIR)/$(lx106-hal_DIR) \
		&& autoreconf -i )

.stage.mkspiffs.patch: .git.mkspiffs.checkout
	@echo STAGE: $@
	(cd $(REPODIR)/$(mkspiffs_DIR) && \
		for p in $(PATCHDIR)/mkspiffs/$(mkspiffs_REF)*.patch; do \
			$(call patch,$$p); \
		done )

.stage.mklittlefs.patch: .git.mklittlefs.checkout
	@echo STAGE: $@
	(cd $(REPODIR)/$(mklittlefs_DIR) && \
		for p in $(PATCHDIR)/mklittlefs/$(mklittlefs_REF)*.patch; do \
			$(call patch,$$p); \
		done )

.stage.%.patch:
	@echo $@

.PHONY: download

download:
	$(MAKE) .git.clone
	$(MAKE) .git.pull
	$(MAKE) .package.fetch

.PHONY: patch .stage.patch

.stage.patch: $(patsubst %,.stage.%.patch,$(REPOS) $(PACKAGES))
	@echo $@

patch: .stage.patch

# Base target configuration info
.PHONY: .target.info .target.%.info

.target.info: $(BUILD_TARGETS:%=.target.%.info)

.target.%.info:
	@echo '{ "host": "$(call host,$@)"',
	@echo '  "ahost": "$(call ahost,$@)"',
	@echo '  "asys": "$(call asys,$@)"',
	@echo '  "ext": "$(call ext,$@)"',
	@echo '  "exe": "$(call exe,$@)"',
	@echo '  "mktgt": "$(call mktgt,$@)"',
	@echo '  "archivepre": "$(call archivepre,$@)"',
	@echo '  "archivecmd": "$(call archivecmd,$@)"',
	@echo '  "archiveopt": "$(call archiveopt,$@)"',
	@echo '  "archiveext": "$(call archiveext,$@)" }'

# Info about current stage build configuration
.PHONY: .stage.info .stage.%.info

.stage.info: $(BUILD_TARGETS:%=.stage.%.info)

.stage.%.info:
	@echo '{ "setenv": "$(subst ",\",$(call setenv,$@))"',
	@echo '  "configure": "$(call configure,$@)"',
	@echo '  "configure_binutils": "$(call configure_binutils,$@)"',
	@echo '  "configure_cross": "$(call configure_cross,$@)"',
	@echo '  "configure_gdb": "$(call configure_gdb,$@)"',
	@echo '  "configure_gmp": "$(call configure_gmp,$@)"',
	@echo '  "configure_libexpat": "$(CONFIGURE_LIBEXPAT)"',
	@echo '  "configure_ncurses": "$(call configure_ncurses,$@)"',
	@echo '  "configure_newlib": "$(call configure_newlib,$@)"',
	@echo '  "configure_target": "$(call configure_target,$@)" }'

# Shared dependency for binutils and gcc
.stage.%.gmp-make:
	@echo STAGE: $@
	rm -rf $(call arena,$@)/gmp
	mkdir -p $(call arena,$@)/gmp
	(cd $(call arena,$@)/gmp \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(gmp_DIR)/configure \
			$(call configure_gmp,$@) \
		&& $(MAKE) \
		&& $(MAKE) install) $(call log_stage,$@)
	touch $@

.stage.%.mpfr-make: .stage.%.gmp-make
	@echo STAGE: $@
	rm -rf $(call arena,$@)/mpfr
	mkdir -p $(call arena,$@)/mpfr
	(cd $(call arena,$@)/mpfr \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(mpfr_DIR)/configure \
			$(call configure_cross,$@) \
			$(call configure_with_gmp,$@) \
		&& $(MAKE) \
		&& $(MAKE) install) $(call log_stage,$@)
	touch $@

.stage.%.mpc-make: .stage.%.mpfr-make
	@echo STAGE: $@
	rm -rf $(call arena,$@)/mpc
	mkdir -p $(call arena,$@)/mpc
	(cd $(call arena,$@)/mpc \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(mpc_DIR)/configure \
			$(call configure_cross,$@) \
			$(call configure_with_gmp,$@) \
		&& $(MAKE) \
		&& $(MAKE) install) $(call log_stage,$@)
	touch $@

.stage.%.gmp: .stage.%.gmp-make .stage.%.mpfr-make .stage.%.mpc-make
	@echo STAGE: $@
	touch $@

# isl-0.xx expects gmp prefix as --with-gmp-prefix=... unlike any other ./configure script here
.stage.%.isl: .stage.%.gmp
	@echo STAGE: $@
	rm -rf $(call arena,$@)/isl
	mkdir -p $(call arena,$@)/isl
	(cd $(call arena,$@)/isl \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(isl_DIR)/configure \
			$(call configure_cross,$@) \
			--with-gmp-prefix=$(call arena,$@)/cross \
		&& $(MAKE) \
		&& $(MAKE) install) $(call log_stage,$@)
	touch $@

# GDB static build has to have up-to-date libs
.stage.%.libexpat:
	@echo STAGE: $@
	rm -rf $(call arena,$@)/libexpat
	mkdir -p $(call arena,$@)/libexpat
	(cd $(call arena,$@)/libexpat \
		&& $(call setenv,$@) \
		&& cp -r $(REPODIR)/$(libexpat_DIR)/* ./ \
		&& bash buildconf.sh \
		&& ./configure \
			$(call configure_cross,$@) \
			$(CONFIGURE_LIBEXPAT) \
		&& $(MAKE) \
		&& $(MAKE) install ) $(call log_stage,$@)
	touch $@

# *warning in regards to any other possible target override recipe*
# both .stage.LINUX.ncurses-progs: OR .stage.LINUX.ncurses-progs: .stage.%.ncurses-progs:
# generate explicit target specifically for LINUX stem, forcing .done to concider this target
# dispatch through an extra, otherwise unsused recipe w/o any explicit or implicit dependencies
.PHONY: .cross.%.ncurses-progs

# todo: since there is no cross-target dependency, ensure that commands generated from LINUX work
.cross.%.ncurses-progs:
	@echo $@
	($(call setenv_cross,$@) \
		&& export crosspath="$(call cross,.stage.LINUX.ncurses-progs)" \
		&& test "$$(command -v tic)" = "$$crosspath/bin/tic" \
		&& test "$$(command -v infocmp)" = "$$crosspath/bin/infocmp" )

# only LINUX aka host toolchain cross has to have these
.cross.LINUX.ncurses-progs:
	@echo $@
	rm -rf $(call arena,$@)/ncurses-progs
	mkdir -p $(call arena,$@)/ncurses-progs
	(cd $(call arena,$@)/ncurses-progs \
		&& $(call setenv_cross,$@) \
		&& $(REPODIR)/$(ncurses_DIR)/configure \
			$(call configure_ncurses,$@) \
			$(NCURSES_CONFIGURE_FLAGS_WITH_PROGS) \
		&& $(MAKE) \
		&& $(MAKE) install)

.stage.%.ncurses-progs:
	@echo STAGE: $@
	$(MAKE) $(subst .stage,.cross,$@) $(call log_stage,$@)
	touch $@

.stage.%.ncurses: .stage.%.ncurses-progs
	@echo STAGE: $@
	rm -rf $(call arena,$@)/ncurses
	mkdir -p $(call arena,$@)/ncurses
	(cd $(call arena,$@)/ncurses \
		&& $(call setenv_cross,$@) \
		&& $(REPODIR)/$(ncurses_DIR)/configure \
			$(call configure_ncurses,$@) \
			$(NCURSES_CONFIGURE_FLAGS_WITH_FALLBACKS) \
		&& $(MAKE) \
		&& $(MAKE) install) $(call log_stage,$@)
	touch $@

BUILD_CROSS = .stage.%.gmp \
			  .stage.%.isl \
			  .stage.%.libexpat \
			  .stage.%.ncurses

# Build binutils & gdb
.stage.%.binutils-config: $(BUILD_CROSS)
	@echo STAGE: $@
	rm -rf $(call arena,$@)/binutils
	mkdir -p $(call arena,$@)/binutils
	(cd $(call arena,$@)/binutils \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(BINUTILS_DIR)/configure \
			$(call configure_binutils,$@) ) $(call log_stage,$@)
	touch $@

.stage.%.binutils-make: .stage.%.binutils-config
	@echo STAGE: $@
	(cd $(call arena,$@)/binutils \
		&& $(call setenv,$@) \
		&& $(call setenv_binutils,$@) \
		&& $(MAKE) \
		&& $(MAKE) install) $(call log_stage,$@)

# attempt to fix dynamic plugins loader by actually building plugins dynamically
# https://github.com/msys2/MINGW-packages/issues/7890
# https://github.com/msys2/MINGW-packages/blob/68f7d4665c396a464536871b1de7b680a47a8fa7/mingw-w64-binutils/PKGBUILD#L150-L151
WIN32_DLL := .dll
WIN64_DLL := .dll

dll = $(or $($(call arch,$(1))_DLL),.so)

.stage.%.binutils-post: .stage.%.binutils-make
	@echo STAGE: $@
ifneq ($(filter-out master binutils-2_32,$(BINUTILS_REF)),)
	rm -rf $(call arena,$@)/binutils/ld
	mkdir -p $(call arena,$@)/binutils/ld
	(cd $(call arena,$@)/binutils/ld \
		&& $(call setenv_binutils,$@) \
		&& $(REPODIR)/$(BINUTILS_DIR)/ld/configure \
			$(call configure_binutils,$@) \
			--enable-static=no \
			--enable-shared \
		&& $(MAKE) \
		&& cp -v .libs/libdep$(call dll,$@) \
			$(call install,$@)/lib/bfd-plugins/ ) $(call log_stage,$@)
endif
	touch $@

.stage.%.gdb-config: $(BUILD_CROSS)
	@echo STAGE: $@
	rm -rf $(call arena,$@)/gdb
	mkdir -p $(call arena,$@)/gdb
	(cd $(call arena,$@)/gdb \
		&& $(call setenv,$@) \
		&& $(call setenv_binutils,$@) \
		&& $(call setenv_gdb,$@) \
		&& $(REPODIR)/$(BINUTILS_DIR)/configure \
			$(call configure_gdb,$@) ) $(call log_stage,$@)
	touch $@

.stage.%.gdb-make: .stage.%.gdb-config
	@echo STAGE: $@
	(cd $(call arena,$@)/gdb \
		&& $(call setenv,$@) \
		&& $(call setenv_binutils,$@) \
		&& $(call setenv_gdb,$@) \
		&& $(MAKE) \
		&& $(MAKE) install) $(call log_stage,$@)
	touch $@

.stage.%.gcc1-config: .stage.%.binutils-post .stage.%.gdb-make
	@echo STAGE: $@
	rm -rf $(call arena,$@)/$(gcc_DIR)
	mkdir -p $(call arena,$@)/$(gcc_DIR)
	(cd $(call arena,$@)/$(gcc_DIR) \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(gcc_DIR)/configure \
			$(CONFIGURE_EH_POOL) \
			$(call configure_with_gmp,$@) \
			$(call configure_with_isl,$@) \
			$(call configure_target,$@) ) $(call log_stage,$@)
	touch $@

.stage.%.gcc1-make: .stage.%.gcc1-config
	@echo STAGE: $@
	(cd $(call arena,$@)/$(gcc_DIR) \
		&& $(call setenv,$@) \
		&& $(MAKE) all-gcc \
		&& $(MAKE) install-gcc \
		&& cd $(call install,$@)/bin  \
		&& ln -sf $(TARGET_ARCH)-gcc$(call exe,$@) \
			$(TARGET_ARCH)-cc$(call exe,$@) ) $(call log_stage,$@)
	touch $@

.stage.%.newlib-config: .stage.%.gcc1-make
	@echo STAGE: $@
	rm -rf $(call arena,$@)/newlib
	mkdir -p $(call arena,$@)/newlib
	(cd $(call arena,$@)/newlib \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(newlib_DIR)/configure \
			$(call configure_newlib,$@)) $(call log_stage,$@)
	touch $@

# generates newlib aka libc and hal installations at the install root
# even though these don't have to be rebuilt per target, its fairly short and also verifies that the compiler actually works
.stage.%.newlib-make: .stage.%.newlib-config
	@echo STAGE: $@
	(cd $(call arena,$@)/newlib \
		&& $(call setenv,$@) \
		&& $(MAKE) \
		&& $(MAKE) install ) $(call log_stage,$@)
	touch $@

.stage.%.hal-config: .stage.%.newlib-make
	@echo STAGE: $@
	rm -rf $(call arena,$@)/lx106-hal
	mkdir -p $(call arena,$@)/lx106-hal
	# note the CC=... to override possibly injected variable after calling 'configure'
	(cd $(call arena,$@)/lx106-hal \
		&& $(call setenv,$@) \
		&& $(REPODIR)/$(lx106-hal_DIR)/configure \
			$(call configure_target,$@) \
			CC=$(TARGET_ARCH)-gcc \
			--target=$(TARGET_ARCH) \
			--host=$(TARGET_ARCH) ) $(call log_stage,$@)
	touch $@

# nb. override prefix to ONLY place hal .a into the target arch directory, don't copy to BOTH system-wide and target
.stage.%.hal-make: .stage.%.hal-config
	@echo STAGE: $@
	(cd $(call arena,$@)/lx106-hal \
		&& $(call setenv,$@) \
		&& $(MAKE) && $(MAKE) \
			prefix=$(call install,$@)/$(TARGET_ARCH) \
			exec_prefix=$(call install,$@)/$(TARGET_ARCH) \
			install ) $(call log_stage,$@)
	touch $@

.stage.%.libstdcpp: .stage.%.hal-make
	@echo STAGE: $@
	# stage 2 (build libstdc++)
	(cd $(call arena,$@)/$(gcc_DIR) \
		&& $(call setenv,$@) \
		&& $(MAKE) && $(MAKE) install ) $(call log_stage,$@)
	touch $@

.stage.%.libstdcpp-nox: .stage.%.libstdcpp
	@echo STAGE: $@
	# We copy existing stdc, adjust the makefile, and build a single .a to save much time
	rm -rf $(call arena,$@)/$(gcc_DIR)/$(TARGET_ARCH)/libstdc++-v3-nox
	(cd $(call arena,$@)/$(gcc_DIR)/$(TARGET_ARCH) \
		&& cp -a libstdc++-v3 libstdc++-v3-nox) $(call log_stage,$@)
	(cd $(call arena,$@)/$(gcc_DIR)/$(TARGET_ARCH)/libstdc++-v3-nox \
		&& $(call setenv,$@) \
		&& $(MAKE) clean \
		&& $(MAKE) CXXFLAGS="-fno-exceptions $${CXXFLAGS_FOR_TARGET}" ) $(call log,$@)
	(cd $(TARGET_ARCH)$(call ext,$@)/$(TARGET_ARCH)/lib/ \
		&& cp -v libstdc++.a libstdc++-exc.a \
		&& cp -v $(call arena,$@)/$(gcc_DIR)/$(TARGET_ARCH)/libstdc++-v3-nox/src/.libs/libstdc++.a ./) $(call log,$@)
	touch $@

.stage.%.strip: .stage.%.libstdcpp-nox
	@echo STAGE: $@
	$(MAKE) .install.$(call arch,$@).strip
	touch $@

.stage.%.post: .stage.%.strip
	@echo STAGE: $@
	for sh in $(POSTDIR)/gcc$(GCC)-*.sh $(POSTDIR)/gcc$(GCC_MAJOR)-*.sh; do \
	    [ -x "$${sh}" ] || continue ; \
		(set -x; $${sh} $(call ext,$@)) ; \
	done $(call log_stage,$@)
	touch $@

# packaging for distribution through package indexes & via releases

.PHONY: tools .tool.%.all

tools: $(BUILD_TARGETS:%=.tool.%.all)

.tool.%.all: .tool.%.toolchain .tool.%.mkspiffs .tool.%.mklittlefs .tool.%.esptool .tool.%.python
	@echo $@

.PHONY: .tool.%.toolchain .tool.%.mkspiffs .tool.%.mklittlefs .tool.%.esptool .tool.%.python

.PHONY: .install.%.debuginfo .install.%.strip

# adjust find expression to find targets for $$STRIP
# in case exe and dll suffixes are available, just match them instead of probing filetypes
__tool_toolchain_find_exedll = \
	-name '*$(call exe,$(1))' -o \
	-name '*$(call dll,$(1))'

# make sure to ignore some executable false-positives
# - host system static lib archives
# - host system libtool library files
# - shellscripts from gcc & gdb
__tool_toolchain_find_executables = \
	'!' -name '*.a' \
	'!' -name '*.la' \
	'!' -name '*.sh' \
	'!' -exec sh -c "head -c32 {} | grep -q -e '\#!.*/bin/sh' -e '\#!.*/bin/env sh' -e '\#!.*/bin/env bash'" \;

__tool_toolchain_strip_find = \
	find $(1) -type f -executable '(' \
	$(if $(and $(call exe,$(2)),$(call dll,$(2))),$(call __tool_toolchain_find_exedll,$(2)),$(__tool_toolchain_find_executables)) \
	')' -print0

tool-toolchain-strip-find = \
	$(call __tool_toolchain_strip_find,\
		$(call install,$@)/bin \
		$(call install,$@)/lib/bfd-plugins \
		$(call install,$@)/libexec/gcc/$(TARGET_ARCH),$@)

# todo: other linux target should also provide *-linux-gnu-objcopy, inject your arch if necessary
# todo: mingw32 also provides *-w64-mingw32-objcopy, but requires mingw packages on target
.install.%.debuginfo:
	echo $@

# assume that gdb session sets arena as `debug-file-directory`, which then allows searches inside of `$path/.build-id`
install-debuginfo-dir := $(call arena,.stage.LINUX.binutils-make)/.build-id

# experiment w/ debuginfo splitting, but only for host aka LINUX
# see arena.x86_64/binutils/libbacktrace/install-debugifo-for-buildid.sh for the original script
# - debug sections are compressed, which is not enabled by default; assume zlib
# - destination file does not get overwritten; beware that $$STRIP follows, extraction cannot happen twice
.install.LINUX.debuginfo:
	echo $@
	( $(tool-toolchain-strip-find) \
		| xargs -n 1 -I {} -r -0 -- $(POSTDIR)/install-debuginfo-for-buildid.sh "$(install-debuginfo-dir)" {})

# manual `make install-strip` since this script never defines or uses $(STRIPPROG)
# note that anything configuring through autotools *should* work with it
.install.%.strip: .install.%.debuginfo
	@echo $@
	($(call setenv_strip,$@) \
		&& ( $(tool-toolchain-strip-find) | xargs -r -0 $$STRIP ))

.PHONY: .toolchain.%.strip

# no-op after staged build, re-run anyway to ensure any rebuilds continue w/ the stripped install dir
.toolchain.%.strip:
	@echo $@
	$(MAKE) .install.$(call arch,$@).strip

.PHONY: package-json .toolchain.%.package-json

package-json: .toolchain.LINUX.package-json

# package.json *should* be available in the install directory, allow symlink://... version spec for testing
.toolchain.%.package-json: TOOL_NAME=toolchain-xtensa
.toolchain.%.package-json: TOOL_DESC=GCC Toolchain for Xtensa processor
.toolchain.%.package-json: TOOL_PKGREL=$(PKGREL)

.toolchain.%.package-json: | .stage.%.done
	@echo $@
	rm -vf $(call install,$@)/package.json
	(cd $(call install,$@) \
		&& $(call make_package_json,$(TOOL_NAME),$(TOOL_DESC),$(TOOL_PKGREL),$(call asys,$@)) )
	@echo JSON $(call install,$@)/package.json

tool-toolchain-pkgdir = $(PKGDIR)/pkg.$(call arch,$@).toolchain

.toolchain.%.clean:
	@echo $@
	-rm -rf $(tool-toolchain-pkgdir)
	-rm -vf .toolchain.$(call stem,$@)*

# both arduino & platformio share package archive structure with $(TARGET_ARCH) as root
$(PKGDIR)/pkg.%.toolchain:
	@echo $@
	rm -rf $@
	mkdir -p $@
	cp -a $(call install,$@) $@/$(TARGET_ARCH)

.PRECIOUS: $(PKGDIR)/%.json

package/%.json: $(PKGDIR)/%.json
	@echo $@

$(PKGDIR)/%.json:
	test -f $(subst .json,,$@)
	case "$(subst .json,,$(@F))" in \
		$(LINUX_HOST)*) ahost=$(LINUX_AHOST) ;; \
		$(LINUX32_HOST)*) ahost=$(LINUX32_AHOST) ;; \
		$(ARM64_HOST)*) ahost=$(ARM64_AHOST) ;; \
		$(RPI_HOST)*) ahost=$(RPI_AHOST) ;; \
		$(WIN64_HOST)*) ahost=$(WIN64_AHOST) ;; \
		$(WIN32_HOST)*) ahost=$(WIN32_AHOST) ;; \
		$(MACOSX86_HOST)*) ahost=$(MACOSX86_AHOST) ;; \
		$(MACOSARM_HOST)*) ahost=$(MACOSARM_AHOST) ;; \
		*) echo "Unknown ahost $(@F)" >&2; exit 1 ;; \
	esac && \
	$(call make_releases_json,$(subst .json,,$@),$$ahost)

.PHONY: .toolchain.%.prepare .toolchain.%.force-prepare

.toolchain.%.force-prepare:
	@echo $@
	$(MAKE) .toolchain.$(call stem,$@).clean
	$(MAKE) $(tool-toolchain-pkgdir)

.PHONY: .toolchain.%.remove-unused

# remove files not intended for distribution
.toolchain.%.remove-unused: | $(PKGDIR)/pkg.%.toolchain
	@echo $@
	# libtool library files are generated for both host and target
	find $(tool-toolchain-pkgdir)/$(TARGET_ARCH) -type f -name '*.la' -delete

# gathers license info from the top directory of the currently checked out repo / unpacked archive
# note that output does not always represent which parts of the package are actually used
# 1) directory to search 2) destination directory 3) find option(s) before predicates
define copy_copying
	(cd $(1) && find ./ $(3) -type f '(' -name 'LICENSE*' -o -name 'COPYING*' ')' -print0 \
		| tar --null -c -T - -f - \
		| tar -C $(2) -x -f - )
endef

# 1) 'git repo' or 'package' name
tool_toolchain_copying_src = \
	$(REPODIR)/$(or $(if $(filter $(1),$(REPOS)),$(call __gitdir,$(1)),),\
		$(if $(filter $(1),$(PACKAGES)),$(call __pkgdir,$(1)),),\
			$(error cant find dir for $(1)))

# store license / copying / legal in the resulting toolchain archive
# 1) destination root 2) 'git repo' or 'package' name
define tool_toolchain_copying
	mkdir -p $(1)/$(2)
	$(call copy_copying,$(call tool_toolchain_copying_src,$(2)),$(1)/$(2),-maxdepth 1)

endef

.PHONY: .toolchain.%.copy-licenses

# gather copying / license / legal info files from the declared repo/$name root directory
# not everything declared beforehand is related to toolchain package, explicitly listing them near use
.toolchain.%.copy-licenses: | $(PKGDIR)/pkg.%.toolchain
	@echo $@
	# license info. packaging limited to topdir, otherwise its the same as other tool recipes
	$(foreach name,$(TOOLCHAIN_PACKAGES),$(call tool_toolchain_copying,$(tool-toolchain-pkgdir)/$(TARGET_ARCH)/share/licenses,$(name)))

TOOLCHAIN_GIT_REPOS := binutils gcc lx106-hal newlib
TOOLCHAIN_PACKAGES := $(TOOLCHAIN_GIT_REPOS) gmp isl libexpat mpc mpfr ncurses

__toolchain_archive = $(call host,$(1)).$(TARGET_ARCH)-gcc$(GCC)-eqt$(REL)$(SUBREL)-$(REV)
toolchain_archive = $(call __toolchain_archive,$(1))$(call archiveext,$(1))

.PHONY: .toolchain.%.archive

# prepare full toolchain archive including binutils + gdb + gcc + newlib
# recipe only has to copy staged build result from the target install dir
.toolchain.%.archive: | $(PKGDIR)/pkg.%.toolchain
	@echo $@
	# packaged artifact named a bit differently to help with clean-up name matching
	# note that $(TARGET_ARCH)-gcc IS arduino internal name that is assigned to the toolchain
	# (ref. arduino recipes below)
	rm -vf \
		$(PKGDIR)/$(call host,$@).$(TARGET_ARCH)-gcc*$(call archiveext,$@) \
		$(PKGDIR)/$(call host,$@).$(TARGET_ARCH)-gcc*$(call archiveext,$@).json
	test -d $(tool-toolchain-pkgdir)/$(TARGET_ARCH)
	$(call tool_make_archive,$(call toolchain_archive,$@),$(tool-toolchain-pkgdir)/$(TARGET_ARCH),$@)

.tool.%.toolchain: | .stage.%.done
	@echo $@
	$(MAKE) .toolchain.$(call stem,$@).package-json
	$(MAKE) .toolchain.$(call stem,$@).strip
	$(MAKE) .toolchain.$(call stem,$@).force-prepare
	$(MAKE) .toolchain.$(call stem,$@).remove-unused
	$(MAKE) .toolchain.$(call stem,$@).copy-licenses
	$(MAKE) .toolchain.$(call stem,$@).strip
	$(MAKE) .toolchain.$(call stem,$@).archive
	$(MAKE) .toolchain.$(call stem,$@).clean

# other currently packaged tools depend only on the host toolchain

# Dependencies borked in makefiles below, make sure to use -j1 to disable parallel execution
# ALL tools below re-use makefile structure, share build & packaging boilerplate and produce a single binary

# NAME, DESC, REL and PKGREL, DIR vars are expected to be set per recipe
# REL expected to be package version, not toolchain version (previously bound to the toolchain release, allow to bump them separately)
# PKGREL expected to be some kind of semver to satisfy platformio indexing. not really enforced for releases, but strongly suggested

define tool-build
	rm -rf $(call arena,$@)/$(TOOL_NAME)
	mkdir -p $(call arena,$@)/$(TOOL_NAME)
	cp -r $(REPODIR)/$(TOOL_DIR)/* $(call arena,$@)/$(TOOL_NAME)/.
	(cd $(call arena,$@)/$(TOOL_NAME) \
		&& $(call setenv_cross,$@) \
		&& $(MAKE) -j1 \
			TARGET_OS=$(call mktgt,$@) \
			BUILD_CONFIG_NAME="-arduino-esp8266" \
			VERSION="$(TOOL_REL)" \
			$(TOOL_NAME)$(call exe,$@))
endef

tool-pkgdir = $(PKGDIR)/pkg.$(call arch,$@).$(TOOL_NAME)

define tool-package-files
	(cd $(tool-pkgdir)/$(TOOL_NAME) \
		&& cp $(call arena,$@)/$(TOOL_DIR)/$(TOOL_NAME)$(call exe,$@) ./ )
endef

define tool-package-copying
	mkdir -p $(tool-pkgdir)/$(TOOL_NAME)/share/licenses/$(TOOL_NAME)
	$(call copy_copying,$(call arena,$@)/$(TOOL_NAME),$(tool-pkgdir)/$(TOOL_NAME)/share/licenses/$(TOOL_NAME),)
endef

tool_archive = $(call host,$(1)).$(TOOL_NAME)-$(TOOL_REL).$(DATESTAMP)$(call archiveext,$(1))

# 1) archive 2) pkg source dir 3) $@
define tool_make_archive
	@echo $(call archivecmd,$(3)) $(call archiveopt,$(3)) $(PKGDIR)/$(1)
	(cd $$(dirname $(2)) \
		&& ( $(call archivepre,$(3)) ) \
		&& ( find $$(basename $(2)) -name '*' -print0 \
			| sort -z \
			| xargs -0 $(call archivecmd,$(3)) $(call archiveopt,$(3)) $(PKGDIR)/$(1) ) \
		&& cd $(PKGDIR) \
		&& $(call make_releases_json,$(1),$(call ahost,$(3))) )
endef

define tool-package-archive
	rm -vf $(PKGDIR)/$(call host,$@).$(TOOL_NAME)-*
	$(call tool_make_archive,$(call tool_archive,$@),$(tool-pkgdir)/$(TOOL_NAME),$@)
endef

define tool-package
	rm -rf $(tool-pkgdir)
	mkdir -p $(tool-pkgdir)/$(TOOL_NAME)
	(cd $(tool-pkgdir)/$(TOOL_NAME) \
		&& $(call make_package_json,$(TOOL_NAME),$(TOOL_DESC),$(TOOL_PKGREL),$(call asys,$@)) )
	$(tool-package-files)
	$(tool-package-copying)
	$(tool-package-archive)
	rm -rf $(tool-pkgdir)
endef

.tool.%.mkspiffs: TOOL_NAME=mkspiffs
.tool.%.mkspiffs: TOOL_DESC=spiffs-utility
.tool.%.mkspiffs: TOOL_REL=$(mkspiffs_REF)
.tool.%.mkspiffs: TOOL_PKGREL=0.$(call piominor,$(mkspiffs_VER)).$(DATESTAMP)$(SUBREL)
.tool.%.mkspiffs: TOOL_DIR=$(mkspiffs_DIR)

.tool.%.mkspiffs:
	@echo $@
	$(tool-build)
	$(tool-package)

.tool.%.mklittlefs: TOOL_NAME=mklittlefs
.tool.%.mklittlefs: TOOL_DESC=littlefs-utility
.tool.%.mklittlefs: TOOL_REL=$(mklittlefs_VER)
.tool.%.mklittlefs: TOOL_PKGREL=0.$(call piominor,$(mklittlefs_VER)).$(DATESTAMP)$(SUBREL)
.tool.%.mklittlefs: TOOL_DIR=$(mklittlefs_DIR)

.tool.%.mklittlefs:
	@echo $@
	$(tool-build)
	$(tool-package)

# TODO esptool-ck was deprecated in favour of esptool-py a long time ago
# TODO (re)package esptool-py? rn it is a submodule of the Core and distributed w/ the release version
#      although, it is unclear whether arduino allows to declare cross-tool dependencies
#      for e.g. this toolchains pinned python version and some other package which is NOT a Core
.tool.%.esptool: TOOL_NAME=esptool
.tool.%.esptool: TOOL_DESC=flashing-utility
.tool.%.esptool: TOOL_REL=$(esptool_VER)
.tool.%.esptool: TOOL_PKGREL=0.$(call piominor,$(esptool_VER)).$(DATESTAMP)$(SUBREL)
.tool.%.esptool: TOOL_DIR=$(esptool_DIR)

.tool.%.esptool:
	@echo $@
	$(tool-build)
	$(tool-package)

# python sourced from astral-sh/python-build-standalone
# note that some versions take the one from the system or environment
PYTHON_RELEASE := 20261110
PYTHON_VERSION := 3.14.10

.PHONY: .tool.python-release

.tool.python-release:
	@echo $(PYTHON_RELEASE)

.PHONY: .tool.python-version

.tool.python-version:
	@echo $(PYTHON_VERSION)

__python_archive = cpython-$(PYTHON_VERSION)+$(PYTHON_RELEASE)-$(1)-install_only_stripped$(2)
python_url = https://github.com/astral-sh/python-build-standalone/releases/download/$(PYTHON_RELEASE)/$(call __python_archive,$(1),$(2))

__arch_python = $(or $($(1)_PYTHON),$(error no python defined for $(1)))
__asys_python = $(or $($(1)_ASYS),$(error no asys defined for $(1)))
__python_dir = python-$(call __asys_python,$(1))-$(PYTHON_VERSION)
python_dir = $(call __python_dir,$(call arch,$(1)))

define python_package

$(1)_PYTHON := $(2)
python-$(2)_URL := $(call python_url,$(2),.tar.gz)
python-$(2)_VER := $(PYTHON_VERSION)
python-$(2)_DIR := $(call __python_dir,$(1))
python-$(2)_TOPDIR := python

.tool.$(1).python: .package.python-$(2).unpack

.tool.$(1).python-info: .package.python-$(2).info

.package.info: .package.python-$(2).info

.package.fetch: .package.python-$(2).fetch

.package.unpack: .package.python-$(2).unpack

clean: .package.python-$(2).clean

endef

# these arches cant use or dont have system interpreter
$(eval $(call python_package,LINUX,x86_64-unknown-linux-gnu))

PYTHON_PACKAGE_TARGETS := WIN32 WIN64 MACOSX86 MACOSARM

$(eval $(call python_package,WIN32,i686-pc-windows-msvc))
$(eval $(call python_package,WIN64,x86_64-pc-windows-msvc))

$(eval $(call python_package,MACOSX86,x86_64-apple-darwin))
$(eval $(call python_package,MACOSARM,aarch64-apple-darwin))

# expect host python to be available before running preparation script
$(PYTHON_PACKAGE_TARGETS:%=.tool.%.python): .package.python-$(call __arch_python,LINUX).unpack

# todo: pin these manually? special case for release workflow
python-sha256sums_URL := https://github.com/astral-sh/python-build-standalone/releases/download/$(PYTHON_RELEASE)/SHA256SUMS
python-sha256sums_VER := $(PYTHON_RELEASE)
python-sha256sums_DIR := $(REPODIR)
python-sha256sums_SHA := 72e29bd6b86194d64eca565416c3cd527c7d41260b445ed56e0f3e721e825e45
python-sha256sums_ARCHIVE := $(PYTHON_RELEASE).SHA256SUMS

.PHONY: .tool.python-fetch

.tool.python-fetch: $(foreach target,$(PYTHON_PACKAGE_TARGETS),.package.python-$(call __arch_python,$(target)).fetch)
.tool.python-fetch: .package.python-sha256sums.fetch

.tool.python-fetch:
	( cd $(REPODIR) \
		&& sha256sum --check --ignore-missing $(python-sha256sums_ARCHIVE) )

.PHONY: .tool.python

.tool.python: $(BUILD_TARGETS:%=.tool.%.python)

.PHONY: .tool.%.python .tool.%.python-info

# if not explicitly set above, other targets expect
# 1) system python being available i.e. /usr/bin/env python3
# 2) system python being able to execute our script
# 3) a) system python is used
#    b) user-provided python is used, see python_via_env.py
PYTHON_VIA_ENV_TARGETS := $(filter-out $(PYTHON_PACKAGE_TARGETS),$(BUILD_TARGETS))

python-pkgdir = $(PKGDIR)/pkg.$(call arch,$@).python

python_via_env_archive = $(call ahost,$(1)).python-via-env$(call archiveext,$(1))

$(PYTHON_VIA_ENV_TARGETS:%=.tool.%.python):
	@echo $@
	rm -rf $(python-pkgdir)
	mkdir -p $(python-pkgdir)
	(cd $(python-pkgdir) \
		&& mkdir -p python3 \
		&& touch python3/placeholder_for_arduino \
		&& cp -v $(PWD)/python_via_env.py python3/python3 \
		&& chmod +x python3/python3 )
	(cd $(python-pkgdir)/python3 \
		&& ln -s python3 python)
	rm -vf $(PKGDIR)/$(call ahost,$@).python-*
	$(call tool_make_archive,$(call python_via_env_archive,$@),$(python-pkgdir)/python3,$@)
	rm -rf $(python-pkgdir)

python_archive = $(call ahost,$(1)).python-$(PYTHON_VERSION)+$(PYTHON_RELEASE)$(call archiveext,$(1))

# 1) prepare PyZipFile (aka pythonVER.zip) with immutable standard library pyc
# 2) prepare pythonVER._pth pointing to PyZipFile and any relevant paths (Windows DLLs dir, current dir, etc.)
# 3) ensure root dir is named python3, and there is callable python3/python3(.exe)
# 4) repackage through archivecmd
$(PYTHON_PACKAGE_TARGETS:%=.tool.%.python): .package.python-$(call __arch_python,LINUX).unpack
	@echo $@
	rm -rf $(python-pkgdir)
	mkdir -p $(python-pkgdir)
	(cd $(python-pkgdir) \
		&& cp -r $(REPODIR)/$(call python_dir,$@) python3/ \
		&& find python3/ -name '*.pyc' -delete \
		&& $(zip_PRE) \
		&& env TZ=UTC SOURCE_DATE_EPOCH=$(SOURCE_DATE_EPOCH) \
			$(REPODIR)/$(call __python_dir,LINUX)/bin/python3 \
			$(PWD)/prepare_python_build_standalone.py python3/ )
	rm -vf $(PKGDIR)/$(call ahost,$@).python-*
	$(call tool_make_archive,$(call python_archive,$@),$(python-pkgdir)/python3,$@)
	rm -rf $(python-pkgdir)

.PHONY: .arduino.%

.arduino.checkout:
	@echo "-------- Preparing Arduino repo at $(ARDUINO)"
	test -d $(ARDUINO) || \
		git clone \
			--branch $(INSTALL_BRANCH) \
			--recurse-submodules tools/sdk/ssl \
			--recurse-submodules tools/sdk/lwip2 \
			https://github.com/$(GHUSER)/Arduino \
			$(ARDUINO)
	(cd $(ARDUINO) \
		&& git reset --hard --recurse-submodules \
		&& git clean -x -f -d \
		&& git checkout $(INSTALL_BRANCH) \
		&& git pull --recurse-submodules )

.arduino.tools: tools

ARDUINO_PKGFILE := $(ARDUINO)/package/package_esp8266com_index.template.json

.arduino.package-template-json:
	@echo "-------- Updating package template.json"
	./patch_json.py \
		--pkgfile "$(ARDUINO_PKGFILE)" \
		--tool $(TARGET_ARCH)-gcc \
		--version "$(VERSION)" \
		--glob '$(PKGDIR)/*.$(TARGET_ARCH)-gcc*.json'
	./patch_json.py \
		--pkgfile "$(ARDUINO_PKGFILE)" \
		--tool mkspiffs \
		--version "$(mkspiffs_REF)+git$(REV)" \
		--glob '$(PKGDIR)/*.mkspiffs-*.json'
	./patch_json.py \
		--pkgfile "$(ARDUINO_PKGFILE)" \
		--tool mklittlefs \
		--version "$(subst -,_,$(mklittlefs_REF))+git$(REV)" \
		--glob '$(PKGDIR)/*.mklittlefs-*.json'
	./patch_json.py \
		--pkgfile "$(ARDUINO_PKGFILE)" \
		--tool python3 \
		--version "$(PYTHON_VERSION)+$(PYTHON_RELEASE)" \
		--glob '$(PKGDIR)/*python*$(PYTHON_VERSION)+$(PYTHON_RELEASE)*.json' \
		--glob '$(PKGDIR)/*python-via-env*.json'

.arduino.build: .package.python-$(call __arch_python,LINUX).unpack
	(cd $(ARDUINO)/tools \
		&& $(REPODIR)/$(call __python_dir,LINUX)/bin/python3 get.py --tool $(TARGET_ARCH)-gcc )
	@echo "-------- Building and installing BearSSL"
	(cd $(ARDUINO)/tools/sdk/ssl \
		&& make clean && make all && make install)
	@echo "-------- Building and installing LWIP2"
	(cd $(ARDUINO)/tools/sdk/lwip2 \
		&& make clean && make install)
	@echo "-------- Building eboot.elf"
	(cd $(ARDUINO)/bootloaders/eboot \
		&& make clean && make)

# Only the native version has to be done to install libs to GIT

.PHONY: install

install:
	@echo $@
	$(MAKE) .arduino.checkout
	$(MAKE) .arduino.tools
	$(MAKE) .arduino.package-template-json
	$(MAKE) .arduino.build

# Upload a draft toolchain release

.PHONY: upload

upload: tools
	@echo $@
	rm -rf ./arena.upload
	mkdir ./arena.upload
	(cd ./arena.upload \
		&& python -m venv ./venv \
		&& venv/bin/pip install -q pygithub \
		&& venv/bin/python $(PWD)/upload_release.py \
			--user "$(GHUSER)" \
			--token "$(GHTOKEN)" \
			--tag "$(REL)$(SUBREL)" \
			--name "ESP8266 Quick Toolchain $(VERSION)" \
			--msg "See https://github.com/esp8266/Arduino for more info" \
			$$(find $(PKGDIR)/ -maxdepth 1 -name "*.tar.gz" -o -name "*.zip") )
	rm -rf ./arena.upload
