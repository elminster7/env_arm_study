#bin/sh
sudo apt install -y gcc-aarch64-linux-gnu libglib2.0 libpixman-1-dev build-essential libssl-dev

build_qemu() {
    wget https://download.qemu.org/qemu-5.0.0.tar.xz ~/
    tar xf qemu-5.0.0.tar.xz
    cd qemu-5.0.0
    ./configure --target-list=aarch64-softmmu
    make -j $(nproc)
    make install
}

build_raspberry_kernel() {
    git clone -b rpi-5.6.y https://github.com/raspberrypi/linux.git linux-5.6
    cd linux-5.6
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make bcm2711_defconfig
    ARCH=arm64 CROSS_COMPILE=aarch64-linux-gnu- make -j $(nproc)
}

download_ubuntu_filesystem() {
    wget https://releases.linaro.org/aarch64-laptops/images/ubuntu/18.04/aarch64-laptops-bionic-prebuilt.img.xz
    tar xf aarch64-laptops-bionic-prebuilt.img.xz
}

prepare_compress_image() {
    wget https://releases.linaro.org/aarch64-laptops/images/ubuntu/18.04/aarch64-laptops-bionic-prebuilt.img.xz
    unxz $PWD/aarch64-laptops-bionic-prebuilt.img.xz
    FILESYSTEM=aarch64-laptops-bionic-prebuilt.img
    EFI=`fdisk -l $PWD/$FILESYSTEM | grep EFI | awk '{print $2}'`
    Linux=`fdisk -l $PWD/$FILESYSTEM | grep Linux | awk '{print $2}'`
    EFI_SIZE=`expr $EFI \* 512`
    Linux_Size=`expr $Linux \* 512`

    if [ $1 == '1' ]; then
	sudo mount -v -o offset=$EFI_SIZE -t vfat $FILESYSTEM mnt1
    fi
    if [ $1 == '2' ]; then
	sudo mount -v -o offset=$Linux_Size -t ext4 $FILESYSTEM mnt2
    fi
    
}

build_qemu
build_raspberry_kernel
download_ubuntu_filesystem
prepare_compress_image
