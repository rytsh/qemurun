# QEMU run with options

Example usage
```shell
./runqemu.sh -p win -i ~/Downloads/Win10_1909_English_x64.iso
```

After the installation run like this
```shell
./runqemu.sh -p win
```

## OVMF bios build

```shell
git clone --depth 1 git@github.com:tianocore/edk2.git
cd edk2
git submodule update --init
source ./edksetup.sh
make -C BaseTools/
build -p OvmfPkg/OvmfPkgIa32X64.dsc -t GCC5 -b RELEASE -a IA32 -a X64 -D SECURE_BOOT_ENABLE
```

check Build/Ovmf3264/RELEASE_GCC5/FV/OVMF*

