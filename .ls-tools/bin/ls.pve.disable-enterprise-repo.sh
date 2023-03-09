#!/usr/bin/env bash

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    text_decore "
      Disable enterprice repository in PVE
     .
      $(pve_ls_supported_versions)
    "
  }

  trap_help_opt "${@}" && { print_help; exit 0; }

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

disable_enterprise_repo() {
  (
    set -x
    sed -i "s/^\s*deb/#deb/g" /etc/apt/sources.list.d/pve-enterprise.list &>/dev/null
  ) || trap_fatal 1 "Can't disable enterprise repo"
}

disable_enterprise_repo
