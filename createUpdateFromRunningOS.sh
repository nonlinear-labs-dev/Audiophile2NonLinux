#!/bin/sh

check_preconditions() {
    echo "Checking preconditions..."
    NUM_SDA_PARTITIONS=`fdisk -l /dev/sda | grep "sda[0-9]" | wc -l`
    if [ $NUM_SDA_PARTITIONS -eq "4" ]; then
        echo "Checking preconditions done."
        return 0
    fi
    echo "Checking preconditions failed."
    return 1
}

set_up() {
    echo "Setting up..."
    mkdir -p /mnt/NonLinux
    mount /dev/sda2 /mnt/NonLinux

    mkdir -p /mnt/update
    mount /dev/sda3 /mnt/update
        
    mkdir -p /mnt/update/update
    echo "Setting up done."
    return 0
}

copy_running_os() {
    echo "Copying running os..."
    if rsync -a --links --delete /mnt/NonLinux /mnt/update/update; then
        echo "Copying running os done."
        return 0
    fi
    echo "Copying running os failed."
    return 1
}

compress_copy() {
    echo "Compressing copy..."
    if (cd /mnt/update/update/ && tar -czf ./NonLinux.tar.gz ./NonLinux); then
        echo "Compressing copy done."
        return 0
    fi
    echo "Compressing copy failed."
    return 1
}

cleanup_copy() {
    echo "Clean up copy..."
    if rm -rf /mnt/update/update/NonLinux; then 
        echo "Clean up copy done."
        return 0
    fi
    echo "Clean up copy failed."
    return 1
}

calc_checksum() {
    echo "Calc checksum..."
    if (cd /mnt/update/update/ && touch $(sha256sum ./NonLinux.tar.gz | grep -o "^[^ ]*").sign); then 
        echo "Calc checksum done."
        return 0
    fi
    echo "Calc checksum failed."
    return 1
}

create_update_tar() {
    echo "Create update.tar..."
    if (cd /mnt/update/ && tar -cf ./update.tar ./update); then 
        echo "Create update.tar done."
        return 0
    fi
    echo "Create update.tar failed."
    return 1
}

cleanup_staging() {
    echo "Clean up staging dir..."
    if rm -rf /mnt/update/update; then 
        echo "Clean up staging dir done."
        return 0
    fi
    echo "Clean up staging dir failed."
    return 1
}
 
create_update() {
    echo "Creating update..."

    if check_preconditions; then
        if set_up && copy_running_os && compress_copy && cleanup_copy && calc_checksum && create_update_tar && cleanup_staging; then
            echo "Created update done."
            return 0
        fi
    fi    

    echo "Creating update failed."
    return 1
}


create_update