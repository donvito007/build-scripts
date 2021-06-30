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
	export KBUILD_BUILD_USER="cepheus"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date} "
	make $args cepheus_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for cepheus!"
    fi
	mkzipKebab
	tg_notify "Finish building cepheus!"
}

mkzipKebab(){
	mv -f ~/src/out/arch/arm64/boot/Image-dtb ~/src/anykernel3
	cd ~/src/anykernel3
	zip -r "MarisaKernel-cepheus-$middlever-$date.zip" *
	mv -f "MarisaKernel-cepheus-$middlever-$date.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for kebab!"
	tg_upload "MarisaKernel-cepheus-$middlever-$date.zip"
	cd $source
}

buildinstantnoodle(){
	export KBUILD_BUILD_USER="raphael"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date} "
	make $args raphael_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for raphael!"
    fi
	mkzipinstantnoodle
	tg_notify "Finish building raphael!"
}

mkzipinstantnoodle(){
	mv -f ~/src/out/arch/arm64/boot/Image-dtb ~/src/anykernel3
	cd ~/src/anykernel3
	zip -r "MarisaKernel-raphael-$middlever-$date.zip" *
	mv -f "MarisaKernel-raphael-$middlever-$date.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for raphael!"
	tg_upload "MarisaKernel-raphael-$middlever-$date.zip"
	cd $source
}

tg_notify "LOG: START BUILDING!"
cd /drone/src
git submodule init
git submodule update

clean
buildKebab
cd /drone/src
buildinstantnoodle

log "Build finished for #${DRONE_BUILD_NUMBER} ( ${date} )."
