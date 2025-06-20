#!/bin/bash
# shellcheck disable=SC2155
set -ex
BOARD_DIR="$(dirname "$(readlink -f "$0")")"

OUTDIR=${2:-"output"}
IMAGEDIR=${OUTDIR}/images

BOARD_CONFIG=${BOARD_DIR}/config.mk
if [ -f "$BOARD_CONFIG" ]; then
    source "$BOARD_CONFIG"
else
    echo "警告: 未找到配置文件 $BOARD_CONFIG"
fi

gen_bootloader_img() {
    dd if="${IMAGEDIR}/idbloader.img" of="${IMAGEDIR}/bootloader.img" seek=64 conv=fsync
    dd if="${IMAGEDIR}/u-boot.img" of="${IMAGEDIR}/bootloader.img" seek=16384 conv=fsync
    dd if="${IMAGEDIR}/trust.img" of="${IMAGEDIR}/bootloader.img" seek=24576 conv=fsync
}

function hassos_pre_image() {

    cp "${BOARD_DIR}/boot-env.txt" "${IMAGEDIR}/haos-config.txt"
    cp "${BOARD_DIR}/cmdline.txt" "${IMAGEDIR}/cmdline.txt"
    mkimage -C none -A arm -T script -d ${BOARD_DIR}/uboot-boot.ush ${IMAGEDIR}/boot.scr  
    cp ${OUTDIR}/u-boot-${UBOOT_VERSION}/u-boot-sunxi-with-spl.bin ${IMAGEDIR}/u-boot-sunxi-with-spl.bin 
    tool/genimage    \
	--tmppath "${OUTDIR}/tmp"    \
	--inputpath "${IMAGEDIR}"  \
	--outputpath "${IMAGEDIR}" \
	--config "${BOARD_DIR}/bootloader-image.cfg" \
    --rootpath "${OUTDIR}/root" 
    # gen_bootloader_img

    KERNEL_IMAGE=${OUTDIR}/linux-${LINUX_VERSION}/arch/arm64/boot/Image.gz
    DTB_FILE=${OUTDIR}/linux-${LINUX_VERSION}/arch/arm64/boot/dts/$DTB_NAME
    export KERNEL_IMAGE DTB_FILE
    envsubst  < ${BOARD_DIR}/fit-image.its.pre > ${OUTDIR}/images/fit-image.its
    mkimage -f ${IMAGEDIR}/fit-image.its ${IMAGEDIR}/fit-Image.itb
}

mkdir -p "${IMAGEDIR}"
mkdir -p "${OUTDIR}/root"
hassos_pre_image
rm -rf "${OUTDIR}/root"
echo "Bootloader images generated in ${IMAGEDIR}"

