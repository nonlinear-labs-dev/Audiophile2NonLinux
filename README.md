# Audiophile2NonLinux
How to turn Audiophile Linux into NonLinux

Download AP Linux ISO image: https://sourceforge.net/projects/ap-linux/
start VirtualBox
create a new virtual machine

"Create Virtual Machine"
- Type: Linux
- Version: Other Linux (64-bit)
- HardDisk: Create a virtual hard disk now
-> Press "Create"

"Create Virtual Hard Disk"
- File size: 64 GB
- Hard disk file type: VDI
- Storage on physical hard disk: Dynamically allocated
-> Press "Create"

Right click on new machine, chose "Settings"
Click "Storage"
Select Storage Devices / Controller: IDE / Empty
Click on the CD symbol and attach the downloaded file "AP-Linux-V.4.0.0.iso"

Start the VM
Select "Boot Arch Linux (x86_64)" in the boot menu
type:
- curl -L "https://github.com/nonlinear-labs-dev/Audiophile2NonLinux/raw/master/runme.sh" | sh
