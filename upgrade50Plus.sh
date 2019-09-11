#!/bin/bash

IP=$1

clear_displays() {
    if [ -e /nonlinear/text2soled/text2soled ]; then
        /nonlinear/text2soled/text2soled clear
    fi
}

boled() {
    if [ -e /nonlinear/text2soled/text2soled ]; then
        /nonlinear/text2soled/text2soled "$1" 0 36
    else
        echo "BOLED MESSAGE: $1"
    fi
}

soled() {
    if [ -e /nonlinear/text2soled/text2soled ]; then
        /nonlinear/text2soled/text2soled "$1" 0 84
    else
        echo "SOLED MESSAGE: $1"
    fi
}   

cout() {
    SOLED="$1"
    BOLED="$2"
    
    if [ -z "$BOLED" ]; then
        BOLED="$SOLED";
    fi

    if [ -z "$BOLED" ]; then
        return 1
    fi

    clear_displays
    boled "$BOLED"
    soled "$SOLED"
}

executeAsRoot() {
    echo "sscl" | sshpass -p 'sscl' ssh sscl@$IP "sudo -S /bin/bash -c '$1' 1>&2 > /dev/null"
    return $?
}

quit() {
    cout "$1"
    exit 1
}

print_scp_progress() {
    
    TARGET_SIZE="0"
    SOURCE_SIZE=$(ls -lah $2 | awk {'print $5'})

    executeAsRoot "touch $2"

    while [ ! "$TARGET_SIZE" = "$SOURCE_SIZE" ]; do
        TARGET_SIZE=$(sshpass -p 'sscl' ssh sscl@$IP "ls -lah $3 | awk {'print \$5'}")
        echo "todo: $SOURCE_SIZE bytes"
        echo "done: $TARGET_SIZE bytes"
        cout "$1" "copying $TARGET_SIZE/$SOURCE_SIZE"
        sleep 1
    done
}

print_dd_progress() {
    MSG=$1
    FILE=$2    
    touch $FILE
    while [ -e "$FILE" ]; do
        OUT=$(cat $FILE | tr '\r' '\n' | tail -n1 | grep -o "[0-9]* bytes")
        cout "$1" "dumping $OUT"
        sleep 1 
    done    
} 


check_preconditions() {
    cout "Checking preconditions..."
    [ -z "$IP" ] && quit "usage: $0 <IP-of-ePC>"
    ping -c1 $IP 1>&2 > /dev/null || quit "ePC is not reachable at $IP, update failed."
    executeAsRoot "sfdisk -d /dev/sda | grep sda5 | grep 42049536" || quit "ePC partition 5 is not expected position, update failed."
    executeAsRoot "sfdisk -d /dev/sda | grep sda5 | grep 20482422" || quit "ePC partition 5 is not of expected size, update failed."
    cout "Checking preconditions done."
}

tear_down_playground() {
    systemctl stop playground
    systemctl stop bbbb
    cout "Nonlinear Labs processes stopped."
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
    print_scp_progress "Copying partition 1 content..." ./p1.raw.gz /mnt/p1.raw.gz &
    sshpass -p 'sscl' scp ./p1.raw.gz sscl@$IP:/mnt || quit "Could not copy partition 1 content onto device. Update failed, device probably bricked."
    cout "Copying partition 2 content..." "Copying partition 2 content to temporary storage...."
    print_scp_progress "Copying partition 2 content..." ./p2.raw.gz /mnt/p2.raw.gz &
    sshpass -p 'sscl' scp ./p2.raw.gz sscl@$IP:/mnt || quit "Could not copy partition 2 content onto device. Update failed, device probably bricked."
    cout "Copying partitions content done."
}

dd_partitions() {
    print_dd_progress "Dumping partition 1 content..." /tmp/dd1.log &
    executeAsRoot "cat /mnt/p1.raw.gz | gzip -d - | dd of=/dev/sda1 bs=1M status=progress" > /tmp/dd1.log 2>&1  || quit "Could not dd partition 1. Update failed, device probably bricked."
    rm /tmp/dd1.log
    
    print_dd_progress "Dumping partition 2 content..." /tmp/dd2.log &
    executeAsRoot "cat /mnt/p2.raw.gz | gzip -d - | dd of=/dev/sda2 bs=1M status=progress" > /tmp/dd2.log 2>&1 || quit "Could not dd partition 2. Update failed, device probably bricked."
    rm /tmp/dd2.log

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
    print_scp_progress "Copying partition 3 content..." ./p3.raw.gz /mnt/p3.raw.gz &
    sshpass -p 'sscl' scp ./p3.raw.gz sscl@$IP:/mnt || quit "Could not copy partition 3 content onto device. Update failed, device probably bricked."
    cout "Copying partition 3 content done."
}

dd_partition_3() {
    print_dd_progress "Dumping partition 3 content..." /tmp/dd3.log &
    executeAsRoot "cat /mnt/p3.raw.gz | gzip -d - | dd of=/dev/sda3 bs=1M status=progress" > /tmp/dd3.log 2>&1 || quit "Could not dd partition 3. Update failed, device probably bricked."
    rm /tmp/dd3.log
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
    executeAsRoot "chroot /mnt mkinitcpio -p linux-rt" || quit "mkinitcpio failed. Update failed, device probably bricked."
    cout "Finalization done." 
}

reboot_device() {
    cout "Rebooting ePC..."

    executeAsRoot "reboot"
    
    sleep 5
    while ! ping -c1 $IP; do 
        sleep 1
    done
    
    cout "ePC has been successfully upgraded!"
}

start_playground() {
    systemctl start bbbb
    systemctl start playground
}

main() {
    check_preconditions
    tear_down_playground
    unmount_doomed
    create_partitions
    copy_partition_content
    dd_partitions
    unmount_tmp
    copy_partition_3_content
    dd_partition_3
    install_grub
    reboot_device
    start_playground
    exit 0;
}

main









