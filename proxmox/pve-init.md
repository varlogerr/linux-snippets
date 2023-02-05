# <a id="top"></a> Proxmox init

* [Back](readme.md)
---
* [Fix locale](#fix-locale)
* [Post-install](#post-install)
* [Install tools (optional)](#install-tools)
* [Upgrade](#upgrade)
---
* [Fix Minisforum USB issue](#post-install)
* [Cergiticates](#certificates)
* [Join host logical volumes](#join-host-logical-volumes)
* [Configure storages](#configure-storages)
---

## Fix locale

[Reference article](https://serverfault.com/a/446048)

```sh
# View missing locale vars
locale
# Update missing variables
update-locale LANGUAGE=en_US.UTF-8 LC_ALL=en_US.UTF-8
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

## <a id="install-tools"></a> Install tools (optional)

See:
* [Basic tools (Linux)](../linux/basic-tools.md) 
* [Goodies (Linux)](../linux/goodies.md)

[To top]

## Upgrade

```sh
~/ls-tools/bin/ls.pve.upgrade.sh
```

[To top]

---

## Fix Minisforum USB issue

Fix AMD-based Minisforum machine USB issue ([issue reference](https://bbs.minisforum.com/threads/the-iommu-issue-boot-and-usb-problems.2180/))

```sh
# Fix minisforum USB issue (if required)
~/ls-tools/bin/ls.pve.fix-minisforum-usb-issue.sh
```

[To top]

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
