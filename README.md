# Audiophile2NonLinux
## How to create a NonLinux image file
* In a VM:
  * Download AP Linux ISO image: https://sourceforge.net/projects/ap-linux/
  * git clone this project
  * go into the checked out folder and call 
  ```console
  ./createNonLinuxImage.sh /home/user/Downloads-Folder-Containing/AP-Linux-V.4.0.iso /where/you/wish/the/new/img/AP-Linux-V.4.0.iso
  ```
  * Now, you can either copy the image onto a stick to boot a NUC from, or boot a virtual machine from the image.

## Install NonLinux
* have VirtualBox installed
  ```console
  ./run-me-on-vm-host.sh /where/you/wish/the/new/img/AP-Linux-V.4.0.iso
  ```
* On a NUC Machine
  * Copy the image /where/you/wish/the/new/img/AP-Linux-V.4.0.iso onto an USB stick
  * Connect monitor, keyboard and stick to the NUC
  * boot from stick (maybe you need to tweak the bios to do so)
  * After some minutes, your (virtual) machine should contain a NonLinux.

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
```console
sudo su
cd /
./buildNonlinearLabsBinaries.sh master
```

Please notice, the binaries and the build files will be gone on next boot.

## How to create an update from the currenlty running OS:
- call 
```console
/createUpdateFromRunningOS.sh
```
- copy the file /update.tar, for example via scp:
```console
scp /update.tar user@computer:
```
