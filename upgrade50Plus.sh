#!/bin/bash

IP=$1

cout() {
    SOLED="$1"
    BOLED="$2"
    
    if [ -z "$BOLED" ]; then
        BOLED="$SOLED";
    fi

    if [ -z "$BOLED" ]; then
        return 1
    fi

    echo "SOLED MESSAGE: $SOLED"
    echo "BOLED MESSAGE: $BOLED"
}

executeAsRoot() {
    echo "sscl" | sshpass -p 'sscl' ssh sscl@$IP "sudo -S /bin/bash -c '$1' 1>&2 > /dev/null"
    return $?
}

quit() {
    echo "$1"
    exit 1
}

check_preconditions() {
    cout "Checking preconditions..."
    [ -z "$IP" ] && quit "usage: $0 <IP-of-ePC>"
    ping -c1 $IP 1>&2 > /dev/null || quit "ePC is not reachable at $IP, update failed."
    executeAsRoot "sfdisk -d /dev/sda | grep sda5 | grep 42049536" || quit "ePC partition 5 is not expected position, update failed."
    executeAsRoot "sfdisk -d /dev/sda | grep sda5 | grep 20482422" || quit "ePC partition 5 is not of expected size, update failed."
    cout "Checking preconditions done."
}

unmount_doomed() {
    cout "Unmounting partitions..."
    executeAsRoot "umount /boot/efi" || quit "unmounting efi partition failed, update failed."
    cout "Unmounting partitions done."
}

create_partitions() {
    cout "Creating partitions..."
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
    
    executeAsRoot "echo \"$PART\" | sfdisk --no-reread /dev/sda" || quit "Could not repartition the ePC SSD, update failed."
    executeAsRoot "partprobe" || quit "Could not re-read the SSD partition table. Update failed, device probably bricked."
    executeAsRoot "mkfs.fat /dev/sda1" || quit "Could not create partition 1. Update failed, device probably bricked."
    executeAsRoot "mkfs.ext4 /dev/sda2" || quit "Could not create partition 2. Update failed, device probably bricked."
    executeAsRoot "mkfs.ext4 /dev/sda3" || quit "Could not create partition 3. Update failed, device probably bricked."
    executeAsRoot "mkfs.ext4 /dev/sda4" || quit "Could not create partition 4. Update failed, device probably bricked."
    cout "Creating partitions done."
}

copy_partition_content() {
    cout "Copying partitions content..." "Mounting partition 3...."
    executeAsRoot "mount /dev/sda3 /mnt" || quit "Could not mount partition 3, update failed, device probably bricked."
    cout "Copying partitions content..." "Chmod partition 3...."
    executeAsRoot "chmod 777 /mnt" || quit "Could not chmod partition 3, update failed, device probably bricked."
    cout "Copying partition 1 content..." "Copying partition 1 content to temporary storage...."
    sshpass -p 'sscl' scp ./p1.raw.gz sscl@$IP:/mnt || quit "Could not copy partition 1 content onto device. Update failed, device probably bricked."
    cout "Copying partition 2 content..." "Copying partition 2 content to temporary storage...."
    sshpass -p 'sscl' scp ./p2.raw.gz sscl@$IP:/mnt || quit "Could not copy partition 2 content onto device. Update failed, device probably bricked."
    cout "Copying partitions content done."
}

dd_partitions() {
    cout "Dumping partition 1 content..." 
    executeAsRoot "cat /mnt/p1.raw.gz | gzip -d - | dd of=/dev/sda1 bs=1M status=progress"  || quit "Could not dd partition 1. Update failed, device probably bricked."
    cout "Dumping partition 2 content..." 
    executeAsRoot "cat /mnt/p2.raw.gz | gzip -d - | dd of=/dev/sda2 bs=1M status=progress"  || quit "Could not dd partition 2. Update failed, device probably bricked."
    cout "Dumping partitions content done." 
}

unmount_tmp() {
    cout "Unmounting temporary storage ..." 
    executeAsRoot "umount /mnt" || quit "Could not unmount temporary storage at /mnt. Update failed, device probably bricked."
    executeAsRoot "chmod 777 /mnt" || quit "Could not chmod /mnt. Update failed, device probably bricked."
    cout "Unmounting temporary storage done." 
}

copy_partition_3_content() {
    cout "Copying partition 3 content..." "Copying partition 3 content to temporary storage...."
    sshpass -p 'sscl' scp ./p3.raw.gz sscl@$IP:/mnt || quit "Could not copy partition 3 content onto device. Update failed, device probably bricked."
    cout "Copying partition 3 content done."
}

dd_partition_3() {
    cout "Dumping partition 3 content..." 
    executeAsRoot "cat /mnt/p3.raw.gz | gzip -d - | dd of=/dev/sda3 bs=1M status=progress" || quit "Could not dd partition 3. Update failed, device probably bricked."
    cout "Dumping partition 3 content done." 
}

install_grub() {
    cout "Finalization - unmounting ..." 
    executeAsRoot "mount /dev/sda2 /mnt" || quit "Could not mount partition 2 for installing grub. Update failed, device probably bricked."
    executeAsRoot "mount /dev/sda1 /mnt/boot/" || quit "Could not mount partition 1 for installing grub. Update failed, device probably bricked."
    executeAsRoot "mount --rbind /dev /mnt/dev" || quit "Could not mount /dev for installing grub. Update failed, device probably bricked."
    executeAsRoot "mount --rbind /sys /mnt/sys" || quit "Could not mount /sys for installing grub. Update failed, device probably bricked."
    executeAsRoot "mount --rbind /proc /mnt/proc" || quit "Could not mount /proc for installing grub. Update failed, device probably bricked."
    cout "Finalization - installing grub ..." 
    executeAsRoot "chroot /mnt grub-install --target=x86_64-efi --efi-directory=/boot --bootloader-id=arch_grub --recheck" || quit "grub-install failed. Update failed, device probably bricked."
    executeAsRoot "chroot /mnt grub-mkconfig -o /boot/grub/grub.cfg" || quit "grub-mkconfig failed. Update failed, device probably bricked."
    cout "Finalization done." 
}

reboot_device() {
    executeAsRoot "reboot"
}

main() {
    check_preconditions
    unmount_doomed
    create_partitions
    copy_partition_content
    dd_partitions
    unmount_tmp
    copy_partition_3_content
    dd_partition_3
    install_grub
    reboot_device

    cout "ePC has been successfully upgraded!"
    exit 0;
}

main









