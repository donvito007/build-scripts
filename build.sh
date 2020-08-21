#!/bin/bash
clang_path="${HOME}/proton-clang-20200606/bin/clang"
gcc_path="${HOME}/proton-clang-20200606/bin/aarch64-linux-gnu-"
gcc_32_path="${HOME}/proton-clang-20200606/bin/arm-linux-gnueabi-"

date="`date +"%m%d%H%M"`"
firstver="MarisaKernel"
device1="cepheus"
device2="raphael"
middlever="4.0"

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


buildCepheus(){
	export KBUILD_BUILD_USER="Cepheus"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${firstver}-${device1}-${middlever} "
  clean
	make $args cepheus_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for cepheus!"
    fi
	mkzip_cepheus
	tg_notify "Finish building cepheus!"
}

buildRaphael(){
	export KBUILD_BUILD_USER="Raphael"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${firstver}-${device2}-${middlever} "
  clean
	make $args raphael_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for raphael!"
    fi
	mkzip_raphael
	log "Finish building raphael!"
}

mkzip_cepheus(){
	mv -f ~/src/out/arch/arm64/boot/Image-dtb ~/src/anykernel3
	cd ~/src/anykernel3
	zip -r "MarisaKernel-cepheus-$middlever-$date-${DRONE_COMMIT_BRANCH}.zip" *
	mv -f "MarisaKernel-cepheus-$middlever-$date-${DRONE_COMMIT_BRANCH}.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for cepheus!"
	tg_upload "MarisaKernel-cepheus-$middlever-$date-${DRONE_COMMIT_BRANCH}.zip"
	cd $source
}

mkzip_raphael(){
	mv -f ~/src/out/arch/arm64/boot/Image-dtb ~/src/anykernel3
	cd ~/src/anykernel3
	zip -r "MarisaKernel-raphael-$middlever-$date-${DRONE_COMMIT_BRANCH}.zip" *
	mv -f "MarisaKernel-raphael-$middlever-$date-${DRONE_COMMIT_BRANCH}.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for raphael!"
	tg_upload "MarisaKernel-raphael-$middlever-$date-${DRONE_COMMIT_BRANCH}.zip"
	cd $source
}

tg_notify "LOG: START BUILDING!"
cd /drone/src
git submodule init
git submodule update


if [ -e arch/arm64/configs/cepheus_defconfig ] ; then
	wget ${PATCHFILE}
	git apply ${PATCHNAME}
    	buildCepheus
fi

cd /drone/src/

if [ -e arch/arm64/configs/raphael_defconfig ] ; then
    buildRaphael
fi
log "Build finished for #${DRONE_BUILD_NUMBER} ( ${date} )."
