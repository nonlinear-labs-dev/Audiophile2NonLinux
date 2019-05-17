#!/bin/sh

if [ $(fdisk -l /dev/sda | wc -l) != "4" ]
 echo "/dev/sda is already partitioned - exit" && exit 1

curl "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/blob/master/sda.sfdisk" | sfdisk /dev/sda


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
