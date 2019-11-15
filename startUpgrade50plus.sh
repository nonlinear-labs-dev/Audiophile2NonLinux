#! /bin/bash
# TODO:
# - more SOLED/BOLED outputs? or log files???

IP=192.168.10.10

echo "Preparing for Upgrade ..."

# check connection
rm /root/.ssh/known_hosts &> /dev/null
ping -c1 $IP &> /dev/null || { echo "Can't ping ePC! Aborting Upgrade ..."; exit 1; }
sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP "exit" &> /dev/null || { echo "Can't login into Windows! Aborting Upgrade ..."; exit 1; }

# check ePC disk size options
# SIZE_OUTPUt=$(sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@192.168.10.10 "echo list disk | diskpart")
# (echo $disk=Get-WmiObject Win32_DiskDrive; echo $disk.size) | powershell
# wmic diskdrive get size

# check ePC SSD size
SSD_SIZE=$(sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP "wmic diskdrive get size")
SSD_SIZE=$(echo "$SSD_SIZE" | sed -n 2p)
SSD_SIZE=${SSD_SIZE//[ $'\001'-$'\037']} # remove possible DOS carriage return characters
# SSD_SIZE=$((SSD_SIZE / 1073741824)) # to be mathimatically correct
SSD_SIZE=$((SSD_SIZE / 1000000000)) # keeping it simple

# switch from Windows to Ubuntu
sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP \
    "mountvol p: /s & p: & cd nonlinear & del win & echo hello > linux & shutdown -r -t 0 -f" &> /dev/null \
    || { echo "Can't switch to Ubuntu! Aborting Upgrade ..."; exit 1; }


# wait till ePC rebooted into linux with 20 sec timer
for (( n=1; n<21 ; n++)); do
    rm /root/.ssh/known_hosts &> /dev/null;
    if sshpass -p 'sscl' ssh -o StrictHostKeyChecking=no sscl@$IP "exit" &> /dev/null; then
        echo "Logged into Ubuntu successfully! Procceeding with the Upgrade ... "
        /bin/sh ./upgrade50Plus.sh $IP $SSD_SIZE
        break
    fi
    sleep 1
    if [ $n -eq 20 ]; then
        echo "Logging into Ubuntu ist taking way to long! Aborting Upgrade ..."
        exit 1
    fi
done

exit 0

