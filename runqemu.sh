#!/bin/bash
#----------------------------
# Simple QEMU runner
#----------------------------

# path settings
PROJ_DIR=$(dirname "$0")
cd ${PROJ_DIR}

# import docker functions
DOCKER_IMAGE=${DOCKER_IMAGE:-runqemu:latest}

source ./misc/docker.sh
source ./misc/qemu.sh
source ./misc/qemu_settings.sh

function usage() {
    cat - <<EOF
QEMU runner
Usage: $0 <OPTIONS>

OPTIONS:
    -p, --profile
        Create/Select profile
    -i, --img
        Give an img disk
    --docker
        Run this commands in docker
    -h, --help
        This help page
EOF
}

ALL_ARGS=$(echo "$0 $@" | sed "s/--docker//g")

while [[ "$1" =~ ^- && ! "$1" == "--" ]]; do case $1 in
    -p | --profile)
        PROFILE="${2}"
        shift 1
        ;;
    -i | --img)
        IMG="${2}"
        shift 1
        ;;
    --docker)
        DOCKER="Y"
        ;;
    --sudo)
        PERMISSION="sudo"
        ;;
    -h | --help)
        usage
        exit 0
        ;;
    *)
        echo "Unknown option: $1"
        usage >&2
        exit 1
        ;;
esac; shift 1; done
if [[ "$1" == '--' ]]; then shift; fi

if [[ -z "${PROFILE}" ]]; then
    echo "You should give profile name!"
    exit 1
fi

if [[ "${DOCKER}" == "Y" ]]; then
    echo "Stating docker container"
    docker_pass
    echo "End docker container"
    exit 0
fi

# set profile folder
echo "Profile configuration"
PROFILE_FOLDER="${PROJ_DIR}/profile/${PROFILE}"
[[ ! -e "${PROFILE_FOLDER}" ]] && mkdir -p ${PROFILE_FOLDER}

generate_qcow "${PROFILE_FOLDER}" ${IMG}

q_net
q_gfx
# q_gfx_f
q_disk "${QCOW_IMG_DISK}"
# [[ -n "${IMG}" ]] && q_disk_usb "${QCOW_IMG}"
[[ -n "${IMG}" ]] && q_disk_cd "${QCOW_IMG}"
q_wdg
q_boot
q_bios "${PROJ_DIR}/bios/OVMF.fd"
# q_smb "/mnt/share"

#### RUN
# -cpu qemu64,${cpu_vars}
# -smp cpus=4,maccpus=4,cores=4,threads=1,sockets=1

set -x
${PERMISSION} qemu-system-x86_64  \
    -machine pc,accel=kvm:xen:tcg   \
    -cpu host                       \
    -m 4096                         \
    -enable-kvm                     \
    -nodefaults                     \
    ${bios_opts}                    \
    ${smb_opts}                     \
    ${net_opts}                     \
    ${gfx_opts}                     \
    ${disk_opts}                    \
    ${usb_opts}                     \
    ${cd_opts}                      \
    ${wdg_opts}                     \
    ${boot_opts}
result=${?}
set +x

exit ${result}
