#!/usr/bin/env bash

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    echo "Upgrade the system"
    exit 0
  }
  trap_help_opt "${@}" && print_help

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_ID_OR_LIKE[@]}"
  sys_must_root
}

pve_upgrade() {
  (
    set -x
    apt-get autoclean -y
    apt-get autoremove -y
    apt-get update
    apt-get dist-upgrade -y
  )
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
