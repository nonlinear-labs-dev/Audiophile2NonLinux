#!/bin/sh

echo "Starting transormation of AP Linux into Nonlinux:"

SSD_NAME=`lsblk -o RM,NAME | grep "^ 0" | grep -o "sd." | uniq`
SSD=/dev/${SSD_NAME}

fdisk -l ${SSD} | grep "${SSD}[0-9]"

if [ $? -eq 0 ]
then
 echo "${SSD} is already partitioned"
 echo "If you are sure to know what you're doing, please type: cfdisk ${SSD}"
 echo "Delete all partitions there manually, write the partition table and retry this skript."
 exit 1
fi
 
echo "Partitioning ${SSD}:"
curl -L "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/sda.sfdisk" | sfdisk ${SSD}
echo ";" | sfdisk -a ${SSD}

echo "Creating filesystems:"
mkfs.fat ${SSD}1
mkfs.ext4 ${SSD}2
mkfs.ext4 ${SSD}3
mkfs.ext4 ${SSD}4

echo "Mounting root and boot partitions:"
mount ${SSD}2 /mnt
mkdir -p /mnt/boot
mount ${SSD}1 /mnt/boot

echo "Tweak AP Linux:"
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/install/nlhook" -O /lib/initcpio/install/nlhook
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/install/oroot" -O /lib/initcpio/install/oroot
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/hook/nlhook" -O /lib/initcpio/hooks/nlhook
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/hook/oroot" -O /lib/initcpio/hooks/oroot
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/createUpdateFromRunningOS.sh" -O /createUpdateFromRunningOS.sh
wget "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/buildNonlinearLabsBinaries.sh" -O /buildNonlinearLabsBinaries.sh

chmod +x /createUpdateFromRunningOS.sh
chmod +x /buildNonlinearLabsBinaries.sh

sed -i 's/read.*username/username=sscl/' /etc/apl-files/runme.sh
sed -i 's/read.*password/password=sscl/' /etc/apl-files/runme.sh
sed -i 's/pacman -U/pacman --noconfirm -U/' /etc/apl-files/runme.sh
sed -i 's/Required DatabaseOptional/Never/' /etc/pacman.conf
sed -i 's/Server.*mettke/#/' /etc/pacman.d/mirrorlist
sed -i 's/GRUB_TIMEOUT=5/GRUB_TIMEOUT=1/' /etc/default/grub
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT.*$/GRUB_CMDLINE_LINUX_DEFAULT="quiet ip=192.168.10.10:::::eth0:none"/' /etc/default/grub
sed -i 's/^HOOKS=.*$/HOOKS=\"base udev oroot block filesystems autodetect modconf keyboard net nlhook\"/' /etc/mkinitcpio.conf
sed -i 's/^BINARIES=.*$/BINARIES=\"tar rsync gzip lsblk udevadm\"/' /etc/mkinitcpio.conf

echo "Copy initial system:"
cp -ax / /mnt

echo "Do APLinux stuff:"
arch-chroot /mnt /bin/bash -c "cd /etc/apl-files && ./runme.sh"

echo "Install grub:"
arch-chroot /mnt /bin/bash -c "grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck"
arch-chroot /mnt /bin/bash -c "grub-mkconfig -o /boot/grub/grub.cfg"

echo "Configure autologin:"
arch-chroot /mnt /bin/bash -c "cd /etc/apl-files && ./autologin.sh"

echo "Downloading NonLinux/Arch packages:"

arch-chroot /mnt /bin/bash -c "mkdir -p /update-packages"
arch-chroot /mnt /bin/bash -c "touch /update-packages/NonLinux.pkg.tar.gz"

DOWNLOAD_URLS="http://192.168.2.180:8000 http://192.168.0.2:8000 http://185.28.186.202:8000 https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/releases/download/1.0"

for DOWNLOAD_URL in ${DOWNLOAD_URLS}; do
    arch-chroot /mnt /bin/bash -c "if [ ! -s /update-packages/NonLinux.pkg.tar.gz ]; then wget --tries=1 --timeout=5 '${DOWNLOAD_URL}/NonLinux.pkg.tar.gz' -O /update-packages/NonLinux.pkg.tar.gz; fi"
done

arch-chroot /mnt /bin/bash -c "tar -C /update-packages -xzf /update-packages/NonLinux.pkg.tar.gz"
arch-chroot /mnt /bin/bash -c "echo 'Server = file:////update-packages/pkg/' > /etc/pacman.d/mirrorlist"

echo "Remove unnecessary packages:"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Sy"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Scc"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Rcs xorg gnome mesa freetype2 ffmpeg ffmpeg2.8 man-db man-pages"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Rcs b43-fwcutter bluez-libs geoip ipw2100-fw ipw2200-fw libjpeg-turbo"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Rcs tango-icon-theme xorg-xmessage xf86-input-evdev xf86-input-synaptics zd1211-firmware"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -S cpupower git networkmanager"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Rcs xorgproto xfsprogs cifs-utils emacs-nox lvm2 fuse2"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Su"
arch-chroot /mnt /bin/bash -c "pacman --noconfirm -Qdt"

echo "Generate fstab:"
genfstab -U /mnt >> /mnt/etc/fstab

echo "Configure cpupower:"
sed -i "s/#governor=.*$/governor='performance'/" /mnt/etc/default/cpupower
arch-chroot /mnt /bin/bash -c "systemctl enable cpupower"

# echo "Build Nonlinear Labs software:"
# arch-chroot /mnt /bin/bash -c "cd / && /buildNonlinearLabsBinaries.sh dsp_optimization"

echo "Remove some artifacts:"
truncate -s 0 /mnt/home/sscl/.zprofile
arch-chroot /mnt /bin/bash -c "rm -rf /usr/lib/modules/5.1.7-arch1-1-ARCH"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/lib/modules/extramodules-ARCH"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/lib/firmware/netronome"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/lib/firmware/liquidio"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/lib/firmware/amdgpu"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/lib/firmware/qed"
arch-chroot /mnt /bin/bash -c "cd /usr/share/locale && ls -1 | grep -v 'en_US' | xargs rm -rf {}"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/share/doc"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/share/info"
arch-chroot /mnt /bin/bash -c "rm -rf /usr/share/man"

arch-chroot /mnt /bin/bash -c "systemctl mask systemd-backlight@"
arch-chroot /mnt /bin/bash -c "systemctl mask systemd-random-seed"
arch-chroot /mnt /bin/bash -c "systemctl mask systemd-tmpfiles-setup"
arch-chroot /mnt /bin/bash -c "systemctl mask systemd-tmpfiles-clean"
arch-chroot /mnt /bin/bash -c "systemctl mask systemd-tmpfiles-setup-dev"

echo "Done."
