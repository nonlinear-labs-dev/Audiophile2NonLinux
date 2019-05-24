# Audiophile2NonLinux
How to turn Audiophile Linux into NonLinux

- Download AP Linux ISO image: https://sourceforge.net/projects/ap-linux/
- Download the virtual machine definition at https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/ePC.ova
- create a new virtual machine by importing ePC.ova
- Start the VM
- Select "Boot Arch Linux (x86_64)" in the boot menu
- type: curl -L "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/runme.sh" | sh
- Wait for the script to finish its work.

How to create a flash image:
- open terminal
- navigate into ePC folder (mine is at ~/VirtualBox VMs/ePC/)
- type: vboxmanage clonehd --format RAW ./ePC-disk001.vmdk ./ePC.raw
- you may want to create an archive: tar -czf ./ePC.tar.gz ./ePC.raw
- and remove the raw file: rm ./ePC.raw

How to flash the image:
- boot the NUC from any Linux-USB-Stick
- cat ePC.tar.gz | tar xzOf - | dd of=/dev/sda bs=1M status=progress

How to create an update from the currenlty running OS:
- call /createUpdateFromRunningOS.sh
- copy the file /mnt/update/update.tar
