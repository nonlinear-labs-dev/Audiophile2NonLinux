#!/bin/bash

ISO_FILE=$1
STICK=$2
TIMESTAMP=`date +%m-%d-%Y-%H:%M:%S`
MOUNTPOINT=$HOME/create-USB-stick-$TIMESTAMP

clean_up() {
    sudo umount $MOUNTPOINT/src
    sudo umount $MOUNTPOINT/tgt
    sudo rm -rf $MOUNTPOINT
    echo $1    
}

check_preconditions() {
    echo $FUNCNAME

    if [ -z $ISO_FILE ]; then
        clean_up "usage: $0 /path/to/NonLinux.iso /dev/sdX"
        exit 1
    fi

    if [ -z $STICK ]; then
        clean_up "usage: $0 /path/to/NonLinux.iso /dev/sdX"
        exit 1
    fi

    if [ ! -f $ISO_FILE ]; then
        clean_up "file $ISO_FILE does not exist."
        exit 1
    fi

    if [ ! -b $STICK ]; then
        clean_up "$STICK seems not to be block device file."
        exit 1
    fi

    if ! lsblk -l -p -o NAME,MOUNTPOINT,RM,TYPE | grep $STICK | grep "1 disk" >> /dev/null; then
        clean_up "$STICK seems not to be a removeable USB storage device."
        exit 1
    fi
}

partition_stick() {
    echo $FUNCNAME
    CMD="label: dos

label-id: 0x16ed9305
device: /dev/sde
unit: sectors

/dev/sde1 : start= 2048, size= 7687424, type=ef, bootable
"

    echo "$CMD" | sudo sfdisk $STICK 
    if ! sudo mkfs.msdos ${STICK}1; then
        echo "partitioning stick failed."
        clean_up 1
    fi
}

mount_iso() {
    echo $FUNCNAME
    mkdir -p $MOUNTPOINT/src
    LOOPDEVICE=$(sudo losetup -f --show -P $ISO_FILE)
    sudo mount ${LOOPDEVICE}p1 $MOUNTPOINT/src
}

mount_target() {
    mkdir -p $MOUNTPOINT/tgt
    sudo mount ${STICK}1 $MOUNTPOINT/tgt
}

copy_fs() {
    echo $FUNCNAME
    sudo cp -a $MOUNTPOINT/src/* $MOUNTPOINT/tgt/
    sync
}

main() {
    check_preconditions
    partition_stick
    mount_iso
    mount_target
    copy_fs
    clean_up "Success!"
}

main