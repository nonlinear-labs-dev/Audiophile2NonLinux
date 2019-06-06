#!/bin/sh

check_preconditions() {
    echo "Checking preconditions..."
    if [ -z "$1" ]; then
        echo "Checking preconditions failed - please provide branch to build as command line argument."
        return 1
    fi
    echo "Checking preconditions done."
    return 0
}

callChecked() {
    echo "$1..."
    if sh -c "$2"; then
        echo "$1 done."
        return 0
    fi
    echo "$1 failed."
    return 1
}

set_up() {
    callChecked "Setting up environment" "pacman --noconfirm -S cmake make gcc glibmm pkgconf"
    return $?
}

check_out() {
    callChecked "Checking out project" "git clone https://github.com/nonlinear-labs-dev/C15.git && cd C15 && git checkout $1"
    return $?
}

build() {
    callChecked "Building project" "mkdir build && cd build && cmake -D CMAKE_BUILD_TYPE=Release ../C15/audio-engine && make install"
    return $?
}

main() {
    if check_preconditions $1 && set_up && check_out $1 && build; then 
        return 0
    fi
    return 1
}

main $1

