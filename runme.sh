#!/bin/sh

echo "Starting transormation of AP Linux into Nonlinux:"

fdisk -l /dev/sda | grep "/dev/sda[0-9]"

if [ $? -eq 0 ]
then
 echo "/dev/sda is already partitioned - exit" && exit 1
fi
 
echo "Partitioning /dev/sda:"
curl -L "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/sda.sfdisk" | sfdisk /dev/sda

echo "Creating filesystems:"
mkfs.ext4 /dev/sda1
mkfs.ext4 /dev/sda2
mkfs.ext4 /dev/sda3
mkfs.ext4 /dev/sda4

echo "Mounting root and boot partitions:"
mount /dev/sda2 /mnt
mkdir -p /mnt/boot
mount /dev/sda1 /mnt/boot

echo "Copy initial system:"
cp -ax / /mnt

echo "Do APLinux stuff:"
arch-root /mnt /bin/bash -c "cd /etc/apl-files && ./runme.sh"

echo "Install grub:"
arch-root /mnt /bin/bash -c "grub-install --target=i386-pc /dev/sda"
arch-root /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

echo "Configure autologin:"
arch-root /mnt /bin/bash -c "cd /etc/apl-files && ./autologin.sh"

echo "Generate fstab:"
genfstab -U /mnt >> /mnt/etc/fstab

