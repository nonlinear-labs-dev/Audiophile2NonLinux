#! /bin/bash

IP=192.168.10.10
rm /root/.ssh/known_hosts

# check connection
ping -c1 $IP 1>&2 > /dev/null || { echo "Can't ping ePC ..."; exit 1; }
rm /root/.ssh/known_hosts 1>&2 > /dev/null
sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP "exit" 1>&2 > /dev/null || { echo "Can't login into Windows ..."; exit 1; }

# check ePC disk size
# SIZE_OUTPUt=$(sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@192.168.10.10 "echo list disk | diskpart")
# (echo $disk=Get-WmiObject Win32_DiskDrive; echo $disk.size) | powershell
# wmic diskdrive get size

DISK_SIZE=$(sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP "wmic diskdrive get size")
DISKSIZE=$(echo "$DISK_SIZE" | sed -n 2p)
DISKSIZE=${DISKSIZE//[ $'\001'-$'\037']} # remove possible DOS carriage return characters
DISKSIZE=$((DISKSIZE / 1073741824))

# switch from win to ubuntu
sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP "mountvol p: /s & p: & cd nonlinear & del win & echo hello > linux & shutdown -r -t 0 -f"

# wait till ePC rebooted into linux
# do we need timeouts? probably ...
# while true; do
#	rm /root/.ssh/known_hosts &> /dev/null;
#        if sshpass -p 'sscl' ssh -o StrictHostKeyChecking=no sscl@$IP "exit" 1>&2 > /dev/null; then
#                break
#        fi
#        sleep 1
# done

# wait till ePC rebooted into linux with 20 sec timer
for (( n=0; n<21 ; n++)); do
    rm /root/.ssh/known_hosts &> /dev/null;
    if sshpass -p 'sscl' ssh -o StrictHostKeyChecking=no sscl@$IP "exit" 1>&2 > /dev/null; then
            break
    fi
    sleep 1
    if [$n -eq 20]; then
        echo "Logging into Ubuntu ist taking to long! Ending Upgrade ..."
        exit 1
    fi
done

# run Henry's destruction script, depending on the size of the SSD
if [ $DISKSIZE -le 40 ]; then
    chmod +x ./upgrade50plus.sh
    ./upgrade50plus.sh $IP
elif [ $DISKSIZE -gt 40 ] && [ $DISKSIZE -le 70 ]
    # henry's script for 64gb
elif [ $DISKSIZE -gt 70 ] && [ $DISKSIZE -le 130 ]
    # henry's script for 120gb
else
    echo "SSD Size not supported for the Update ..."
    exit 1
fi

exit 0

