#!/bin/sh

check_preconditions() {
    echo "Checking preconditions..."
    AP="$1/AP-Linux-V.4.0.iso"

    if [ -f ${AP} ]; then
        echo "Checking preconditions done."
        return 0
    fi

    echo "${AP} not found."
    echo "usage: ./run-me-on-vm-host.sh path-to-folder-containing-AP-Linux-V.4.0.iso"
    echo "Checking preconditions failed."
    return 1
}

create_vm() {
    cat ./ePC.ova | sed -E "s/(.*)<Image(.*)location=\"(.*)\"/\1<Image\2location=\"${AP}\"/" > ePC-tweaked.ova
    VM_NAME=`vboxmanage import ./ePC-tweaked.ova | grep "Suggested VM name" | grep -o "\".*\"" | sed 's/"//g'`
    return $?
}

start_vm() {
    echo "Starting VM..."
    vboxmanage startvm ${VM_NAME}
}

choose_boot_option() {
    sleep 10
    vboxmanage controlvm ${VM_NAME} keyboardputscancode 1c 9c
}

start_script() {
    sleep 20
    vboxmanage controlvm ${VM_NAME} keyboardputstring 'curl -L "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/runme.sh" | sh'
    vboxmanage controlvm ${VM_NAME} keyboardputscancode 1c 9c
}

main() {
    if check_preconditions $1; then
        create_vm && start_vm && choose_boot_option && start_script
    fi
}


main $1