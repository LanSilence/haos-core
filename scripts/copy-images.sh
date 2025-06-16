#!/bin/bash
set -e


TARGET_CONFIG=${1:-"rk3399-custom"}/config.mk
# 读取 config 文件
if [ -f "$TARGET_CONFIG" ]; then
    source "$TARGET_CONFIG"
else
    echo "Warning: Configuration file $TARGET_CONFIG not found."
fi
OUTDIR=${2:-"output"}
IMAGEDIR=${OUTDIR}/images

mkdir -p "$IMAGEDIR"

# 假设 u-boot 产物在 u-boot 目录下，kernel 产物在 linux/arch/arm64/boot 下
UBOOT_IMG=${OUTDIR}/u-boot-${UBOOT_VERSION}/${UBOOT_BIN_IMG:-u-boot.img}
KERNEL_IMG=${OUTDIR}/linux-${LINUX_VERSION}/arch/arm64/boot/Image
DTB_FILE=${OUTDIR}/linux-${LINUX_VERSION}/arch/arm64/boot/dts/$DTB_NAME



# 拷贝 u-boot
if [ -f "$UBOOT_IMG" ]; then
    cp "$UBOOT_IMG" "$IMAGEDIR/"
    echo "Copied $UBOOT_IMG to $IMAGEDIR/"
fi

# 拷贝 kernel
if [ -f "$KERNEL_IMG" ]; then
    cp "$KERNEL_IMG" "$IMAGEDIR/"
    echo "Copied $KERNEL_IMG to $IMAGEDIR/"
else
    echo "Warning: Kernel image $KERNEL_IMG not found."
fi

# 拷贝 dtb 文件
if [ -f "$DTB_FILE" ]; then
    cp "$DTB_FILE" "$IMAGEDIR/" 2>/dev/null || true
    echo "Copied dtb files to $IMAGEDIR/"
else
    echo "Warning: Kernel DTB $DTB_FILE not found."
fi

echo "All images copied."
