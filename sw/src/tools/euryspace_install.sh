#!/bin/bash
################################
# Project: EurySPACE CCSDS RX/TX
# Design Name: euryspace_install.sh
# Version: 1.0.0
# Description:
# EurySPACE installation tool
################################
# Author(s):
# Guillaume REMBERT
################################
# Licence:
# MIT
################################
# Changes list:
# 2017/09/04: initial release
################################

set -x
set -e

#Get input arguments:
EURYSPACE_OPERATING_SYSTEM=$1 
EURYSPACE_PRODUCTION=$2
EURYSPACE_USER=$3
EURYSPACE_DESTINATION=$4
EURYSPACE_BUILD_PARALLELISM=9

###### TOOLS AND SOURCE CODE REPOSITORIES ######
#TODO: merge or1k-gcc + or1k-linux with upstream
###### fusesoc
## description: SoC build and sources management tool
## repository: https://github.com/olofk/fusesoc.git
EURYSPACE_REPO_FUSESOC="https://github.com/euryecetelecom/fusesoc.git"
###### orpsoc-cores
## description: hdl cores and systems descriptions (used by fusesoc)
## repository: https://github.com/openrisc/orpsoc-cores.git
EURYSPACE_REPO_ORPSOC_CORES="https://github.com/euryecetelecom/orpsoc-cores.git"
###### newlib
## description:* minimal library for baremetal applications or1k-elf
## repository: https://github.com/openrisc/newlib.git
EURYSPACE_REPO_NEWLIB="https://github.com/euryecetelecom/newlib.git"
###### or1k-gcc
## description: compiler for arch or1k (cross-compilation)
## repository: https://github.com/openrisc/or1k-gcc.git
#EURYSPACE_REPO_OR1K_GCC="https://github.com/euryecetelecom/or1k-gcc.git"
###### or1k-src
## description: cross-linker and cross-assembler for target platform (binutils)
## repository: https://github.com/openrisc/or1k-src.git
#EURYSPACE_REPO_OR1K_SRC="https://github.com/euryecetelecom/or1k-src"
###### or1ksim
## description: or1k system simulator
## repository: https://github.com/openrisc/or1ksim.git
EURYSPACE_REPO_OR1KSIM="https://github.com/euryecetelecom/or1ksim.git"
###### or1k-tests
## description: or1k system tests suite
## repository: https://github.com/openrisc/or1k-tests.git
EURYSPACE_REPO_OR1K_TESTS="https://github.com/euryecetelecom/or1k-tests.git"
###### uclibc-or1k
# NOT USED
## description: or1k-linux-uclibc build environment
## repository: https://github.com/openrisc/uClibc-or1k.git
###### musl-cross
## description: or1k-linux-musl build environment
## repository: https://github.com/openrisc/musl-cross.git
EURYSPACE_REPO_MUSL_CROSS="https://github.com/euryecetelecom/musl-cross.git"
###### qemu-system-or32
## description: General emulator - with support for or1k
## repository: git://git.qemu-project.org/qemu.git
EURYSPACE_REPO_QEMU="https://github.com/euryecetelecom/qemu.git"
###### linux
## description: embedded linux to use with or1k
## repository: https://github.com/openrisc/linux.git
EURYSPACE_REPO_LINUX="https://github.com/euryecetelecom/linux.git"
###### binutils-gdb
## description: software debugger
## repository: git://sourceware.org/git/binutils-gdb.git
EURYSPACE_REPO_BINUTILS_GDB="https://github.com/euryecetelecom/binutils-gdb.git"
###### uboot
## description: minimal bootloader
## repository: git://git.denx.de/u-boot.git
EURYSPACE_REPO_U_BOOT="https://github.com/euryecetelecom/u-boot.git"
###### busybox
## description: TBD
## repository: http://git.busybox.net/busybox
###### openocd
## description: chip debugger
## repository: git://git.code.sf.net/p/openocd/code
EURYSPACE_REPO_OPENOCD="https://github.com/euryecetelecom/openocd.git"
###### altera-quartus
## description: generation and injection of layouts and build files for ALTERA FPGA platforms
## repository:* https://github.com/altera/$arch/??.git
# *: FIXME - possible to distribute binaries of vendors?
###### xilinx-iselibstdc++-devel
## description: generation and injection of layouts and build files for XILINX FPGA platforms
## repository:* https://github.com/xilinx/$arch/??.git
# *: FIXME - possible to distribute binaries of vendors?
###### icarus
## description: verilog simulator
## repository: https://github.com/steveicarus/iverilog.git
EURYSPACE_REPO_IVERILOG="https://github.com/euryecetelecom/iverilog.git"
###### ghdl
## description: vhdl simulator
## repository: https://github.com/tgingold/ghdl.git
EURYSPACE_REPO_GHDL="https://github.com/euryecetelecom/ghdl.git"
###### gcc
## description: compiler
## repository: git://gcc.gnu.org/git/gcc.git
EURYSPACE_REPO_GCC="https://github.com/euryecetelecom/gcc.git"
##### mor1kx
## description: hdl RISC CPU description 
## repository: https://github.com/openrisc/mor1kx.git
EURYSPACE_REPO_MOR1KX="https://github.com/euryecetelecom/mor1kx.git"
##### isl
## description: Graphite loop optimizations for GCC building
## repository: ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2
EURYSPACE_PACKAGE_ISL="ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2"

###### ENVIRONMENT SETUP ######
getent passwd ${EURYSPACE_USER}  > /dev/null
if [ $? -ne 0 ]; then
  adduser ${EURYSPACE_USER}
fi
if [[ ${EURYSPACE_PRODUCTION} != true ]]
then
  case ${EURYSPACE_OPERATING_SYSTEM} in
    centos7)
      echo "Installing epel repository"
      yum -y install epel-release
      ### STAGE 0: installation of initial development tools
      echo "Installing required tools"
      yum -y install glibc-devel gcc gcc-c++ libstdc++-static libstdc++-devel flex bison patch texinfo ncurses-devel mpfr-devel libmpc-devel libzip-devel expat-devel expat-static elfutils-libelf-devel gperf libftdi libftdi-devel libftdi-c++ libftdi-c++-devel libusb libusb-devel gcc-gnat zlib-devel glib2-devel pixman-devel git wget bzip2 autogen
    ;;
    ubuntu16)
      apt-get install 
    ;;
  esac
  #Preparing target path and enviroment
  echo "Preparing target build directories and environment setup"
  mkdir -p ${EURYSPACE_DESTINATION}/or1k-toolchain/bin ${EURYSPACE_DESTINATION}/or1k-toolchain/src ${EURYSPACE_DESTINATION}/tools/bin ${EURYSPACE_DESTINATION}/tools/src ${EURYSPACE_DESTINATION}/linux/src ${EURYSPACE_DESTINATION}/linux/elf
  chown -R ${EURYSPACE_USER} ${EURYSPACE_DESTINATION}
  PATH=$PATH:${EURYSPACE_DESTINATION}/or1k-toolchain/bin:${EURYSPACE_DESTINATION}/tools/bin
  su ${EURYSPACE_USER} -c "export PATH=$PATH:${EURYSPACE_DESTINATION}/or1k-toolchain/bin:${EURYSPACE_DESTINATION}/tools/bin"
  cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && wget ${EURYSPACE_PACKAGE_ISL} && tar -xjf isl-*.bz2 && mkdir build_isl && cd build_isl && ../isl-*/configure && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
  ### STAGE 1: set-up or1k-src / arch=or1k-elf bootstrap only
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone ${EURYSPACE_REPO_BINUTILS_GDB}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir build_or1k-binutils-gdb && cd build_or1k-binutils-gdb && ../binutils-gdb/configure --target=or1k-elf --prefix=${EURYSPACE_DESTINATION}/or1k-toolchain --enable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup --disable-gdbtk --disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb --with-sysroot --disable-newlib --disable-libgloss --disable-werror && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  # Test: launch binary / Result: version of ld
  su ${EURYSPACE_USER} -c "or1k-elf-ld --version"
  ### STAGE 1: set-up or1k-gcc / arch=or1k-elf bootstrap only
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone ${EURYSPACE_REPO_GCC}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir build_or1k-gcc && cd build_or1k-gcc && ../or1k-gcc/configure --target=or1k-elf --prefix=/${EURYSPACE_DESTINATION}/or1k-toolchain --enable-languages=c --disable-shared --disable-libssp && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  # Test: launch binary / Result: version of gcc
  su ${EURYSPACE_USER} -c "or1k-elf-gcc --version"
  ### STAGE 2: set-up newlib / arch=or1k-elf
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone ${EURYSPACE_REPO_NEWLIB}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir build_newlib && cd build_newlib && ../newlib/configure --target=or1k-elf --prefix=/${EURYSPACE_DESTINATION}/or1k-toolchain && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  ### STAGE 2: set-up or1k-gcc / arch=or1k-elf with newlib
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir build_or1k-gcc-newlib && cd build_or1k-gcc-newlib && ../or1k-gcc/configure --target=or1k-elf --prefix=/${EURYSPACE_DESTINATION}/or1k-toolchain --enable-languages=c,c++ --disable-shared --disable-libssp --with-newlib && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  # Test: launch binary / Result: version of the compiler
  su ${EURYSPACE_USER} -c "or1k-elf-g++ --version"
  ### STAGE 2: set-up or1ksim / arch=or1k-elf
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone ${EURYSPACE_REPO_OR1KSIM}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir build_or1ksim && cd build_or1ksim && ../or1ksim/configure --target=or1k-elf --prefix=/${EURYSPACE_DESTINATION}/or1k-toolchain && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  # Test: launch binary / Result: version of the simulator
  su ${EURYSPACE_USER} -c "or1k-elf-sim --version"
  ### STAGE 2:* set-up gdb / arch=or1k-elf
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone ${EURYSPACE_REPO_OR1K_BINUTILS_GDB}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir build_or1k-gdb && cd build_or1k-gdb && ../binutils-gdb/configure --target=or1k-elf --prefix=/${EURYSPACE_DESTINATION}/or1k-toolchain && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  # Test: launch binary / Result: version of the simulator
  su ${EURYSPACE_USER} -c "or1k-elf-gdb --version"
#../or1k-src/configure --target=or1k-elf --prefix=/home/or1k-toolchain --enable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup --disable-gdbtk --disable-libgui --disable-rda --disable-sid --enable-sim --disable-or1ksim --enable-gdb  --with-sysroot --disable-newlib --disable-libgloss
#TODO: OR1KTESTS
##TODO? / TO BE CLEANED
### STAGE 3: set-up linux build stuff / arch=or1k-linux-uclibc
#../or1k-src/configure --target=or1k-linux-uclibc --prefix=$HOME/toolchain --disable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup --disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb --with-sysroot --disable-newlib --disable-libgloss --disable-werror
#make
#make install
#or1k-linux-uclibc-ld --version
#[ROOT]
#cd linux
#ARCH=openrisc make INSTALL_HDR_PATH=$HOME/toolchain/or1k-linux-uclibc/sys-root/usr headers_install
#../or1k-gcc/configure --target=or1k-linux-uclibc --prefix=$HOME/toolchain --disable-libssp --srcdir=../or1k-gcc --enable-languages=c --without-headers --enable-threads=single --disable-libgomp --disable-libmudflap --disable-shared --disable-libquadmath --disable-libatomic --disable-werror
#make -j9
#make install
#make test
#or1k-linux-uclibc-gcc --version
#mkdir -p $HOME/toolchain/or1k-linux-uclibc/sys-root
#cd uClibc
#make ARCH=or1k defconfig
#make -j9
#make PREFIX=$HOME/toolchain/or1k-linux-uclibc/sys-root install
#../or1k-gcc/configure --target=or1k-linux-uclibc --prefix=$HOME/toolchain --disable-libssp --srcdir=../or1k-gcc --enable-languages=c,c++ --enable-threads=posix --disable-libgomp --disable-libmudflap --with-sysroot=$HOME/toolchain/or1k-linux-uclibc/sys-root --disable-multilib --disable-werror
#make -j9
#make install
#../or1ksim/configure --target=or1k-linux-uclibc --prefix=$HOME/toolchain

#TODO: MUSL
#ARCH=or1k
#GCC_URL=https://github.com/openrisc/or1k-gcc/archive/musl-4.9.2.tar.gz
#GCC_EXTRACT_DIR=or1k-gcc-musl-4.9.2
#GCC_VERSION=or1k-4.9.2
#LINUX_HEADERS_URL=http://www.kernel.org/pub/linux/kernel/v4.x/linux-4.2.tar.xz

#TODO: fusesoc

  #Icarus
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/tools/src && git clone ${EURYSPACE_REPO_IVERILOG}"
  #TODO: autoconf
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/tools/src && mkdir build_iverilog && cd build_iverilog && ../iverilog/configure --prefix=/${EURYSPACE_DESTINATION}/tools && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  #GHDL
#  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/tools/src && git clone ${EURYSPACE_REPO_GCC}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/tools/src && git clone ${EURYSPACE_REPO_GHDL}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/tools/src && mkdir build_ghdl && cd ghdl && ./configure --with-gcc=${EURYSPACE_DESTINATION}/or1k-toolchain/src/gcc && make copy-sources && cd ../build_ghdl && ../ghdl/configure --prefix=/${EURYSPACE_DESTINATION}/tools  --enable-languages=c,vhdl --disable-bootstrap --disable-lto --disable-multilib && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  #OPENOCD
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/tools/src && git clone ${EURYSPACE_REPO_OPENOCD}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/tools/src && mkdir build_openocd && cd build_openocd && ../openocd/configure --prefix=/${EURYSPACE_DESTINATION}/tools  --enable-ftdi --enable-usb_blaster_libftdi && make -j${EURYSPACE_BUILD_PARALLELISM} && make install"
  #Linux
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/linux/src && git clone ${EURYSPACE_REPO_LINUX}"
  su ${EURYSPACE_USER} -c "cd ${EURYSPACE_DESTINATION}/linux/src && mkdir build_linux && cd build_linux"
  export ARCH=openrisc && export CROSS_COMPILE=or1k-elf-
  # Configure for simulation
  #make or1ksim_defconfig
  # Configure for specific SoC
  #make de0_nano_defconfig
  #make musl_defconfig
  #make menuconfig
  #make -j$BUILD_PARALLELISM
fi

#TBD: Quartus??
#TBD: Xilinx??

#TODO: production / from RPM/DEB PKG
#yum install qemu-system-or32
#yum install openocd
