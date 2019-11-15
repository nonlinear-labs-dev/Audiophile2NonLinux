#!/bin/sh

IP=192.168.10.10

executeAsRoot() {
    echo "$1"
    echo "sscl" | sshpass -p 'sscl' ssh -o StrictHostKeyChecking=no sscl@$IP "sudo -S /bin/bash -c '$1'"
    return $?
}


while true; do
	rm /root/.ssh/known_hosts &> /dev/null;
        if executeAsRoot "exit" &> /dev/null; then
            echo "got into NonLinux!"
            break
        fi
	sleep 1
done

rm /root/.ssh/known_hosts &> /dev/null
executeAsRoot "sfdisk --delete /dev/sda 4" || echo "Failed clean up! del_sda4"
executeAsRoot "sfdisk --delete /dev/sda 5" || echo "Failed clean up! del_sda5"
executeAsRoot "echo \";\" | sfdisk -a --no-reread /dev/sda" || echo "Failed clean up! mk_part"
executeAsRoot "echo \"y\" | mkfs.ext4 /dev/sda4" || "" "Failed clean up! mkfs"

executeAsRoot "reboot"

while true; do
        rm /root/.ssh/known_hosts &> /dev/null;
        if executeAsRoot "exit" &> /dev/null; then
            echo "got into NonLinux!"
            break
        fi
        sleep 1
done

executeAsRoot "lsblk" || "Failed to echo lsblk.."

exit 0
