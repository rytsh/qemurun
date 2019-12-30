#!/bin/bash
# Use this command to initialize qemu

function read_usb_port() {
    IFS=, read -a USB_HOST_B_P <<< "${1}"
    USB_HOST_BUS="${USB_HOST_B_P[0]}"
    USB_HOST_PORT="${USB_HOST_B_P[1]-1}"
}

function generate_qcow() {
    # $1 -> PATH
    # $2 -> DISK path iso, img..
    if [[ -n ${2} ]]; then
        disk_name="$(md5sum -b ${2} -z | cut -d ' ' -f1)"
        # disk_name="${2##*/}"
        # disk_name_ext="${2##*.}"
        # disk_name="${disk_name%.${disk_name_ext}}"
        QCOW_IMG="${1}/${disk_name}.qcow2"
    fi
    QCOW_IMG_DISK="${1}/disk.qcow2"

    # link to usb and create disk
    [[ ! -e "${1}" ]] && mkdir -p "${1}"
    [[ -n "${QCOW_IMG}" ]] && [[ ! -e "${QCOW_IMG}" ]] && qemu-img create -b "${2}" -f qcow2 "${QCOW_IMG}" && echo "Qcow2 link to img"
    [[ ! -e "${QCOW_IMG_DISK}" ]] && qemu-img create -f qcow2 "${QCOW_IMG_DISK}" "100G" && echo "Created disk qcow2"
}

function tmp_kill {
        if [[ -n ${TPM_PID} ]]; then
            # echo ${TPM_PID} kill
            kill ${TPM_PID}
        fi
    }

function tpm_init() {
    # $1 -> PATH
    trap tmp_kill EXIT
    # create software tpm
    swtpm socket --tpmstate dir="${1}" --tpm2 \
        --ctrl type=unixio,path="${1}/swtpm-sock" &
    TPM_PID=$!

    # wait to initialize swtpm command
    while [ ! -e "${1}/swtpm-sock" ]; do
        sleep 0.1
    done
}
