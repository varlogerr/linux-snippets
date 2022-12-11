# <a id="top"></a> NAS init

* [Back](readme.md)
---
* [Mount hard drives](#mount-hard-drives)
* [Setup containers](#setup-containers)
  * [Init1](#setup-containers-init1)
  * [Init2](#setup-containers-init2)
  * [Init3](#setup-containers-init3)
* [Devnotes](#devnotes)
  * [LXC Devmode](#devnotes-lxc-devmode)
---

## Mount hard drives

> **_NOTE:_**
>
> It's highly important to check directories structure on the hard drives before applying the section.  

```sh
DATA_DRIVE_UUID=593427d9-71a9-4b62-8fe1-c840087bf757
DATA_DRIVE_MP=/mnt/data1
BAK_DRIVE_UUID=1a64ebc9-17dc-4af2-9d92-9dafe3e42bcc
BAK_DRIVE_MP=/mnt/bak1

MOUNT_OPTS=noatime,nosuid,nodev,nofail,x-systemd.device-timeout=3s
echo "
  # data drive
  UUID=${DATA_DRIVE_UUID} ${DATA_DRIVE_MP} ext4 ${MOUNT_OPTS} 0 0
  # backup drive
  UUID=${BAK_DRIVE_UUID} ${BAK_DRIVE_MP} ext4 ${MOUNT_OPTS} 0 0
" | grep -v '^\s*$' | sed 's/^\s\+//' >> /etc/fstab

# create directories to mount to and mount
mkdir -p "${DATA_DRIVE_MP}" "${BAK_DRIVE_MP}"
mount -a
```

[To top]

## Setup containers

* `nas1.home`
* `servant1.home` - domestic services + pivpn-ovpn
* `servant2.home` - differences from `servant1.home`:
  * [pivpn-wg](https://docs.pivpn.io/wireguard/) instead of [pivpn-ovpn](https://docs.pivpn.io/openvpn/)
  * no [adguard](https://hub.docker.com/r/adguard/adguardhome) docker container

### <a id="setup-containers-init1"></a> Init1:
* Common settings:
  * @ubuntu
  * _start on boot_
  * _privileged_
  * Disk: skip replication
* Host specific
  * `nas1.home`: ID=110, Disk=15GB, Cores=4, Memory=4GB
  * `servant1.home`: ID=111, Disk=10GB, Cores=2, Memory=1GB
  * `servant2.home`: ID=112, Disk=10GB, Cores=2, Memory=1GB

[To top]

### <a id="setup-containers-init2"></a> Init2:

* Don't start the machines yet!
* ```sh
  # ensure directories to mount to container
  # and ownership, UID and GID are likely 1000
  mkdir -p \
    /root/servants/conf/servant{1,2} \
    /root/servants/data/servant{1,2}/{ovpn,wg}
  chown -R 1000:1000 \
    /root/servants/conf/servant{1,2} \
    /root/servants/data/servant{1,2}/{ovpn,wg}
  ```
* The hookscripts perform the following:
  * ensure the user
  * ensure the public key
  * mount directories on container `pre-start` and unmount on `pre-stop`, `post-stop`
  * add container configurations for vpn readyness, docker, user/group mappings

  > **NOTE 1**:
  >
  > Due to [PVE issue](https://bugzilla.proxmox.com/show_bug.cgi?id=1007) that doesn't allow making snapshots for CTs with bind mount, hookscripts will be used to bind mount and unmount directories.

  > **NOTE 2**:
  >
  > It's highly important to check directories structure on the hard drives before applying the section.  
  > Don't forget to change `PASS_PLACEHOLDER` placeholder!

  ```sh
  # Create passwords for users.
  # Hooks first check file `<MACHINE_ID>.pass` and if not found or empty tries `master.pass`.
  # If password file is not read for somw reason, passwordless user will be created.
  PASS=<PASS_PLACEHOLDER> # or `read -s PASS` if somebody is begind you shoulder
  mkdir -p /root/.toolset-conf/pve/secrets/homelab/pass
  find /root/.toolset-conf/pve/secrets -type d -exec chmod 0700 {} \;
  openssl passwd -5 "${PASS}" > /root/.toolset-conf/pve/secrets/homelab/pass/master.pass
  chmod 0600 /root/.toolset-conf/pve/secrets/homelab/pass/master.pass
  ```

  ```sh
  # install hooks
  branch=master
  tmpdir="$(mktemp -d)"
  wget -qO- https://github.com/varlogerr/linux-snippets/archive/refs/heads/${branch}.tar.gz | tar -xzf - -C "${tmpdir}"
  cp -r "${tmpdir}/linux-snippets-${branch}/proxmox/rootfs/root/.toolset" /root
  rm -rf "${tmpdir}"
  mkdir -p /var/lib/vz/snippets
  ln -fs /root/.toolset/pve/hook/nas1.sh /var/lib/vz/snippets/nas.sh
  ln -fs /root/.toolset/pve/hook/servants.sh /var/lib/vz/snippets/servants.sh
  # attach hooks
  pct set 110 --hookscript local:snippets/nas.sh
  pct set 111 --hookscript local:snippets/servants.sh
  pct set 112 --hookscript local:snippets/servants.sh
  ```
* > **NOTE**:
  >
  > Although `apparmor` is disabled by hookscript, for some reason it's not applied from the first run. So one start-stop loop is required before running the playbook.  
  > Don't forget to change `MACHINE_ID_PLACEHOLDER` placeholder!
  ```sh
  MACHINE_ID=<MACHINE_ID_PLACEHOLDER>
  pct start ${MACHINE_ID}
  lxc-attach ${MACHINE_ID} -- passwd bug1 # if not set with hookscript
  pct stop ${MACHINE_ID}
  ```

[To top]

### <a id="setup-containers-init3"></a> Init3:
* Start the machines `pct start <MACHINE_ID_PLACEHOLDER>`
* Run `servers` playbook
* If required restore VPN confs with:
  ```sh
  lxc-attach <MACHINE_ID_PLACEHOLDER> -- /usr/local/bin/pivpn-restore.sh <GUEST_PATH_TO_BAK_PLACEHOLDER>
  ```

[To top]

## Devnotes

### <a id="devnotes-lxc-devmode"></a> LXC Devmode

Development / testing in LXC containers doesn't require some features (for example mounts). To make hook aware of the machine devmode create an empty file `/root/.toolset-conf/pve/devmode/<MACHINE_ID>`. Example:
```sh
# Enable devmode for container #103
touch /root/.toolset-conf/pve/devmode/103
```

Remove the file to disable devmode

[To top]

[To top]: #top
