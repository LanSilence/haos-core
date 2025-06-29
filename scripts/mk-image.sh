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
SYSTEM_VERSION=$(cat VERSION)

export OUTDIR IMAGEDIR BOARD_DIR TARGET_CONFIG SCRIPTS_DIR SYSTEM_VERSION
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

HACODE=${2:-".."}/source/homeassistant-core/core-${HASS_VERSION:-2025.5.3}

${SCRIPTS_DIR}/rauc.sh

# 设置版本号
sed -i "s/VERSION_ID=\".*\"/VERSION_ID=\"${SYSTEM_VERSION}\"/" ubuntu/rootfs-overlay/usr/lib/os-release
cd ubuntu
UBUNTU_SCRIPTS_DIR=$(pwd)/scripts
${UBUNTU_SCRIPTS_DIR}/build.sh ${HACODE}

cp homeassistant.img "$IMAGEDIR"/homeassistant.img
cp ubuntu-24.04-rootfs.img "$IMAGEDIR"/system.img
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

tar -czvf haos-${BOARD_ID}_${VERSION}-$(date +%Y%m%d).tar.gz ${OUTDIR}/HAOS_IMAGE_NAME
rm $IMAGEDIR/homeassistant.img
export TARGET_CONFIG IMAGEDIR OUTDIR BOARD_ID SYSTEM_VERSION
$SCRIPTS_DIR/mk-raucbundle.sh 
rm $IMAGEDIR/system.img
