#!/bin/bash

IP=192.168.2.87
PART="label: gpt
label-id: 7D22A5F5-C3A7-4C35-B879-B58C9B422919
device: /dev/sda
unit: sectors
first-lba: 2048

/dev/sda1 : start=        2048, size=     1048576, type=C12A7328-F81F-11D2-BA4B-00A0C93EC93B, uuid=37946461-1176-43E6-9F0F-5B98652B8AB9
/dev/sda2 : start=     1050624, size=    16777216, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=274A1E65-7546-4887-86DD-771BAC588588
/dev/sda3 : start=    17827840, size=    16777216, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=E30DE52F-B006-442E-9A4A-F332A9A0FF00
/dev/sda4 : start=    34605056, size=     7444480, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=22c47cae-cf10-11e9-b217-6b290f556266
/dev/sda5 : start=    42049536, size=    20482422, type=0FC63DAF-8483-4772-8E79-3D69D8477DE4, uuid=45c5a8ae-cf10-11e9-aefa-5f647edf4354"

executeAsRoot() {
    echo "sscl" | sshpass -p 'sscl' ssh sscl@$IP "sudo -S /bin/bash -c '$1'"    
    return $?
}

executeAsRoot "sfdisk -d /dev/sda"
executeAsRoot "sfdisk -d /dev/sda | grep sda5"

if ! executeAsRoot "sfdisk -d /dev/sda | grep sda5 | grep 42049536"; then
    echo "sda5 is not expected position"
    exit 1
fi

if ! executeAsRoot "sfdisk -d /dev/sda | grep sda5 | grep 20482422"; then
    echo "sda5 is not of expected size"
    exit 1
fi

executeAsRoot "umount /boot/efi"
executeAsRoot "umount /mnt"

executeAsRoot "echo \"$PART\" | sfdisk --no-reread /dev/sda"
executeAsRoot "partprobe"
executeAsRoot "mkfs.fat /dev/sda1"
executeAsRoot "mkfs.ext4 /dev/sda2"
executeAsRoot "mkfs.ext4 /dev/sda3"
executeAsRoot "mkfs.ext4 /dev/sda4"

executeAsRoot "mount /dev/sda3 /mnt"
executeAsRoot "chmod 777 /mnt"

sshpass -p 'sscl' scp ./p1.raw.gz sscl@$IP:/mnt
sshpass -p 'sscl' scp ./p2.raw.gz sscl@$IP:/mnt

executeAsRoot "cat /mnt/p1.raw.gz | gzip -d - | dd of=/dev/sda1 bs=1M status=progress"
executeAsRoot "cat /mnt/p2.raw.gz | gzip -d - | dd of=/dev/sda2 bs=1M status=progress"

executeAsRoot "umount /mnt"
executeAsRoot "chmod 777 /mnt"

sshpass -p 'sscl' scp ./p3.raw.gz sscl@$IP:/mnt

executeAsRoot "cat /mnt/p3.raw.gz | gzip -d - | dd of=/dev/sda3 bs=1M status=progress"

executeAsRoot "mount /dev/sda2 /mnt"
executeAsRoot "mount /dev/sda1 /mnt/boot/"
executeAsRoot "mount --rbind /dev /mnt/dev"
executeAsRoot "mount --rbind /sys /mnt/sys"
executeAsRoot "mount --rbind /proc /mnt/proc"
executeAsRoot "chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck"
executeAsRoot "chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg"

executeAsRoot "reboot"
