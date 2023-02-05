#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

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