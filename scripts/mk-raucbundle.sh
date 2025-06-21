#!/bin/bash

# 计算文件哈希和大小
set -e
ROOT_DIR=$(pwd)
PREPARE_DIR=$ROOT_DIR/prebuild/ota
OTA_DIR=$OUTDIR/ota

mkdir -p $OTA_DIR
cp $IMAGEDIR/system.img $OTA_DIR/system.img
cp $IMAGEDIR/kernel.img $OTA_DIR/kernel.img


cp $PREPARE_DIR/template.raucm  $OTA_DIR/manifest.raucm


# 构建RAUC bundle（需要签名证书）
rm -rf $IMAGEDIR/$BOARD_ID-update-${VERSION}.raucb
rauc --cert=$OUTDIR/cert.pem \
  --key=$OUTDIR/key.pem \
  bundle \
  $OTA_DIR/ \
  $IMAGEDIR/$BOARD_ID-update-${VERSION}.raucb

rm -rf $OTA_DIR