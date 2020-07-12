#!/bin/sh
install_clang_9_packages() {
    sudo apt-get install -y libllvm-9-ocaml-dev libllvm9 llvm-9 llvm-9-dev llvm-9-doc llvm-9-examples \
	 llvm-9-runtime clang-9 clang-tools-9 clang-9-doc libclang-common-9-dev libclang-9-dev \
	 libclang1-9 clang-format-9 python-clang-9 clangd-9 libfuzzer-9-dev lldb-9 \
	 lld-9 libc++-9-dev libc++abi-9-dev libomp-9-dev
}

install_bear() {
    git clone https://github.com/rizsotto/Bear.git
    cd $PWD/Bear
    sudo cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 $PWD/Bear;make all; sudo make install
}

install_rtags() {
    git clone https://github.com/Andersbakken/rtags.git
    cd $PWD/rtags
    git submodule init && git submodule update
    sudo cmake -DCMAKE_EXPORT_COMPILE_COMMANDS=1 .
    sudo make -j $(nproc)
    sudo make install
}

install_emacs_packages() {
    sudo apt install -y build-essential texinfo bison flex libxpm-dev pkgconf libssl-dev \
	 gcc-aarch64-linux-gnu autoconf cmake libtiff-dev libgif-dev libjpeg-dev libgtk-3-dev git
}

add_repositories_for_emacs() {
    sudo add-apt-repository ppa:ubuntu-elisp/ppa
    sudo apt update
    sudo apt install -y emacs-snapshot
}

build_raspberrypi_kernel() {
    git clone -b rpi-5.4.y https://github.com/raspberrypi/linux.git linux-5.4
    cd $PWD/linux-5.4
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make bcmrpi3_defconfig
    bear ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -vvvv -j $(nproc)
}

install_ccls() {
    sudo apt install -y snapd
    sudo snap install ccls --classic
}

#install_clang_9_packages
#install_bear
#install_rtags
#install_emacs_packages
#add_repositories_for_emacs
build_raspberrypi_kernel
