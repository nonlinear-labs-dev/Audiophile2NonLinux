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

echo "Tweak AP Linux:"
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/install/nlhook" -O /lib/initcpio/install/nlhook
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/hook/nlhook" -O /lib/initcpio/hooks/nlhook

sed -i 's/read.*username/username=sscl/' /etc/apl-files/runme.sh
sed -i 's/read.*password/password=sscl/' /etc/apl-files/runme.sh
sed -i 's/pacman -U/pacman --noconfirm -U/' /etc/apl-files/runme.sh
sed -i 's/Required DatabaseOptional/Never/' /etc/pacman.conf
sed -i 's/Server.*mettke/#/' /etc/pacman.d/mirrorlist
sed -i 's/^HOOKS=.*$/HOOKS="base udev block filesystems autodetect modconf keyboard net nlhook"/' /etc/mkinitcpio.conf
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT.*$/GRUB_CMDLINE_LINUX_DEFAULT="quiet ip=192.168.10.10:::::eth0:none"/' /etc/default/grub

echo "Copy initial system:"
cp -ax / /mnt

echo "Do APLinux stuff:"
arch-chroot /mnt /bin/bash -c "cd /etc/apl-files && ./runme.sh"

echo "Install grub:"
arch-chroot /mnt /bin/bash -c "grub-install --target=i386-pc /dev/sda"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

echo "Configure autologin:"
arch-chroot /mnt /bin/bash -c "cd /etc/apl-files && ./autologin.sh"

echo "Remove unnecessary packages:"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Suy"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Rcs xorg gnome freetype2 ffmpeg ffmpeg2.8 man-db man-pages"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -S cpupower"

echo "Generate fstab:"
genfstab -U /mnt >> /mnt/etc/fstab

