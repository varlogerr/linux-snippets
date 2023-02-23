# <a id="top"></a> TOC

* [Pre-setup](#pre-setup)
  * [Install helper scripts](#pre-setup-install-helper-scripts)
---
* [Linux](linux/readme.md)
* [Proxmox](proxmox/readme.md)
---

## Pre-setup

### <a id="pre-setup-install-helper-scripts"></a> Install helper scripts

In most setup scenarios helper scripts are required. Installation:

```sh
(branch=master; bash <(
  dl_url=https://raw.githubusercontent.com/varlogerr/linux-snippets/${branch}/.ls-tools/install.sh
  curl -fsL -o - "${dl_url}" 2>/dev/null || wget -qO- "${dl_url}"
) "${branch}")
```

Change `branch` variable value (defaults to `master`) to download helper scripts from a different branch.

[To top]

[To top]: #top
