#!/bin/bash
clang_path="${HOME}/proton-clang/bin/clang"
gcc_path="${HOME}/proton-clang/bin/aarch64-linux-gnu-"
gcc_32_path="${HOME}/proton-clang/bin/arm-linux-gnueabi-"

date="`date +"%m%d%H%M"`"
firstver="Marisa"
device1="kebab"
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
	export KBUILD_BUILD_USER="Kebab"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date} "
	make $args kebab_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for kebab!"
    fi
	mkzipKebab
	tg_notify "Finish building kebab!"
}

mkzipKebab(){
	mv -f ~/src/out/arch/arm64/boot/Image.gz ~/src/anykernel3
	mv -f ~/src/out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb ~/src/anykernel3/dtb
	cd ~/src/anykernel3
	zip -r "MarisaKernel-kebab-$middlever-$date.zip" *
	mv -f "MarisaKernel-kebab-$middlever-$date.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for kebab!"
	tg_upload "MarisaKernel-kebab-$middlever-$date.zip"
	cd $source
}

buildKebabaosp(){
	export KBUILD_BUILD_USER="Kebab"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date} "
	make $args kebab_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for kebab AOSP!"
    fi
	mkzipKebabaosp
	tg_notify "Finish building kebab AOSP!"
}

mkzipKebabaosp(){
	mv -f ~/src/out/arch/arm64/boot/Image.gz ~/src/anykernel3
	mv -f ~/src/out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb ~/src/anykernel3/dtb
	cd ~/src/anykernel3
	zip -r "MarisaKernel-kebab-$middlever-$date-AOSP.zip" *
	mv -f "MarisaKernel-kebab-$middlever-$date-AOSP.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for kebab AOSP!"
	tg_upload "MarisaKernel-kebab-$middlever-$date-AOSP.zip"
	cd $source
}


buildinstantnoodle(){
	export KBUILD_BUILD_USER="instantnoodle"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date} "
	make $args instantnoodle_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for instantnoodle!"
    fi
	mkzipinstantnoodle
	tg_notify "Finish building instantnoodle!"
}

mkzipinstantnoodle(){
	mv -f ~/src/out/arch/arm64/boot/Image.gz ~/src/anykernel3
	mv -f ~/src/out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb ~/src/anykernel3/dtb
	cd ~/src/anykernel3
	zip -r "MarisaKernel-instantnoodle-$middlever-$date.zip" *
	mv -f "MarisaKernel-instantnoodle-$middlever-$date.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for instantnoodle!"
	tg_upload "MarisaKernel-instantnoodle-$middlever-$date.zip"
	cd $source
}

buildinstantnoodlep(){
	export KBUILD_BUILD_USER="instantnoodle"
	export KBUILD_BUILD_HOST="MarisaKernel"
args+="LOCALVERSION=-${middlever}-${date} "
	make $args instantnoodlep_defconfig&&make $args
	if [ $? -ne 0 ]; then
    terminate "Error while building for instantnoodlep!"
    fi
	mkzipinstantnoodlep
	tg_notify "Finish building instantnoodlep!"
}

mkzipinstantnoodlep(){
	mv -f ~/src/out/arch/arm64/boot/Image.gz ~/src/anykernel3
	mv -f ~/src/out/arch/arm64/boot/dts/vendor/qcom/kona-v2.1.dtb ~/src/anykernel3/dtb
	cd ~/src/anykernel3
	zip -r "MarisaKernel-instantnoodlep-$middlever-$date.zip" *
	mv -f "MarisaKernel-instantnoodlep-$middlever-$date.zip" ${HOME}
	cd ${HOME}
	log "Finish making zip for instantnoodlep!"
	tg_upload "MarisaKernel-instantnoodlep-$middlever-$date.zip"
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
cd /drone/src
buildinstantnoodlep
cd /drone/src
git apply lineage.diff
buildkebabaosp

log "Build finished for #${DRONE_BUILD_NUMBER} ( ${date} )."
