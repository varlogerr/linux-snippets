# <a id="top"></a> Proxmox init

* [Back](readme.md)
---
* [Fix locale](#fix-locale)
* [Install basic tools](#install-basic-tools)
* [Install more goodies](#install-basic-tools)
* [Install PVE helpers](#install-pve-helpers)
* [Join host logical volumes](#join-host-logical-volumes)
* [Configure storages](#configure-storages)
---

## Certificates

Place to `/etc/pve/nodes/pve1/pveproxy-ssl.{key,pem}` and
```sh
systemctl restart pveproxy
```

## Fix locale

[Reference article](https://www.thomas-krenn.com/en/wiki/Perl_warning_Setting_locale_failed_in_Debian)

```sh
# Generate missing locales if required.
# Substitute en_US with required one
locale-gen en_US.UTF-8
```

[To top]

## Install basic tools

```sh
apt update
apt install -y vim htop bash-completion tmux

# create default tmux configuration
mkdir -p /etc/tmux
echo '
  set-option -g prefix C-Space
  set-option -g allow-rename off
  set -g history-limit 100000
  set -g renumber-windows on
  set -g base-index 1
  set -g display-panes-time 3000
  setw -g pane-base-index 1
  setw -g aggressive-resize on
' | grep -v '^\s*$' | sed 's/^\s\+//' > /etc/tmux/default.conf
echo 'source-file /etc/tmux/default.conf' >> ~/.tmux.conf
```

[To top]

## Install PVE helpers

```sh
wget https://github.com/varlogerr/proxmox-tools/raw/master/proxmox/pve-tool-helper-install.sh
chmod +x ./pve-tool-helper-install.sh
./pve-tool-helper-install.sh
rm ./pve-tool-helper-install.sh

# generate, edit and execute post-install
pve-tool-post-install.sh --conf-gen ~/conf/pve-tool/pve.post-install.conf
vim ~/conf/pve-tool/pve.post-install.conf
pve-tool-post-install.sh ~/conf/pve-tool/pve.post-install.conf
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
