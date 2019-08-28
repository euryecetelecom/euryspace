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

#Get input arguments and pass it to sub-shells:
export EURYSPACE_OPERATING_SYSTEM=$1 
export EURYSPACE_PRODUCTION=$2
export EURYSPACE_USER=$3
export EURYSPACE_DESTINATION=$4
export EURYSPACE_BUILD_PARALLELISM=$5

#TODO: add make check wherever possible
install_tools(){
  ###### TOOLS AND SOURCE CODE REPOSITORIES ######
  EURYSPACE_REPO_ROOTNAME="https://github.com/euryecetelecom/"
  #TODO: merge or1k-gcc + binutils-gdb + or1k-linux with upstream
  ###### fusesoc
  ## description: SoC build and sources management tool
  ## repository: https://github.com/olofk/fusesoc.git
  EURYSPACE_REPO_FUSESOC="${EURYSPACE_REPO_ROOTNAME}fusesoc.git"
  ###### orpsoc-cores
  ## description: hdl cores and systems descriptions (used by fusesoc)
  ## repository: https://github.com/openrisc/orpsoc-cores.git
  EURYSPACE_REPO_ORPSOC_CORES="${EURYSPACE_REPO_ROOTNAME}orpsoc-cores.git"
  ###### newlib
  ## description:* minimal library for baremetal applications or1k-elf
  ## repository: https://github.com/openrisc/newlib.git
  EURYSPACE_REPO_NEWLIB="${EURYSPACE_REPO_ROOTNAME}newlib.git"
  ###### or1k-gcc
  ## description: compiler for arch or1k (cross-compilation)
  ## repository: https://github.com/openrisc/or1k-gcc.git
  EURYSPACE_REPO_OR1K_GCC="${EURYSPACE_REPO_ROOTNAME}or1k-gcc.git"
  ###### or1k-src
  ## description: cross-linker and cross-assembler for target platform (binutils)
  ## repository: https://github.com/openrisc/or1k-src.git
  #EURYSPACE_REPO_OR1K_SRC="https://github.com/euryecetelecom/or1k-src"
  ###### or1ksim
  ## description: or1k system simulator
  ## repository: https://github.com/openrisc/or1ksim.git
  EURYSPACE_REPO_OR1KSIM="${EURYSPACE_REPO_ROOTNAME}or1ksim.git"
  ###### or1k-tests
  ## description: or1k system tests suite
  ## repository: https://github.com/openrisc/or1k-tests.git
  EURYSPACE_REPO_OR1K_TESTS="${EURYSPACE_REPO_ROOTNAME}or1k-tests.git"
  ###### uclibc-or1k
  # NOT USED
  ## description: or1k-linux-uclibc build environment
  ## repository: https://github.com/openrisc/uClibc-or1k.git
  ###### musl-cross
  ## description: or1k-linux-musl build environment
  ## repository: https://github.com/openrisc/musl-cross.git
  EURYSPACE_REPO_MUSL_CROSS="${EURYSPACE_REPO_ROOTNAME}musl-cross.git"
  ###### qemu-system-or32
  ## description: General emulator - with support for or1k
  ## repository: git://git.qemu-project.org/qemu.git
  EURYSPACE_REPO_QEMU="${EURYSPACE_REPO_ROOTNAME}qemu.git"
  ###### linux
  ## description: embedded linux to use with or1k
  ## repository: https://github.com/openrisc/linux.git
  EURYSPACE_REPO_OR1K_LINUX="${EURYSPACE_REPO_ROOTNAME}or1k-linux.git"
  ###### binutils-gdb
  ## description: software debugger
  ## repository: git://sourceware.org/git/binutils-gdb.git
  EURYSPACE_REPO_BINUTILS_GDB="${EURYSPACE_REPO_ROOTNAME}binutils-gdb.git"
  ###### uboot
  ## description: minimal bootloader
  ## repository: git://git.denx.de/u-boot.git
  EURYSPACE_REPO_U_BOOT="${EURYSPACE_REPO_ROOTNAME}u-boot.git"
  ###### busybox
  ## description: TBD
  ## repository: http://git.busybox.net/busybox
  ###### openocd
  ## description: chip debugger
  ## repository: git://git.code.sf.net/p/openocd/code
  EURYSPACE_REPO_OPENOCD="${EURYSPACE_REPO_ROOTNAME}openocd.git"
  ###### altera-quartus
  ## description: generation and injection of layouts and build files for ALTERA FPGA platforms
  ## repository:* https://github.com/altera/$arch/??.git
#FIXME - possible to distribute binaries of vendors?
  ###### xilinx-ise
  ## description: generation and injection of layouts and build files for XILINX FPGA platforms
  ## repository:* https://github.com/xilinx/$arch/??.git
#FIXME - possible to distribute binaries of vendors?
  ###### icarus
  ## description: verilog simulator
  ## repository: https://github.com/steveicarus/iverilog.git
  EURYSPACE_REPO_IVERILOG="${EURYSPACE_REPO_ROOTNAME}iverilog.git"
  ###### ghdl
  ## description: vhdl simulator
  ## repository: https://github.com/tgingold/ghdl.git
  EURYSPACE_REPO_GHDL="${EURYSPACE_REPO_ROOTNAME}ghdl.git"
  ###### gcc
  ## description: compiler
  ## repository: git://gcc.gnu.org/git/gcc.git
  EURYSPACE_REPO_GCC="${EURYSPACE_REPO_ROOTNAME}gcc.git"
  ##### mor1kx
  ## description: hdl RISC CPU description 
  ## repository: https://github.com/openrisc/mor1kx.git
  EURYSPACE_REPO_MOR1KX="${EURYSPACE_REPO_ROOTNAME}mor1kx.git"
  ##### isl
  ## description: graphite loop optimizations for GCC building
  ## repository: ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2
  EURYSPACE_PACKAGE_GCC_ISL="ftp://gcc.gnu.org/pub/gcc/infrastructure/isl-0.16.1.tar.bz2"
  ##### xenomai
  ## description: real time capabilities for linux
  ## repository: https://git.xenomai.org/xenomai-3.git
  EURYSPACE_REPO_XENOMAI="${EURYSPACE_REPO_ROOTNAME}xenomai.git"

  #~ set -x
  #~ set -e
  export PATH=$PATH:${EURYSPACE_DESTINATION}/or1k-toolchain/bin:${EURYSPACE_DESTINATION}/tools/bin
  if ! command -v or1k-elf-ld --version > /dev/null; then
    ### STAGE 1: set-up or1k-src / arch=or1k-elf bootstrap only
    if ! test -e ${EURYSPACE_DESTINATION}/or1k-toolchain/src/binutils-gdb ; then
      cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone --depth=1 ${EURYSPACE_REPO_BINUTILS_GDB}
    fi
    cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir -p build_or1k-binutils-gdb && cd build_or1k-binutils-gdb && ../binutils-gdb/configure --target=or1k-elf --prefix=${EURYSPACE_DESTINATION}/or1k-toolchain --enable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup --disable-gdbtk --disable-libgui --disable-rda --disable-sid --disable-sim --disable-gdb --with-sysroot --disable-newlib --disable-libgloss --disable-werror && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
    # Test: launch binary / Result: version of ld
    or1k-elf-ld --version
  fi
  if ! command -v or1k-elf-gcc --version > /dev/null ; then
    ### STAGE 1: set-up or1k-gcc / arch=or1k-elf bootstrap only
    if ! test -e ${EURYSPACE_DESTINATION}/or1k-toolchain/src/or1k-gcc ; then
      cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone --depth=1 ${EURYSPACE_REPO_OR1K_GCC}
    fi
    cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src/or1k-gcc && ./contrib/download_prerequisites && tar -xjf isl-*.bz2 && tar -xjf gmp-*.bz2 && tar -xzf mpc-*.tar.gz && tar -xjf mpfr-*.bz2
    cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir -p build_or1k-gcc && cd build_or1k-gcc && ../or1k-gcc/configure --target=or1k-elf --prefix=${EURYSPACE_DESTINATION}/or1k-toolchain --enable-languages=c --disable-shared --disable-libssp && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
#FIXME: make check fail
    # Test: launch binary / Result: version of gcc
    or1k-elf-gcc --version
  fi
  if ! command -v or1k-elf-g++ --version > /dev/null; then
    ### STAGE 2: set-up newlib / arch=or1k-elf
    if ! test -e ${EURYSPACE_DESTINATION}/or1k-toolchain/src/newlib ; then
      cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone --depth=1 ${EURYSPACE_REPO_NEWLIB}
    fi
    cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir -p build_newlib && cd build_newlib && ../newlib/configure --target=or1k-elf --prefix=${EURYSPACE_DESTINATION}/or1k-toolchain && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
    ### STAGE 2: set-up or1k-gcc / arch=or1k-elf with newlib
    cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir -p build_or1k-gcc-newlib && cd build_or1k-gcc-newlib && ../or1k-gcc/configure --target=or1k-elf --prefix=/${EURYSPACE_DESTINATION}/or1k-toolchain --enable-languages=c,c++ --disable-shared --disable-libssp --with-newlib && make CXXFLAGS+=" -std=gnu++98" -j${EURYSPACE_BUILD_PARALLELISM} && make install
    # Test: launch binary / Result: version of the compiler
    or1k-elf-g++ --version
  fi
  if ! command -v or1k-elf-sim --version > /dev/null; then
    ### STAGE 2: set-up or1ksim / arch=or1k-elf
    if ! test -e ${EURYSPACE_DESTINATION}/or1k-toolchain/src/or1ksim ; then
      cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone --depth=1 ${EURYSPACE_REPO_OR1KSIM}
    fi
    cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir -p build_or1ksim && cd build_or1ksim && ../or1ksim/configure --target=or1k-elf --prefix=${EURYSPACE_DESTINATION}/or1k-toolchain && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
    # Test: launch binary / Result: version of the simulator
#FIXME: simulator version execution stop script execution
    #~ or1k-elf-sim --version
  fi
  if ! command -v or1k-elf-gdb --version > /dev/null; then
    ### STAGE 2: set-up gdb / arch=or1k-elf
    if ! test -e ${EURYSPACE_DESTINATION}/or1k-toolchain/src/isl-0.16.1 ; then
      cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && wget ${EURYSPACE_PACKAGE_GCC_ISL} && tar -xjf isl-0.16.1.tar.bz2 && mkdir build_gcc_isl && cd build_gcc_isl && ../isl-0.16.1/configure && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
    fi
    cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir -p build_or1k-gdb && cd build_or1k-gdb && ../binutils-gdb/configure --target=or1k-elf --prefix=${EURYSPACE_DESTINATION}/or1k-toolchain --disable-sim && make CFLAGS+=' -Wno-parentheses' -j${EURYSPACE_BUILD_PARALLELISM} && make install
#&& make check KO
    # Test: launch binary / Result: version of the debugger
    or1k-elf-gdb --version
  fi
#TODO: OR1KTESTS
#FIXME: to be done for centos7 only / available as deb in debian9
  #Icarus
  #Autoconf KO (no configure file from repo)
  #~ if ! command -v icarus -v > /dev/null; then
    #~ if ! test -e ${EURYSPACE_DESTINATION}/tools/src/iverilog ; then
      #~ cd ${EURYSPACE_DESTINATION}/tools/src && git clone --depth=1 ${EURYSPACE_REPO_IVERILOG}
    #~ fi
    #~ cd ${EURYSPACE_DESTINATION}/tools/src && mkdir -p build_iverilog && cd build_iverilog && ../iverilog/configure --prefix=/${EURYSPACE_DESTINATION}/tools && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
    #~ icarus -v
  #~ fi
  #OPENOCD
  #~ if ! command -v openocd --version > /dev/null; then
    #~ if ! test -e ${EURYSPACE_DESTINATION}/tools/src/openocd ; then
      #~ cd ${EURYSPACE_DESTINATION}/tools/src && git clone --depth=1 ${EURYSPACE_REPO_OPENOCD}
    #~ fi
    #~ cd ${EURYSPACE_DESTINATION}/tools/src && mkdir -p build_openocd && cd openocd && ./bootstrap && cd ../build_openocd && ../openocd/configure --prefix=/${EURYSPACE_DESTINATION}/tools  --enable-ftdi --enable-usb_blaster_libftdi && make CFLAGS+=' -Wno-shift-negative-value' -j${EURYSPACE_BUILD_PARALLELISM} && make install
    #~ # Test: launch binary / Result: version of the simulator
    #~ openocd --version
  #~ fi
  #GHDL
  if ! command -v ghdl --version > /dev/null; then
    if ! test -e ${EURYSPACE_DESTINATION}/tools/src/gcc ; then
      cd ${EURYSPACE_DESTINATION}/tools/src && git clone --branch=gcc-7_2_0-release --depth=1 ${EURYSPACE_REPO_GCC} && cd gcc && git checkout gcc-7_2_0-release
    fi
    if ! test -e ${EURYSPACE_DESTINATION}/tools/src/ghdl ; then
      cd ${EURYSPACE_DESTINATION}/tools/src && git clone --depth=1 ${EURYSPACE_REPO_GHDL}
    fi
    cd ${EURYSPACE_DESTINATION}/tools/src && mkdir -p build_ghdl && cd ghdl && ./configure --with-gcc=${EURYSPACE_DESTINATION}/tools/src/gcc && make copy-sources && cd ../build_ghdl && ../ghdl/configure --prefix=/${EURYSPACE_DESTINATION}/tools && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
# --enable-languages=c,vhdl --disable-bootstrap --disable-lto --disable-multilib  
    # Test: launch binary / Result: version of the simulator
    ghdl --version
  fi
  #Linux
  if ! test -e ${EURYSPACE_DESTINATION}/linux/src/or1k-linux ; then
    cd ${EURYSPACE_DESTINATION}/linux/src && git clone --depth=1 ${EURYSPACE_REPO_OR1K_LINUX}
  fi
  cd ${EURYSPACE_DESTINATION}/linux/src && mkdir -p build_linux && cd build_linux
  export ARCH=openrisc && export CROSS_COMPILE=or1k-elf-
  ##Linux compilation predefined profiles
  # Configure for simulation
  #make or1ksim_defconfig
  # Configure for specific SoC
  #make de0_nano_defconfig
  #make musl_defconfig
  # Configure interactiv
  #make menuconfig
  #make -j$BUILD_PARALLELISM
#TODO: MUSL
  #~ if ! command -v or1k-linux-musl --version > /dev/null; then
    #~ if ! test -e ${EURYSPACE_DESTINATION}/or1k-toolchain/src/musl-cross ; then
      #~ cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && git clone --depth=1 ${EURYSPACE_REPO_MUSL_CROSS}
    #~ fi
    #~ cd ${EURYSPACE_DESTINATION}/or1k-toolchain/src && mkdir -p build_musl-cross && cd musl-cross && source ./config.sh && cd ../build_musl-cross && ../musl-cross/configure --prefix=/${EURYSPACE_DESTINATION}/or1k-toolchain && make -j${EURYSPACE_BUILD_PARALLELISM} && make install
    #~ # Test: launch binary / Result: version of the simulator
    #~ or1k-linux-musl --version
  #~ fi
  
#TODO: Quartus and Xilinx tools if not possible auto / manual setup instructions display
#NB: for de0_nano => quartus tools for altera cyclone IV
  
}

###### ENVIRONMENT SETUP ######
if ! command getent passwd ${EURYSPACE_USER} > /dev/null; then
  adduser ${EURYSPACE_USER}
fi
if [[ ${EURYSPACE_PRODUCTION} != true ]]
then
  ### STAGE 0: installation of initial development tools
  echo "Installing required tools"
  case ${EURYSPACE_OPERATING_SYSTEM} in
    centos7)
      echo "Installing epel repository"
      yum -y install epel-release
      yum -y install glibc-devel gcc gcc-c++ libstdc++-static libstdc++-devel flex bison patch texinfo ncurses-devel libzip-devel expat-devel expat-static elfutils-libelf-devel gperf libftdi libftdi-devel libftdi-c++ libftdi-c++-devel libusb libusb-devel gcc-gnat zlib-devel glib2-devel pixman-devel git wget bzip2 autogen python-pip dejagnu libtool automake
    ;;
    debian9)
      apt-get install -y build-essential glibc-source gcc g++ libstdc++6 libstdc++-6-dev flex bison patch texinfo libncurses5 libzip-dev libexpat1 libexpat1-dev libelf1 gperf libftdi1 libftdi1-dev libftdipp1-2v5 libftdipp1-dev libusb-1.0-0 libusb-1.0-0-dev gnat-6 zlib1g-dev libglib2.0-dev libpixman-1-dev git wget bzip2 autogen python-pip dejagnu libtool automake iverilog openocd
    ;;
  esac
  pip install --upgrade pip setuptools
  pip install fusesoc
  #Preparing target path and enviroment
  echo "Preparing target build directories and environment setup"
  mkdir -p ${EURYSPACE_DESTINATION}/or1k-toolchain/bin ${EURYSPACE_DESTINATION}/or1k-toolchain/src ${EURYSPACE_DESTINATION}/tools/bin ${EURYSPACE_DESTINATION}/tools/src ${EURYSPACE_DESTINATION}/linux/src ${EURYSPACE_DESTINATION}/linux/elf
  chown -R ${EURYSPACE_USER} ${EURYSPACE_DESTINATION}
  export -f install_tools
  su ${EURYSPACE_USER} -c "install_tools"
fi


#TODO: production / from RPM/DEB PKG
#yum install qemu-system-or32
#yum install openocd


##TO BE CLEANED
#../or1k-src/configure --target=or1k-elf --prefix=/home/or1k-toolchain --enable-shared --disable-itcl --disable-tk --disable-tcl --disable-winsup --disable-gdbtk --disable-libgui --disable-rda --disable-sid --enable-sim --disable-or1ksim --enable-gdb  --with-sysroot --disable-newlib --disable-libgloss
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
