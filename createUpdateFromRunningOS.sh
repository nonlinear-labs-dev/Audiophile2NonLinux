#!/bin/sh

SSD_NAME=$(lsblk -o RM,NAME | grep "^ 0" | grep -o "sd." | uniq)
SSD=/dev/${SSD_NAME}

set_up() {
    echo "Setting up..."

    mkdir -p /nloverlay
    mount /dev/sda3 /nloverlay

    rm -rf  /nloverlay/update-scratch

    mkdir -p /nloverlay/update-scratch/update
    mkdir -p /nloverlay/runtime-overlay

    if [ `find /nloverlay/os-overlay | wc -l` -ne "1" ]; then
        echo "This system has been already updated (there is content in /nloverlay/os-overlay),"
        echo "so it is not suitable for performing this script."
        echo "Please run it on fresh installations only."
        return 1
    fi

    echo "Setting up done."
    return 0
}

copy_running_os() {
    echo "Copying running os..."
    if tar -C /nloverlay/runtime-overlay --exclude=./C15 --exclude=./build/CMakeFiles -czf /nloverlay/update-scratch/update/NonLinuxOverlay.tar.gz .; then
        echo "Copying running os done."
        return 0
    fi
    echo "Copying running os failed."
    return 1
}

calc_checksum() {
    echo "Calc checksum..."
    if (cd /nloverlay/update-scratch/update/ && touch $(sha256sum ./NonLinuxOverlay.tar.gz | grep -o "^[^ ]*").sign); then
        echo "Calc checksum done."
        return 0
    fi
    echo "Calc checksum failed."
    return 1
}

create_update_tar() {
    echo "Create update.tar..."
    if (cd /nloverlay/update-scratch/ && tar -cf /update.tar ./update); then
        echo "Create update.tar done."
        return 0
    fi
    echo "Create update.tar failed."
    return 1
}

cleanup_staging() {
    echo "Clean up staging dir..."
    if rm -rf /nloverlay/update-scratch/update; then
        echo "Clean up staging dir done."
        return 0
    fi
    echo "Clean up staging dir failed."
    return 1
}

create_update() {
    echo "Creating update..."

    if set_up && copy_running_os && calc_checksum && create_update_tar && cleanup_staging; then
        echo "Created update done."
        return 0
    fi

    echo "Creating update failed."
    return 1
}

create_update
