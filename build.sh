#!/bin/bash
clang_path="${HOME}/proton-clang/bin/clang"
gcc_path="${HOME}/proton-clang/bin/aarch64-linux-gnu-"
gcc_32_path="${HOME}/proton-clang/bin/arm-linux-gnueabi-"

date="`date +"%m%d%H%M"`"
firstver="Marisa"
middlever="RUBY"

args="-j64 O=out \
	ARCH=arm64 \
	SUBARCH=arm64 "

args+="CC=$clang_path \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	CROSS_COMPILE=$gcc_path "

args+="CROSS_COMPILE_ARM32=$gcc_32_path "

clean(){
	make mrproper
	make $args mrproper
}

tg_upload(){
    curl -s https://api.telegram.org/bot"${BOTTOKEN}"/sendDocument -F document=@"${1}" -F chat_id="${CHATID}"
}

tg_notify(){
    curl -s https://api.telegram.org/bot"${BOTTOKEN}"/sendMessage -d parse_mode="Markdown" -d text="${1}" -d chat_id="${CHATID}"
}

log(){
	tg_notify "LOG: ${1}"
}

terminate(){
  log "${1}"
  exit 1
}


buildKebab(){
	export KBUILD_BUILD_USER="judyln"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date} "
	make $args STB_EM_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for judyln!"
    fi
	mkzipKebab
	tg_notify "Finish building judyln!"
}

mkzipKebab(){
	mv -f ~/src/out/arch/arm64/boot/Image.gz-dtb ~/src/anykernel3
	cd ~/src/anykernel3
	zip -r "MarisaKernel-G7-$middlever-$date.zip" *
	mv -f "MarisaKernel-G7-$middlever-$date.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for LG G7!"
	tg_upload "MarisaKernel-G7-$middlever-$date.zip"
	cd $source
}

tg_notify "LOG: START BUILDING!"
cd /drone/src
git submodule init
git submodule update

clean
buildKebab

log "Build finished for #${DRONE_BUILD_NUMBER} ( ${date} )."
