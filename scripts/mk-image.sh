#!/bin/bash
set -ex
VERSION=v1.0.0
BOOTSTATE_SIZE=8M
SYSTEM_SIZE=680M
KERNEL_SIZE=24M
OVERLAY_SIZE=100M
HASS_SIZE=1200M
DATA_SIZE=50M

OUTDIR=${3:-"output"}
IMAGEDIR=${3:-"output"}/images
BOARD_DIR=${1:-"rk3399-custom"}
TARGET_CONFIG=${1:-"rk3399-custom"}/config.mk
SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
# 读取 config 文件

if [ -f "$TARGET_CONFIG" ]; then
    source "$TARGET_CONFIG"
else
    echo "警告: 未找到配置文件 $TARGET_CONFIG"
fi

if [ ! -d "$IMAGEDIR" ]; then
    echo "Creating image directory: $IMAGEDIR"
    mkdir -p "$IMAGEDIR"
fi

if [ "${PARTITION_TYPE}" == "mbr" ]; then
    sudo mkdir -p "ubuntu/binary/usr/lib/udev/rules.d"
    sudo cp -f "./ubuntu/rootfs-diff/mbr-part.rules" "ubuntu/binary/usr/lib/udev/rules.d/"
fi

HACODE=${2:-".."}/homeassistant-core/core-${HASS_VERSION:-2025.5.3}

cd ubuntu

if [ ! -f .ubuntuimg ]; then
    ./mk-rootfs.sh 
    echo "Ubuntu image not found, creating..."
    TARGET=lite IMAGE_VERSION=24.02 ./mk-image.sh && touch .ubuntuimg
else
    echo "Ubuntu image already exists, skipping creation."
fi
if [ ! -f .homeassistantimg ]; then
    echo "Home Assistant image not found, creating..."
    sudo IMAGE_VERSION=24.02 ./mk-homeassistant.sh ${HACODE} && touch .homeassistantimg
else
    echo "Home Assistant image already exists, skipping creation."
fi

cp homeassistant.img "$IMAGEDIR"/homeassistant.img
cp ubuntu-24.02-rootfs.img "$IMAGEDIR"/system.img
cd -


HAOS_IMAGE_NAME=haos-${BOARD_ID}_${VERSION}-$(date +%Y%m%d).img
if [ -f "$IMAGEDIR/$HAOS_IMAGE_NAME" ]; then
    echo "HAOS image $HAOS_IMAGE_NAME already exists, skipping creation."
else
    echo "Creating HAOS image: $HAOS_IMAGE_NAME"
fi
rm -rf $HAOS_IMAGE_NAME
export BOOTSTATE_SIZE SYSTEM_SIZE KERNEL_SIZE OVERLAY_SIZE DATA_SIZE HASS_SIZE IMAGEDIR HAOS_IMAGE_NAME PARTITION_TYPE
# tool/genimage    \
# 	--tmppath "${OUTDIR}/tmp"    \
# 	--inputpath "${IMAGEDIR}"  \
# 	--outputpath "${IMAGEDIR}" \
# 	--config "genimage/images-os.cfg" \
#     --rootpath "${OUTDIR}/root" 

rm -rf ${OUTDIR}/tmp/*
tool/genimage --rootpath ${OUTDIR} \
    --tmppath "${OUTDIR}/tmp" \
    --inputpath "$IMAGEDIR" \
    --outputpath "$IMAGEDIR" \
    --includepath genimage:"$BOARD_DIR"\
    --config "genimage/genimage.cfg" 

rm $IMAGEDIR/homeassistant.img
export TARGET_CONFIG IMAGEDIR OUTDIR BOARD_ID
$SCRIPTS_DIR/mk-raucbundle.sh 