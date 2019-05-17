#!/bin/sh

echo "Starting transormation of AP Linux into Nonlinux..."

if [ fdisk -l /dev/sda | grep /dev/sda1 ]
then
 echo "/dev/sda is already partitioned - exit" && exit 1
fi
 
echo "Partitioning /dev/sda"
curl -L "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/sda.sfdisk" | sfdisk /dev/sda

echo "Done."

# mkfs.ext4 /dev/sdXX
# mount /dev/sdXX /mnt
# time cp -ax / /mnt
# arch-chroot /mnt /bin/bash
# cd /etc/apl-files
# ./runme.sh
# grub-install --target=i386-pc /dev/sdX 
# grub-mkconfig -o /boot/grub/grub.cfg
# passwd root
# ln -s /usr/share/zoneinfo/Europe/Dublin /etc/localtime
# hwclock --systohc --utc
# ./autologin.sh
# exit
# genfstab -U /mnt >> /mnt/etc/fstab
# reboot
