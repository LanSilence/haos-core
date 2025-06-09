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