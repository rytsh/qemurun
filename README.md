# QEMU run with options

Running qemu with some helper scripts.

Before to run, please set settings in [runqemu.sh](./runqemu.sh) file.

Example usage
```shell
# run netboot
# if you need sudo permission try --sudo option
./runqemu.sh -p alpine
# run windows
./runqemu.sh -p win -i ~/Downloads/Win10_1909_English_x64.iso
```

After the installation run like this
```shell
./runqemu.sh -p win
```

Connect with a vncviewer to your qemu instance.

Check [TigerVNC](https://sourceforge.net/projects/tigervnc/).

Goto fs0: and run efi file.

```sh
fs0:
netboot.xyz.efi
```

If you want to use additional efi files add to the bootloader folder.

## Development

First we need an libraries installed environment so lets try to build the this container image:

```sh
docker build -t qemu-ovmf-bios-builder:latest - < build/edk2.Dockerfile
```

## Qemu build

You can get qemu in your package manager or you can build it yourself.

https://www.qemu.org/download/#linux

```sh
apt-get install qemu
```

## IPXE build

Check this contents:

https://github.com/rgl/raspberrypi-uefi-edk2-vagrant/blob/master/build-ipxe.sh  
https://ipxe.org/download  

Check for embed ipxe example:

https://github.com/rgl/raspberrypi-uefi-edk2-vagrant/blob/master/rpi.ipxe


```sh
git clone --recursive --depth=1 --branch=v1.21.1 https://github.com/ipxe/ipxe.git ipxe

cd ipxe
cat >src/config/local/general.h <<'EOF'
#define CERT_CMD                /* Certificate management commands */
#define DOWNLOAD_PROTO_HTTPS    /* Secure Hypertext Transfer Protocol */
#define DOWNLOAD_PROTO_TFTP     /* Trivial File Transfer Protocol */
#define IMAGE_TRUST_CMD         /* Image trust management commands */
#define NEIGHBOUR_CMD           /* Neighbour management commands */
#define NSLOOKUP_CMD            /* Name resolution command */
#define NTP_CMD                 /* Network time protocol commands */
#define PARAM_CMD               /* Form parameter commands */
#define PING_CMD                /* Ping command */
#define POWEROFF_CMD            /* Power off command */
#undef SANBOOT_PROTO_AOE        /* AoE protocol */
EOF

cd ..
```

```sh
docker run -it --rm --name qemu-ovmf-bios-builder -u $(id -u):$(id -g) -v $(pwd):/workspace qemu-ovmf-bios-builder:latest
```

Inside of container:

```sh
cd ipxe

NUM_CPUS=$((`getconf _NPROCESSORS_ONLN` + 2))
# NB sometimes, for some reason, when we change the settings at
#    src/config/local/*.h they will not always work unless we
#    build from scratch.
rm -rf src/bin*

time make -j $NUM_CPUS -C src bin-x86_64-efi/ipxe.efi
cp src/bin-x86_64-efi/ipxe.efi /workspace/efi/ipxe.efi
```

## OVMF bios build

You can directly download with your package manager.

First clone the edk2 repo:

```sh
git clone --depth 1 git@github.com:tianocore/edk2.git
cd edk2
git submodule update --init
cd ..
```

Add our builded ipxe.efi to the edk2 repo:

```sh

```

Now mount the root folder of repo to the container:

```sh
docker run -it --rm --name qemu-ovmf-bios-builder -u $(id -u):$(id -g) -v $(pwd):/workspace qemu-ovmf-bios-builder:latest
```

If you see any error connect as root user

```sh
docker exec -u 0 -it qemu-ovmf-bios-builder /bin/bash
```

Change logo in edk2/MdeModulePkg/Logo/Logo.bmp

Logo file should be this format, use imagemagick tool:

```sh
convert logo.png -depth 8 -type truecolor edk2/MdeModulePkg/Logo/Logo.bmp
```

```shell
cd edk2

export PYTHON_COMMAND=${EDK2_PYTHON_COMMAND:-python3}

# Source "edksetup.sh" carefully.
set +e +u +C
source ./edksetup.sh
ret=$?
set -e -u -C
if [ $ret -ne 0 ]; then
  exit $ret
fi

make -C BaseTools/
build -p OvmfPkg/OvmfPkgIa32X64.dsc -t GCC5 -b RELEASE -a IA32 -a X64 -D SECURE_BOOT_ENABLE
```

And your bios is ready

```sh
cp /workspace/edk2/Build/Ovmf3264/RELEASE_GCC5/FV/OVMF* /workspace/bios/
```

Check more details in here:

```
https://gitlab.com/qemu-project/qemu/-/blob/master/roms/edk2-build.sh
```
