#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir; curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir; libdir="$(realpath -- "${curdir}/../lib")"

  local f; for f in "${libdir}"/*.sh; do . "${f}"; done

  declare -a supported_pve=(7)
  pve_version_must_in "${supported_pve[@]}"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

pve_upgrade() {
  (set -x; apt-get update; apt-get dist-upgrade -y)
}

print_post_info() {
  log_info ""
  log_info '~~~~~~~~~~~~~~~~~~'
  log_info "Reboot recommended"
  log_info '~~~~~~~~~~~~~~~~~~'
  log_info ""
}

pve_upgrade
print_post_info
