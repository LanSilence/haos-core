#!/bin/bash
set -e

TOOLCHAIN_SOURCE=https://snapshots.linaro.org/gnu-toolchain/12.2-2022.10-1/aarch64-linux-gnu/gcc-linaro-12.2.1-2022.10-x86_64_aarch64-linux-gnu.tar.xz
TOOLCHAIN_CACHE=cache/toolchain.tar.xz

if [ ! -f cache/.toolchain ]; then
    wget -O ${TOOLCHAIN_CACHE} ${TOOLCHAIN_SOURCE} && touch cache/.toolchain
fi

if [ ! -d tool/toolchain ] || [ -z "$(ls -A tool/toolchain 2>/dev/null)" ]; then
    mkdir -p tool/toolchain
     tar -xJf ${TOOLCHAIN_CACHE} -C tool/toolchain/
fi