#! /bin/sh

IP=192.168.10.10

executeAsRoot() {
    echo "$1"
    echo "sscl" | sshpass -p 'sscl' ssh -o StrictHostKeyChecking=no sscl@$IP "sudo -S /bin/bash -c '$2'" &> /dev/null
    return $?
}

echo "Back to Windows!"
rm /root/.ssh/known_hosts &> /dev/null
executeAsRoot "Mounting ..." "mount /dev/sda2 /mnt" || { echo "Can't mount! Aborting ..."; exit 1; }
executeAsRoot "Removing ..." "rm /mnt/nonlinear/linux" || { echo "Can't remove! Aborting ..."; exit 1; }
executeAsRoot "Touching ..." "touch /mnt/nonlinear/win" || { echo "Can't touch! Aborting ..."; exit 1; }
executeAsRoot "Unmouting ..." "umount /dev/sda2" || { echo "Can't unmount! Aborting ..."; exit 1; }
executeAsRoot "Rebooting ..." "reboot"

exit 0
