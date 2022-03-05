#!/bin/bash
clang_path="${HOME}/proton-clang/bin/clang"
gcc_path="${HOME}/proton-clang/bin/aarch64-linux-gnu-"
gcc_32_path="${HOME}/proton-clang/bin/arm-linux-gnueabi-"

KERNEL_DIR=$PWD
date="`date +"%Y%m%d%H%M"`"
DATE2=$(date +"%d.%m.%y")
firstver="Marisa"
middlever="r1"

args="-j128 O=out \
	ARCH=arm64 \
	SUBARCH=arm64 "

args+="CC=$clang_path \
	CLANG_TRIPLE=aarch64-linux-gnu- \
	CROSS_COMPILE=$gcc_path "

args+="CROSS_COMPILE_ARM32=$gcc_32_path "

DEVICES=(
    "lmi"
    "umi"
    "cmi"
    "cas"
    "apollo"
    "alioth"
    "thyme"
    "psyche"
)

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

tg_notify "LOG: START BUILDING!"
cd /drone/src
git submodule init
git submodule update

clean

for ELEMENT in ${DEVICES[@]}; do
    cd ${PWD}
    START=$(date2 +"%s")
   	export KBUILD_BUILD_USER=$ELEMENT
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date}"
	make $args ${ELEMENT}_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for ${ELEMENT}!"
    fi
    mv -f ${KERNEL_DIR}/out/arch/arm64/boot/Image ${KERNEL_DIR}/anykernel3
    mv -f ${KERNEL_DIR}/out/arch/arm64/boot/dtbo.img ${KERNEL_DIR}/anykernel3
	mv -f ${KERNEL_DIR}/out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb ${KERNEL_DIR}/anykernel3/dtb
	cd ${KERNEL_DIR}/anykernel3
	zip -r "MarisaKernel-${ELEMENT}-$middlever-$date.zip" *
	mv -f "MarisaKernel-${ELEMENT}-$middlever-$date.zip" ${PWD}
	cd ${PWD}
	log "Finish making zip for ${ELEMENT}!"
	tg_upload "MarisaKernel-${ELEMENT}-$middlever-$date.zip"
	cd $source
    END=$(date2 +"%s")
    DIFF=$((END - START))
    tg_notify "Finish building ${ELEMENT} in $((DIFF / 60)) minute(s) and $((DIFF % 60)) seconds for ${ELEMENT}!"
done

log "Build finished for #${DRONE_BUILD_NUMBER} ( ${date} )."
