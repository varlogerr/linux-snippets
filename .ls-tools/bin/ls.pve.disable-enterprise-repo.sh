#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/pve.sh"
  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  declare -a supported_pve=(7)
  pve_version_must_in "${supported_pve[@]}"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

disable_enterprise_repo() {
  (
    set -x
    sed -i "s/^\s*deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list &>/dev/null
  ) || trap_fatal 1 "Can't disable enterprise repo"
}

disable_enterprise_repo
