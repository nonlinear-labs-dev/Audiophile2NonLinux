#! /bin/sh

IP=192.168.10.10

executeAsRoot() {
    echo "$1"
    sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP "'$2'" &> /dev/null
    return $?
}


echo "Back to Linux!"
rm /root/.ssh/known_hosts &> /dev/null

sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP \
    "mountvol p: /s & p: & cd nonlinear & del win & echo hello > linux & shutdown -r -t 0 -f" &> /dev/null \
    || { echo "Can't switch to Linux! Aborting Upgrade ..."; exit 1; }

exit 0
