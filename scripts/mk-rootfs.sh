#!/bin/bash -e
set -ex
TARGET_ROOTFS_DIR="ubuntu/binary"
ROOT_DIR=$(pwd)/ubuntu
notinstall() {
    sudo mkdir -p ${ROOT_DIR}/binary/lib/firmware/{brcm,aic8800_sdio}
    sudo cp -r ${ROOT_DIR}/linux-firmware/brcm/* $TARGET_ROOTFS_DIR/lib/firmware/brcm/
    sudo cp -r ${ROOT_DIR}/linux-firmware/aic8800_sdio/* $TARGET_ROOTFS_DIR/lib/firmware/aic8800_sdio/
    sudo cp -rpf ${ROOT_DIR}/rootfs-overlay/* $TARGET_ROOTFS_DIR/
    ID=$(stat --format %u $TARGET_ROOTFS_DIR)

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

    # Fixup owners
    if [ "$ID" -ne 0 ]; then
        find / -user $ID -exec chown -h 0:0 {} \;
    fi
    for u in \$(ls /home/); do
        chown -h -R \$u:\$u /home/\$u
    done
EOF
    cd $ROOT_DIR
    ./mk-rootfs.sh
    echo -e "\033[47;31m not install \033[0m"
    exit 1
}

if [ $1 = "notinstall" ]; then
    notinstall
    exit 1
fi
mkdir -p $TARGET_ROOTFS_DIR
sudo cp /etc/resolv.conf $TARGET_ROOTFS_DIR/etc/resolv.conf
sudo cp -b /usr/bin/qemu-aarch64-static $TARGET_ROOTFS_DIR/usr/bin/
finish() {
    ./ch-mount.sh -u $TARGET_ROOTFS_DIR
    echo -e "error exit"
    exit -1
}
trap finish ERR
echo -e "\033[47;36m Change root.................... \033[0m"

./ch-mount.sh -m $TARGET_ROOTFS_DIR

cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/


export APT_INSTALL="apt-get install -fy --allow-downgrades"

export LC_ALL=C.UTF-8

apt-get -y update
apt-get -f -y upgrade
mkdir -p /var/cache/apt/archives/partial
apt install adduser
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime
chmod 1777 tmp  
adduser --system --no-create-home --group systemd-network
addgroup --system systemd-journal
useradd -r -s /usr/sbin/nologin messagebus
useradd -r -s /usr/sbin/nologin systemd-timesync
groupadd -r polkitd
useradd -r -g polkitd -d / -s /usr/sbin/nologin -c "Polkit Daemon" polkitd
echo "LC_ALL=zh_CN.UTF-8" >> /etc/default/locale
apt install -y vim net-tools iproute2 curl wget openssh-server
cd /bin && mv -f systemd-sysusers{,.org} && ln -s echo systemd-sysusers && cd -
apt install -y vim net-tools iproute2 curl wget openssh-server
apt install -y software-properties-common
add-apt-repository -y ppa:deadsnakes/ppa
\${APT_INSTALL} python3.13 python3.13-dev  python3.13-venv
python3.13 -m ensurepip
apt install -y udev    #一定要安装udev！！！不然进不去系统，血的教训

\${APT_INSTALL} network-manager systemd-timesyncd wpasupplicant wireless-tools systemd-resolved \
        libturbojpeg0-dev u-boot-tools fdisk jq aarch64-linux-gnu-gcc build-essential zlib-ng isal
sudo useradd -r -s /usr/sbin/nologin systemd-resolve
systemctl enable NetworkManager 
systemctl enable homeassistant 
systemctl enable systemd-timesyncd
apt install -y iputils-ping

apt install -y sudo
apt install -y kmod
apt install -y apt-utils
mkdir /mnt/{data,overlay,config,boot}

HOST=homeassistant

# Create User
useradd -G sudo -m -s /bin/bash haos
passwd haos <<IEOF
123456
123456
IEOF
passwd root <<IEOF
123456
123456
IEOF

# hostname
echo homeassistant > /etc/hostname

# set localtime
ln -sf /usr/share/zoneinfo/Asia/Shanghai /etc/localtime

systemctl mask wpa_supplicant-wired@
systemctl mask wpa_supplicant-nl80211@
systemctl mask wpa_supplicant@

apt-get clean
rm -rf /var/lib/apt/lists/*
rm -rf /var/lib/apt/lists/*
rm -rf /var/cache/
rm -rf /packages/
rm -rf /etc/update-motd.d/{10-help-text,60-unminimize}

sync

EOF
sudo mkdir -p binary/lib/firmware/{brcm,aic8800_sdio}
sudo cp -r linux-firmware/brcm/* $TARGET_ROOTFS_DIR/lib/firmware/brcm/
sudo cp -r linux-firmware/aic8800_sdio/* $TARGET_ROOTFS_DIR/lib/firmware/aic8800_sdio/
sudo cp -rpf rootfs-overlay/* $TARGET_ROOTFS_DIR/
cat <<EOF | sudo chroot $TARGET_ROOTFS_DIR/
mkdir /homeassistant
systemctl enable homeassistant 
systemctl enable hassos-overlay
systemctl enable hassos-image
systemctl enable home-haos.mount
rm -rf /lib/modules/6.12.0-haos+/build
rm -rf sbin.usr-is-merged bin.usr-is-merged lib.usr-is-merged
rm /root/.bash_history
EOF
./ch-mount.sh -u $TARGET_ROOTFS_DIR

ID=$(stat --format %u $TARGET_ROOTFS_DIR)

cat << EOF | sudo chroot $TARGET_ROOTFS_DIR

# Fixup owners
if [ "$ID" -ne 0 ]; then
    find / -user $ID -exec chown -h 0:0 {} \;
fi
for u in \$(ls /home/); do
    chown -h -R \$u:\$u /home/\$u
done
EOF

echo -e "\033[47;36m normal exit \033[0m"