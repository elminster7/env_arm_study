#!/bin/sh
# only nvidia ffmpeg support.
# purge remove cuda with nvidia driver on system.
sudo rm /etc/apt/sources.list.d/cuda*
sudo apt remove -y --autoremove nvidia-cuda-toolkit
sudo apt remove -y --autoremove nvidia-*

#
# setip correct cuda ppa.
sudo apt update
sudo add-apt-repository ppa:graphics-drivers/ppa
sudo apt-key adv --fetch-keys  http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64/7fa2af80.pub
sudo bash -c 'echo "deb http://developer.download.nvidia.com/compute/cuda/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda.list'
sudo bash -c 'echo "deb http://developer.download.nvidia.com/compute/machine-learning/repos/ubuntu1804/x86_64 /" > /etc/apt/sources.list.d/cuda_learn.list'

#
# install Cuda 10.1 package.
sudo apt update
sudo apt install cuda-10-1
sudo apt install libcudnn7
#sudo apt install nvidia-cuda-toolkit

if grep -q cuda-10.1 $HOME/.profile; then
    echo "exist"
else
    echo "# set PATH for cuda 10.1 installation
    if [ -d "/usr/local/cuda-10.1/bin/" ]; then
       export PATH=/usr/local/cuda-10.1/bin${PATH:+:${PATH}}
       export LD_LIBRARY_PATH=/usr/local/cuda-10.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}
    fi" >> $HOME/.profile
fi

sudo apt install -y libass-dev pkg-config autoconf texinfo zlib1g-dev cmake \
	 mercurial libdrm-dev libvorbis-dev libogg-dev libdrm-dev libvpx-dev

mkdir -p $HOME/ffmpeg_sources

#
# build ffmpeg for nvenc.
build_deploy_nasm() {
    echo "====build_deploy_nasm===="
    cd ~/ffmpeg_sources
    wget https://www.nasm.us/pub/nasm/releasebuilds/2.14.02/nasm-2.14.02.tar.gz
    tar xzvf nasm-2.14.02.tar.gz
    cd nasm-2.14.02
    ./configure --prefix="$HOME/ffmpeg_build" --bindir="$HOME/bin"
    make -j$(nproc) VERBOSE=1
    make -j$(nproc) install
    make -j$(nproc) distclean
}

#Compile libmp3lame
compileLibMP3Lame(){
    echo "====Compiling libmp3lame===="
    sudo apt-get install nasm
    cd ~/ffmpeg_sources
    wget http://repository.timesys.com/buildsources/l/lame/lame-3.99.5/lame-3.99.5.tar.gz
    tar xzvf lame-3.99.5.tar.gz
    cd lame-3.99.5
    ./configure --prefix="$HOME/ffmpeg_build" --enable-nasm --disable-shared
    make -j$(nproc)
    make -j$(nproc) install
    make -j$(nproc) distclean
}

#Compile libopus
compileLibOpus(){
    echo "====Compiling libopus===="
    cd ~/ffmpeg_sources
    wget http://downloads.xiph.org/releases/opus/opus-1.2.1.tar.gz
    tar xzvf opus-1.2.1.tar.gz
    cd opus-1.2.1
    ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
    make -j$(nproc)
    make -j$(nproc) install
    make -j$(nproc) distclean
}

build_deploy_libx264() {
    echo "====build_deploy_libx264===="
    cd ~/ffmpeg_sources
    git clone http://git.videolan.org/git/x264.git
    cd x264/
    PATH="$HOME/bin:$PATH" ./configure --prefix="$HOME/ffmpeg_build" --enable-static --enable-shared
    PATH="$HOME/bin:$PATH" make -j$(nproc) VERBOSE=1
    make -j$(nproc) install VERBOSE=1
    make -j$(nproc) distclean
}

build_deploy_libx265() {
    echo "====build_deploy_libx265===="
    sudo apt -y install mercurial
    cd ~/ffmpeg_sources
    hg clone https://bitbucket.org/multicoreware/x265
    cd ~/ffmpeg_sources/x265/build/linux
    PATH="$HOME/bin:$PATH" cmake -G "Unix Makefiles" -DCMAKE_INSTALL_PREFIX="$HOME/ffmpeg_build" -DENABLE_SHARED:bool=off ../../source
    make -j$(nproc) VERBOSE=1
    make -j$(nproc) install VERBOSE=1
    make -j$(nproc) clean VERBOSE=1
}

build_deploy_libfdk_aac() {
    echo "====build_deploy_libfdk_aac===="
    cd ~/ffmpeg_sources
    wget -O fdk-aac.tar.gz https://github.com/mstorsjo/fdk-aac/tarball/master
    tar xzvf fdk-aac.tar.gz
    cd mstorsjo-fdk-aac*
    autoreconf -fiv
    ./configure --prefix="$HOME/ffmpeg_build" --disable-shared
    make -j$(nproc)
    make -j$(nproc) install
    make -j$(nproc) distclean
}

build_configure_libvpx() {
    echo "====build_configure_libvpx===="
    cd ~/ffmpeg_sources
    git clone https://github.com/webmproject/libvpx
    cd libvpx
    ./configure --prefix="$HOME/ffmpeg_build" --enable-runtime-cpu-detect --enable-vp9 --enable-vp8 \
		--enable-postproc --enable-vp9-postproc --enable-multi-res-encoding --enable-webm-io --enable-better-hw-compatibility --enable-vp9-highbitdepth --enable-onthefly-bitpacking --enable-realtime-only --cpu=native --as=nasm 
    time make -j$(nproc)
    time make -j$(nproc) install
    time make clean -j$(nproc)
    time make distclean
}

build_libvorbis() {
    echo "====build_libvorbis===="
    sudo apt install -y autoconf automake libtool pkg-config
    cd ~/ffmpeg_sources
    #git clone https://git.xiph.org/vorbis.git
    git clone https://github.com/xiph/vorbis.git
    cd vorbis
    autoreconf -ivf
    ./configure --enable-static --prefix="$HOME/ffmpeg_build"
    time make -j$(nproc)
    time make -j$(nproc) install
    time make clean -j$(nproc)
    time make distclean
}

build_ffmpeg() {
    echo "====build_ffmpeg===="
    cd ~/ffmpeg_sources
    export PATH=/usr/local/cuda-10.1/bin${PATH:+:${PATH}}
    export LD_LIBRARY_PATH=/usr/local/cuda-10.1/lib64${LD_LIBRARY_PATH:+:${LD_LIBRARY_PATH}}

    git clone https://github.com/FFmpeg/FFmpeg -b master
    cd FFmpeg
    PATH="$HOME/bin:$PATH" PKG_CONFIG_PATH="$HOME/ffmpeg_build/lib/pkgconfig:/opt/intel/mediasdk/lib/pkgconfig" ./configure \
	--pkg-config-flags="--static" \
	--prefix="$HOME/bin" \
	--bindir="$HOME/bin" \
	--extra-cflags="-I$HOME/bin/include" \
	--extra-ldflags="-L$HOME/bin/lib" \
	--enable-cuda-sdk \
	--enable-cuvid \
	--enable-libnpp \
	--extra-cflags="-I/usr/local/cuda/include/" \
	--extra-ldflags=-L/usr/local/cuda/lib64/ \
	--enable-nvenc \
	--enable-libass \
	--disable-debug \
	--enable-libvorbis \
	--enable-libvpx \
	--enable-libdrm \
	--enable-opencl \
	--enable-gpl \
	--cpu=native \
	--enable-opengl \
	--enable-libfdk-aac \
	--enable-libx264 \
	--enable-libx265 \
	--enable-openssl \
	--extra-libs="-lpthread -lm -lz" \
	--enable-nonfree 
    PATH="$HOME/bin:$PATH" make -j$(nproc) 
    make -j$(nproc) install 
    make -j$(nproc) distclean 
    hash -r
}

install_ffmpeg_libraries() {
    cd ~/ffmpeg_build/
    tar cfvz lib.tar.gz *
    tar xf lib.tar.gz -C /usr/
    cp ~/bin/ff* /usr/local/bin
}

install_on_nvenc_enablement_for_ffmpeg() {
    cd ~/ffmpeg_sources
    git clone https://git.videolan.org/git/ffmpeg/nv-codec-headers.git
    cd nv-codec-headers
    make
    make install PREFIX="$HOME/ffmpeg_build"

    build_deploy_nasm
    build_deploy_libx264
    build_deploy_libx265
    build_deploy_libfdk_aac
    compileLibOpus
    compileLibMP3Lame
    build_configure_libvpx
    build_libvorbis
    build_ffmpeg
    install_ffmpeg_libraries
}

install_on_nvenc_enablement_for_ffmpeg
