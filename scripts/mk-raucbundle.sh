#!/bin/bash

# 计算文件哈希和大小
set -e
ROOT_DIR=$(pwd)
PREPARE_DIR=$ROOT_DIR/prebuild/ota
OTA_DIR=$OUTDIR/ota

mkdir -p $OTA_DIR
cp $IMAGEDIR/system.img $OTA_DIR/system.img
cp $IMAGEDIR/kernel.img $OTA_DIR/kernel.img
cp $IMAGEDIR/homeassistant.img $OTA_DIR/homeassistant.img
SYSTEM_SHA256=$(sha256sum $OTA_DIR/system.img | awk '{print $1}')
KERNEL_SHA256=$(sha256sum $OTA_DIR/kernel.img | awk '{print $1}')

echo "system.img SHA256: $SYSTEM_SHA256"
echo "kernel.img SHA256: $KERNEL_SHA256"
echo "system sha256: $SYSTEM_SHA256" > $OUTDIR/ota.sha256
echo "kernel sha256: $KERNEL_SHA256" >> $OUTDIR/ota.sha256

cp $PREPARE_DIR/template.raucm  $OTA_DIR/manifest.raucm
sed -i "s/\(version=\).*/\1${SYSTEM_VERSION}/" $OTA_DIR/manifest.raucm
cp $PREPARE_DIR/switch-slot.sh  $OTA_DIR/switch-slot.sh

# 构建RAUC bundle（需要签名证书）
rm -rf $IMAGEDIR/$BOARD_ID-update-${SYSTEM_VERSION}.raucb
rauc --cert=$OUTDIR/cert.pem \
  --key=$OUTDIR/key.pem \
  bundle \
  $OTA_DIR/ \
  $IMAGEDIR/$BOARD_ID-update-${SYSTEM_VERSION}.raucb

rm -rf $OTA_DIR