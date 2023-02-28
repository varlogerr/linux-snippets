# <a id="top"></a> Proxmox init

* [Back](readme.md)
---
* [Install helper scripts](#install-helper-scripts)
---
* [Fix Minisforum USB issue](#fix-minisforum-usb-issue)
---
* [Fix locale](#fix-locale)
* [Post-install](#post-install)
* [Upgrade (optional)](#upgrade)
* [Install tools (optional)](#install-tools)
---
* [Cergiticates](#certificates)
* [Join host logical volumes](#join-host-logical-volumes)
* [Configure storages](#configure-storages)
---

## Install helper scripts

See [Install helper scripts](../readme.md#pre-setup-install-helper-scripts)

[To top]

---

## Fix Minisforum USB issue

Fix AMD-based Minisforum machine USB issue. [The issue discussion](https://bbs.minisforum.com/threads/rear-usb-unstable-not-working.2130/), [the fix reference](https://bbs.minisforum.com/threads/the-iommu-issue-boot-and-usb-problems.2180/) (point 3 from the first post)

```sh
# Fix minisforum USB issue (if required)
~/ls-tools/bin/ls.pve.fix-minisforum-usb-issue.sh
```

[To top]

---

## Fix locale

```sh
~/ls-tools/bin/ls.pve.fix-locale.sh
```

Logout and login back.

[To top]

## Post-install

```sh
~/ls-tools/bin/ls.pve.disable-enterprise-repo.sh
~/ls-tools/bin/ls.pve.enable-nosubscription-repo.sh
~/ls-tools/bin/ls.pve.disable-subscription-nag.sh
```

[To top]

## <a id="upgrade"></a> Upgrade

```sh
~/ls-tools/bin/ls.linux.upgrade.sh
```

[To top]

## <a id="install-tools"></a> Install tools (optional)

See:
* [Basic tools (Linux)](../linux/tools.md#install-basic-tools)
* Goodies (Linux):
  * [fzf](../linux/tools.md#install-goodies-fzf)
  * [tmux](../linux/tools.md#install-goodies-tmux)

[To top]

---

## Certificates

Place to `/etc/pve/nodes/pve1/pveproxy-ssl.{key,pem}` and
```sh
systemctl restart pveproxy
```

[To top]

## Join host logical volumes

[Reference video](https://youtu.be/GYOlulPwxlE?list=PLk3oVaFzBUufFbrE4Y0gnQcjzfmEmT93o&t=372)


```sh
# reconfigure the storage
# UI: Datacenter -> Storage -> mark local-lve -> hit Remove, than execute:
lvremove /dev/pve/data
lvresize -l +100%FREE /dev/pve/root
resize2fs /dev/mapper/pve-root
# (optional) UI: back to Datacenter -> Storage -> mark local -> hit Edit
# and under Content choose types of content to store (for example all)
```

[To top]

## Configure storages

[Reference video](https://www.youtube.com/watch?v=Gy5iWpbZbDg)

See the reference video

[To top]

[To top]: #top
