#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir; curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir; libdir="$(realpath -- "${curdir}/../lib")"

  local f; for f in "${libdir}"/*.sh; do . "${f}"; done

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

disable_enterprise_repo() {
  (
    set -x
    sed -i "s/^\s*deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list &>/dev/null
  ) || trap_fatal 1 "Can't disable enterprise repo"
}

disable_enterprise_repo
