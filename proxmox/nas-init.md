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
~/ls-tools/bin/ls.pve.nas-mount-storages.sh
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
  # Ensure directories to mount to container
  # and ownership, UID and GID are likely 1000
  ~/ls-tools/bin/ls.pve.nas-create-servants-dirs.sh
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
  # If password file is not read for some reason, passwordless user will be created.
  PASS=<PASS_PLACEHOLDER> # or `read -s PASS` if somebody is begind you shoulder
  mkdir -p /root/.toolset-conf/pve/secrets/homelab/pass
  find /root/.toolset-conf/pve/secrets -type d -exec chmod 0700 {} \;
  openssl passwd -5 "${PASS}" > /root/.toolset-conf/pve/secrets/homelab/pass/master.pass
  chmod 0600 /root/.toolset-conf/pve/secrets/homelab/pass/master.pass
  ```

  ```sh
  # Install hooks from master branch.
  # Optionally pass branch name as an argument
  # to use an alternative branch.
  ~/ls-tools/bin/ls.pve.nas-install-hooks.sh
  # Attach hooks to containers.
  pct set 110 --hookscript local:snippets/nas.sh
  pct set 111 --hookscript local:snippets/servants.sh
  pct set 112 --hookscript local:snippets/servants.sh
  ```
* > **NOTE**:
  >
  > Although `apparmor` is disabled by hookscript, for some reason it's not applied from the first run. So one start-stop loop is required before running the playbook.  
  > Don't forget to change `MACHINE_ID_PLACEHOLDER` placeholder!
  ```sh
  # Loop over each machine
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

Development / testing in LXC containers doesn't always require mounts. To make hook aware of the machine devmode create an empty file `/root/.toolset-conf/pve/devmode/<MACHINE_ID>`. Example:
```sh
# Enable devmode for container #103
touch /root/.toolset-conf/pve/devmode/103
```

Remove the file to disable devmode.

[To top]

[To top]: #top
