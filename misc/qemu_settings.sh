#!/bin/bash
# qemu settings

function q_serial() {
    pts_dev=$(tty)
    pts_id=${pts_dev/#\/dev\//}
    pts_id=${pts_id/#pts\//pts}

    serial_opts="\
        -chardev tty,id=${pts_id},path=${pts_dev}   \
        -device isa-serial,chardev=${pts_id}        \
    "
}

function q_bios() {
    # $1 -> PATH of bios
    bios_opts="\
        -L /usr/share/qemu  \
        -bios ${1}          \
        "
}

function q_net() {
    #,hostfwd=tcp:8822-:22
    PROFILE_IN_NETWORK_X1P1=",net=10.0.1.0/24,dhcpstart=10.0.1.20,ipv4"
    # PROFILE_IN_NETWORK_X2P1=",restrict=y"

    net_opts="\
        -device pci-bridge,id=pci.01,chassis_nr=1,addr=06,shpc=off  \
        -netdev user,id=X1P1${PROFILE_IN_NETWORK_X1P1}              \
        -device e1000,netdev=X1P1,bus=pci.01,mac=00:11:22:33:44:AA  \
        "
}

function q_gfx() {
    gfx_opts="\
        -vnc :0 -k en-us -nographic -vga std   \
    "
}

function q_gfx_f() {
    gfx_opts="\
        -vga virtio   \
    "
}

function q_disk() {
    # $1 -> path main disk file
    disk_opts="\
        -drive if=none,id=diskM,file=${1},cache=unsafe  \
        -device ide-hd,drive=diskM,bootindex=1          \
        "
}

function q_disk_usb() {
    # $1 -> path of usb disk file
    [[ -z "${usb_opts}" ]] && usb_opts="-device usb-ehci,id=xhci"
    usb_opts="${usb_opts}   \
        -device usb-storage,id=usbdisk1,bus=xhci.0,drive=usbx,removable=on,bootindex=2  \
        -drive if=none,id=usbx,file=${1},cache=unsafe   \
        "
}

function q_disk_cd() {
    # $1 -> path of usb disk file
    cd_opts="${cd_opts}   \
        -device ide-cd,drive=cdx,bootindex=3  \
        -drive if=none,id=cdx,file=${1},cache=unsafe   \
        "
}

function q_usb_host() {
    # $1 -> usbhost
    # $2 -> usbport
    [[ -z "${usb_opts}" ]] && usb_opts="-device usb-ehci,id=xhci"
    usb_opts="${usb_opts}   \
        -device usb-host,hostbus=${1},hostport=${2} \
        "
}

function q_tmp() {
    tmp_opts="-chardev socket,id=chrtpm,path=${1}/swtpm-sock    \
    -tpmdev emulator,id=tpm0,chardev=chrtpm \
    -device tpm-tis,tpmdev=tpm0             \
    "
}

function q_wdg() {
    wdg_opts="\
        -watchdog i6300esb      \
        -watchdog-action none   \
        "
}

function q_boot() {
    boot_opts="\
        -boot menu=on,once=d    \
        "
}

function q_cpu_flag() {
    # $1 PRE_CPU_FLAGS
    # PRE_CPU_FLAGS="" # fill this line
    machine_flags="$(cat /proc/cpuinfo | grep '^flags *' | head --lines=1 | cut --delimeter=':' --fields=2 | sed 's/ *\(.*\) */\1/g') | sed 's/ /\n/g'"
    target_flags="$(echo ${1} | sed 's/ /\n/g')"
    common_flags="$(echo ${machine_flags} ${target_flags} | sort | uniq --repeated)"

    supported_cpu_flags="$(qemu-system-x86_64 -cpu help | grep 'CPUID flags' --after-context=1000 | tail --lines=+2 | tr ' ' '\n' | sed '/^$/d')"

    cpu_vars="$(echo ${common_flags} ${supported_cpu_flags} | sort | uniq --repeated | sed -e 's/^/+/' -e ':a' -e 'N;s/\n/,+/;ta')"
}

