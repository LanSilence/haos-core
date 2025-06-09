#!/bin/bash
set -e

TARGET_DIR=${1:-"/rk3399-custom"}
# 定义 patch 路径
LINUX_PATCH_DIR=${TARGET_DIR}/patch/linux
UBOOT_PATCH_DIR=${TARGET_DIR}/patch/u-boot
LINUX_SOURCE_DIR=linux/linux-${LINUX_VERSION:-6.12}
UBOOT_SOURCE_DIR=u-boot/u-boot-${UBOOT_VERSION:-2025.01}

TARGET_CONFIG=${1:-"rk3399-custom"}/config.mk
# 读取 config 文件

if [ -f "$TARGET_CONFIG" ]; then
    source "$TARGET_CONFIG"
else
    echo "警告: 未找到配置文件 $TARGET_CONFIG"
fi

# 进入 linux 源码目录并打 patch
if [ -d ${LINUX_SOURCE_DIR} ] && [ -d $LINUX_PATCH_DIR ]; then
    cd ${LINUX_SOURCE_DIR}
    for patch in $LINUX_PATCH_DIR/*.patch; do
        [ -e "$patch" ] || continue
        echo "Applying $patch to linux..."
        if patch -N -p1 < "$patch"; then
            echo "成功: $patch"
        else
            echo "错误: 打补丁 $patch 失败！"
        fi
    done
    cd - >/dev/null
else
    echo "警告: 未找到 Linux 源码目录 ${LINUX_SOURCE_DIR} 或补丁目录 $LINUX_PATCH_DIR"
fi

# 进入 u-boot 源码目录并打 patch
if [ -d ${UBOOT_SOURCE_DIR} ] && [ -d $UBOOT_PATCH_DIR ]; then
    cd  ${UBOOT_SOURCE_DIR}
    for patch in $UBOOT_PATCH_DIR/*.patch; do
        [ -e "$patch" ] || continue
        echo "Applying $patch to u-boot..."
        if patch -N -p1 < "$patch"; then
            echo "成功: $patch"
        else
            echo "错误: 打补丁 $patch 失败！"
        fi
    done
    cd - >/dev/null
else
    echo "警告: 未找到 U-Boot 源码目录 ${UBOOT_SOURCE_DIR} 或补丁目录 $UBOOT_PATCH_DIR"
fi

echo "All patches applied."
