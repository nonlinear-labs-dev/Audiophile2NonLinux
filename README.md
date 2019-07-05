# Audiophile2NonLinux
## How to turn Audiophile Linux into NonLinux
* In a VM:
  * Download AP Linux ISO image: https://sourceforge.net/projects/ap-linux/
  * have VirtualBox installed
  * git clone this project
  * go into the checked out folder and call 
  > `./run-me-on-vm-host.sh /home/user/Downloads-Folder-Containing-AP-Linux-V.4.0.iso`
* On a NUC Machine
  * Download AP Linux ISO image: https://sourceforge.net/projects/ap-linux/
  * Copy the image onto an USB stick
  * Connect monitor, keyboard, ethernet and stick to the NUC
  * boot from stick (maybe you need to tweak the bios to do so)
  * when booted, type: 
  > `curl -L "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/runme.sh" | sh`
  
After some minutes, your (virtual) machine should contain a NonLinux.

## How to create a flash image:
* open terminal
* navigate into ePC folder (mine is at ~/VirtualBox VMs/ePC/)
* type: vboxmanage clonehd --format RAW ./ePC-disk001.vmdk ./ePC.raw
* you may want to create an archive: tar -czf ./ePC.tar.gz ./ePC.raw
* and remove the raw file: rm ./ePC.raw

## How to flash the image:
* boot the NUC from any Linux-USB-Stick
* cat ePC.tar.gz | tar xzOf - | dd of=/dev/sda bs=1M status=progress

## How to build our binaries on a NonLinux installation
`
sudo su
cd /
./buildNonlinearLabsBinaries.sh master


## How to create an update from the currenlty running OS:
- call /createUpdateFromRunningOS.sh
- copy the file /mnt/update/update.tar
