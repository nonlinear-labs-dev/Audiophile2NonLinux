#! /bin/bash

IP=192.168.10.10

rm /root/.ssh/known_hosts

# switch from win to ubuntu
sshpass -p 'TEST' ssh -o StrictHostKeyChecking=no TEST@$IP "mountvol p: /s & p: & cd nonlinear & del win & echo hello > linux & shutdown -r -t 0 -f"

# wait till ePC rebooted into linux
# do we need timeouts? probably ...
while true; do
	rm /root/.ssh/known_hosts &> /dev/null;
        if sshpass -p 'sscl' ssh -o StrictHostKeyChecking=no sscl@$IP "exit" &> /dev/null; then
                break
        fi
done

# run Henry's destruction script
chmod +x ./upgrade50plus.sh
./upgrade50plus.sh $IP

