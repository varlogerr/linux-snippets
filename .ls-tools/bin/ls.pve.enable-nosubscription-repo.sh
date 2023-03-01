#!/usr/bin/env bash

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

pve_enable_nosubscription_repo() {
  local dest_file=/etc/apt/sources.list.d/pve-no-subscription.list

  local codename
  local repo
  codename="$(
    set -o pipefail
    grep VERSION_CODENAME /etc/os-release | cut -d= -f2
  )" || {
    trap_fatal 1 "Can't detect version codename"
  }
  repo="deb http://download.proxmox.com/debian/pve ${codename} pve-no-subscription"

  (set -x; echo "${repo}" | tee "${dest_file}" &>/dev/null) || {
    trap_fatal 1 "Can't enable nosubscription repo"
  }
}

pve_enable_nosubscription_repo
