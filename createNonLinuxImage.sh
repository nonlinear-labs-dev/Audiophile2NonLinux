#!/bin/bash

TIMESTAMP=`date +%m-%d-%Y-%H:%M:%S`
ISO_IN=$1
ISO_OUT=$2
STAGING_DIR=/tmp/NonLinux-repackaging-$TIMESTAMP

error() {
    echo $FUNCNAME
    echo "$1"
    clean_up
    exit
}

check_preconditions() {
    echo $FUNCNAME
    if [ -z $ISO_IN -o -z $ISO_OUT ]; then
        error "usage: $0 path-to-original-AP-Linux-V.4.0.iso path-to-NonLinux-AP-Linux-V.4.0.iso"
    fi

    if [ ! -f $ISO_IN ]; then
        error "Input ISO image does not exist."
    fi

    if ! which mksquashfs; then 
        error "Please install mksquashfs"
    fi

    if ! which md5sum; then 
        error "Please install md5sum"
    fi

    if ! which unsquashfs; then 
        error "Please install unsquashfs"
    fi

    echo "Creating ISO $ISO_OUT from $ISO_IN."
}

download_artifacts() {
    if [ ! -f ./NonLinux.pkg.tar.gz ]; then 
        wget https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/releases/download/1.0/NonLinux.pkg.tar.gz
    fi
}

mount_original() {
    echo $FUNCNAME
    mkdir -p $STAGING_DIR/original
    sudo mount ~/Downloads/AP-Linux-V.4.0.iso $STAGING_DIR/original -o loop,ro
}

create_copy() {
    echo $FUNCNAME
    rm -rf $STAGING_DIR/copy
    cp -a $STAGING_DIR/original $STAGING_DIR/copy
    (cd $STAGING_DIR; sudo unsquashfs $STAGING_DIR/copy/arch/x86_64/airootfs.sfs)
}

modify_copy() {
    echo $FUNCNAME
    sudo mkdir $STAGING_DIR/squashfs-root/Audiophile2NonLinux
    sudo chmod 777 $STAGING_DIR/squashfs-root/Audiophile2NonLinux
    cp -a ./hook ./install ./buildNonlinearLabsBinaries.sh ./NonLinux.pkg.tar.gz ./sda.sfdisk ./createUpdateFromRunningOS.sh $STAGING_DIR/squashfs-root/Audiophile2NonLinux
    sudo cp -a ./runme.sh $STAGING_DIR/squashfs-root/etc/profile.d/
}

create_iso() {
    echo $FUNCNAME
    rm $STAGING_DIR/copy/arch/x86_64/airootfs.sfs
    sudo mksquashfs $STAGING_DIR/squashfs-root $STAGING_DIR/copy/arch/x86_64/airootfs.sfs
    sudo rm -rf $STAGING_DIR/squashfs-root
    md5sum $STAGING_DIR/copy/arch/x86_64/airootfs.sfs > $STAGING_DIR/copy/arch/x86_64/airootfs.md5
    (cd $STAGING_DIR/copy; sudo genisoimage -l -r -J -V "ARCH_201704" -b isolinux/isolinux.bin -no-emul-boot -boot-load-size 4 -boot-info-table -c isolinux/boot.cat -o $ISO_OUT ./)
}

unmount_original() {
    echo $FUNCNAME
    if [ -d $STAGING_DIR/original ]; then
        sudo umount $STAGING_DIR/original
    fi
}

clean_up() {
    unmount_original
    # sudo rm -rf $STAGING_DIR
}

main() {
    echo $FUNCNAME
    check_preconditions
    download_artifacts
    mount_original
    create_copy
    modify_copy
    create_iso
    clean_up
}

main