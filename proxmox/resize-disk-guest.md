# Resize disk

## Host action

1. Web UI:
    * For VM (must be LVM): VM > Hardware > Hard Disk (XXX) > Disk Action > Resize 
    * For CT: CT > Resources > Root Disk > Volume Action > Resize 

## Ubuntu VM shell action (not required for CT)

1. Inspect free space available
    ```sh
    sudo fdisk -l
    ```
2. Extend physical drive
    ```sh
    # Disk '/dev/sda', volume number '3'
    sudo growpart /dev/sda 3
    ```
3. Update physical volume
    ```sh
    # View starting PV
    sudo pvdisplay
    # Instruct LVM that disk size has changed
    sudo pvresize /dev/sda3
    # Check new PV
    sudo pvdisplay
    ```
4. Extend logical volume
    ```sh
    # View starting LV
    sudo lvdisplay
    # Resize LV. '/dev/ubuntu-vg/ubuntu-lv' - LV Path (from lvdisplay)
    sudo lvextend -l +100%FREE /dev/ubuntu-vg/ubuntu-lv
    # View changed LV
    sudo lvdisplay
    ```
5. Resize filesystem
    ```sh
    sudo resize2fs /dev/ubuntu-vg/ubuntu-lv
    # Confirm results
    sudo fdisk -l
    ```
