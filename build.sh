#!/bin/bash

date="`date +"%m%d%H%M"`"

clean(){
	make clean
	make mrproper
}

tg_upload(){
    curl -s https://api.telegram.org/bot"${BOTTOKEN}"/sendDocument -F document=@"${1}" -F chat_id="${CHATID}"
}

tg_notify(){
    curl -s https://api.telegram.org/bot"${BOTTOKEN}"/sendMessage -d parse_mode="Markdown" -d text="${1}" -d chat_id="${CHATID}"
}

log(){
	tg_notify "Building Pixel3/XL: LOG: ${1}"
}

terminate(){
  log "${1}"
  exit 1
}

mkzipb1c1(){
	mv -f ~/src/out/arch/arm64/boot/Image.lz4 ~/src/anykernel3
	mv -f ~/src/out/arch/arm64/boot/dtbo.img ~/src/anykernel3
	cd ~/src/anykernel3
	zip -r "MarisaKernel-b1c1-$date.zip" *
	mv -f "MarisaKernel-b1c1-$date.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for b1c1!"
	tg_upload "MarisaKernel-b1c1-$date.zip"
	cd /drone/src
}


#!/bin/bash

echo
log "Clean Build Directory"
echo 

clean

echo
log "Issue Build Commands"
echo


git submodule init
git submodule update

mkdir -p out
export ARCH=arm64
export SUBARCH=arm64
export CLANG_PATH=/drone/linux-x86/clang-r383902/bin
export PATH=${CLANG_PATH}:${PATH}
export CLANG_TRIPLE=aarch64-linux-gnu-
export CROSS_COMPILE=/drone/aarch64-linux-android-4.9/bin/aarch64-linux-android-
export CROSS_COMPILE_ARM32=/drone/arm-linux-androideabi-4.9/bin/arm-linux-androideabi-
export LD_LIBRARY_PATH=/drone/linux-x86/clang-r383902/lib64:$LD_LIBRARY_PATH
export KBUILD_BUILD_USER="b1c1"
export KBUILD_BUILD_HOST="MarisaKernel"


echo
log "Set DEFCONFIG"
echo 
# make CC=clang O=out kirisakura_defconfig
make CC=clang O=out b1c1_defconfig

echo
log "Build The Good Stuff"
echo 

make CC=clang O=out -j128 "LOCALVERSION=-${date}"

mkzipb1c1

cd /drone/src

log "Build finished for #${DRONE_BUILD_NUMBER} ( ${date} )."
