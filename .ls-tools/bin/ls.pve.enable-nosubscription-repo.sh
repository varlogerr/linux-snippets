#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir; curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir; libdir="$(realpath -- "${curdir}/../lib")"

  local f; for f in "${libdir}"/*.sh; do . "${f}"; done

  declare -a supported_pve=(7)
  pve_version_must_in "${supported_pve[@]}"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

pve_enable_nosubscription_repo() {
  local dest_file=/etc/apt/sources.list.d/pve-no-subscription.list

  local codename
  local repo
  codename="$(grep VERSION_CODENAME /etc/os-release | cut -d= -f2)"
  repo="deb http://download.proxmox.com/debian/pve ${codename} pve-no-subscription"

  (set -x; echo "${repo}" | tee "${dest_file}" &>/dev/null) || {
    trap_fatal 1 "Can't enable nosubscription repo"
  }
}

pve_enable_nosubscription_repo
