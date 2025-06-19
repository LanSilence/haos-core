#!/bin/bash
set -ex

#获取当前路径
SCRIPTS_DIR=$(dirname "$(readlink -f "$0")")
OUT_DIR=${SCRIPTS_DIR}/../out
TARGET_DIR=${SCRIPTS_DIR}/../ubuntu/binary


function prepare_rauc_signing() {
    local key="${OUT_DIR}/key.pem"
    local cert="${OUT_DIR}/cert.pem"

    if [ ! -f "${key}" ]; then
        echo "Generating a self-signed certificate for development"
        ${SCRIPTS_DIR}/generate-signing-key.sh "${cert}" "${key}"
    fi
}


function write_rauc_config() {
    mkdir -p "${TARGET_DIR}/etc/rauc"

    local ota_compatible
    ota_compatible="$(hassos_rauc_compatible)"

    export ota_compatible
    export BOOTLOADER PARTITION_TABLE_TYPE BOOT_SPL

    (
        "${HOST_DIR}/bin/tempio" \
            -template "${BR2_EXTERNAL_HASSOS_PATH}/ota/system.conf.gtpl"
    ) > "${TARGET_DIR}/etc/rauc/system.conf"
}


function install_rauc_certs() {
    local cert="${OUT_DIR}/cert.pem"

    # Add local self-signed certificate (if not trusted by the dev or release
    # certificate it is a self-signed certificate, dev-ca.pem contains both)
    if ! openssl verify -CAfile "${SCRIPTS_DIR}/../prebuild/ota/haos-ota-cert.pem" -no-CApath "${cert}"; then
        echo "Adding self-signed certificate to keyring."
        sudo mkdir -p "${TARGET_DIR}/etc/rauc"
        sudo openssl x509 -in "${cert}" -text | sudo tee "${TARGET_DIR}/etc/rauc/keyring.pem"
    fi
}

prepare_rauc_signing
install_rauc_certs
