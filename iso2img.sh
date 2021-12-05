#!/bin/sh -ex

. ./DISTRO_SPECS

[ -f ../local-repositories/${DISTRO_TARGETARCH}/efilinux.efi ] || wget --tries=1 --timeout=10 -O ../local-repositories/${DISTRO_TARGETARCH}/efilinux.efi https://github.com/dpupos/efilinux/releases/latest/download/efilinux.efi

mkdir -p /mnt/iso
mount -o loop,ro $1 /mnt/iso

dd if=/dev/zero of=$2 bs=50M count=20 conv=sparse
parted --script $2 mklabel gpt
parted --script $2 mkpart "" fat32 1MiB 261MiB
parted --script $2 set 1 esp on
parted --script $2 mkpart "" ext4 261MiB 100%
LOOP=`losetup -Pf --show $2`
mkfs.fat -F 32 ${LOOP}p1
mkfs.ext4 -F -m 0 ${LOOP}p2

mkdir -p /mnt/uefiimagep1 /mnt/uefiimagep2

mount -o noatime ${LOOP}p1 /mnt/uefiimagep1
install -D -m 644 ../local-repositories/${DISTRO_TARGETARCH}/efilinux.efi /mnt/uefiimagep1/EFI/BOOT/BOOTX64.EFI
install -m 644 /mnt/iso/vmlinuz /mnt/uefiimagep1/EFI/BOOT/vmlinuz
install -m 644 /mnt/iso/initrd.gz /mnt/uefiimagep1/EFI/BOOT/initrd.gz
if [ -e /mnt/iso/ucode.cpio ]; then
	install -m 644 /mnt/iso/ucode.cpio /mnt/uefiimagep1/EFI/BOOT/ucode.cpio
	echo "-f 0:\EFI\BOOT\vmlinuz initrd=0:\EFI\BOOT\ucode.cpio initrd=0:\EFI\BOOT\initrd.gz" > /mnt/uefiimagep1/EFI/BOOT/efilinux.cfg
else
	echo "-f 0:\EFI\BOOT\vmlinuz initrd=0:\EFI\BOOT\initrd.gz" > /mnt/uefiimagep1/EFI/BOOT/efilinux.cfg
fi
umount /mnt/uefiimagep1 2>/dev/null

mount -o noatime ${LOOP}p2 /mnt/uefiimagep2
cp -a /mnt/iso/*.sfs /mnt/iso/*.txt /mnt/uefiimagep2/
umount /mnt/uefiimagep2 2>/dev/null
losetup -d ${LOOP}

umount /mnt/iso