#!/bin/bash
set -e
TARGET_CONFIG=${1:-"rk3399-custom"}/config.mk
# 读取 config 文件

if [ -f "$TARGET_CONFIG" ]; then
    source "$TARGET_CONFIG"
fi

LINUX_VERSION=${LINUX_VERSION:-6.12}
UBOOT_VERSION=${UBOOT_VERSION:-2025.01}
HASS_VERSION=${HASS_VERSION:-2025.5.3}

LINUX_SOURCE=https://github.com/torvalds/linux/archive/refs/tags/v${LINUX_VERSION}.tar.gz
LINUX_CACHE=cache/linux-v${LINUX_VERSION}
if [ ! -f cache/.linux ];then
    wget -O ${LINUX_CACHE} ${LINUX_SOURCE} && touch cache/.linux 
fi
if [ ! -d linux ] || [ -z "$(ls -A linux 2>/dev/null)" ]; then
    mkdir -p linux
    tar -xzf ${LINUX_CACHE} -C linux
fi

# 拉取 u-boot 源码
UBOOT_SOURCE=https://github.com/u-boot/u-boot/archive/refs/tags/v${UBOOT_VERSION}.tar.gz
UBOOT_CACHE=cache/uboot-v${UBOOT_VERSION}
if [ ! -f cache/.uboot ]; then
    wget -O ${UBOOT_CACHE} ${UBOOT_SOURCE} && touch cache/.uboot
fi
if [ ! -d u-boot ] || [ -z "$(ls -A u-boot 2>/dev/null)" ]; then
    mkdir -p u-boot
    tar -xzf ${UBOOT_CACHE} -C u-boot
fi

# 拉取 Home Assistant Core 源码
HASS_SOURCE=https://github.com/home-assistant/core/archive/refs/tags/${HASS_VERSION}.tar.gz
HASS_CACHE=cache/homeassistant-core-v${HASS_VERSION}
if [ ! -f cache/.hasscore ]; then
    wget -O ${HASS_CACHE} ${HASS_SOURCE} && touch cache/.hasscore
fi
if [ ! -d homeassistant-core ] || [ -z "$(ls -A homeassistant-core 2>/dev/null)" ]; then
    mkdir -p homeassistant-core
    tar -xzf ${HASS_CACHE} -C homeassistant-core
fi

# 解压并覆盖官方 translations（如有 translations.zip）
TRANSLATIONS_ZIP=prebuild/translations/translations5.3.zip
TRANSLATIONS_TAR=translations.tar.gz
TRANSLATIONS_DIR=homeassistant-core/core-${HASS_VERSION}/
if [ ! -f cache/.translations ] && [ -f $TRANSLATIONS_ZIP ]; then
    unzip -o $TRANSLATIONS_ZIP -d $TRANSLATIONS_DIR
    if [ -f ${TRANSLATIONS_DIR}/$TRANSLATIONS_TAR ]; then
        tar -xzf  ${TRANSLATIONS_DIR}/$TRANSLATIONS_TAR -C ${TRANSLATIONS_DIR} && touch cache/.translations
        rm -rf ${TRANSLATIONS_DIR}/$TRANSLATIONS_TAR
    fi
fi

UBUNTU_BASE=https://cdimage.ubuntu.com/ubuntu-base/releases/noble/release/ubuntu-base-24.04.2-base-arm64.tar.gz
UBUNTU_CACHE=cache/ubuntu-base
TARGET_ROOTFS_DIR=ubuntu/binary
if [ ! -f cache/.ubuntubase ]; then
    wget -O ${UBUNTU_CACHE} ${UBUNTU_BASE} && touch cache/.ubuntubase
fi
if [ ! -d ubuntu/binary ] || [ -z "$(ls -A ubuntu/binary 2>/dev/null)" ]; then
    mkdir -p ubuntu/binary
    sudo tar -xzf ${UBUNTU_CACHE} -C ubuntu/binary
    # sudo mkdir $TARGET_ROOTFS_DIR/lib/modules
    # sudo chmod 0666 $TARGET_ROOTFS_DIR/lib/modules
    sudo cp -b /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
    sudo cp -b /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
fi
