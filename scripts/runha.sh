#!/bin/bash 
set -e
ROOT_DIR=$(pwd)
UBUNTU_DIR=${ROOT_DIR}/ubuntu
finish() {
    set +e
    sudo unmount ${UBUNTU_DIR}/rootfs/home/haos
    sudo ${UBUNTU_DIR}/ch-mount.sh -u ${UBUNTU_DIR}/rootfs
    sudo umount ${UBUNTU_DIR}/rootfs/tmp
    sudo umount ${UBUNTU_DIR}/rootfs/homeassistant/
    sudo umount ${UBUNTU_DIR}/rootfs/mnt/data/
    sudo umount ${UBUNTU_DIR}/rootfs
    sudo umount ${UBUNTU_DIR}/rootfs
    rm -rf ${UBUNTU_DIR}/data.ext4
    echo "exit"
    exit 1
}
trap finish ERR EXIT
sudo mount -t erofs  -o loop ${UBUNTU_DIR}/ubuntu-24.02-rootfs.img ${UBUNTU_DIR}/rootfs
${UBUNTU_DIR}/ch-mount.sh -m ${UBUNTU_DIR}/rootfs
sudo mount -t tmpfs -o size=512M tmpfs ${UBUNTU_DIR}/rootfs/tmp
sudo mount ${UBUNTU_DIR}/homeassistant.img ${UBUNTU_DIR}/rootfs/homeassistant/
fallocate -l 500M ${UBUNTU_DIR}/data.ext4
mkfs.ext4 -L hassos-data ${UBUNTU_DIR}/data.ext4
sudo mount ${UBUNTU_DIR}/data.ext4 ${UBUNTU_DIR}/rootfs/mnt/data/
export http_proxy=http://192.168.31.126:7890
export https_proxy=http://192.168.31.126:7890
cat <<EOF | sudo chroot ${UBUNTU_DIR}/rootfs 
mkdir -p /mnt/data/.homeassistant
mkdir -p /mnt/data/home/haos
mount -o bind /mnt/data/home/haos /home/haos
chown -R haos:haos /mnt/data/home/haos
chown -R haos:haos /mnt/data/.homeassistant
sudo -i -u haos

cd /homeassistant
source venv/bin/activate
python3.13 -m homeassistant --config /mnt/data/.homeassistant


EOF