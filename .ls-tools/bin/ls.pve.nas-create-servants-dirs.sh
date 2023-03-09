#!/usr/bin/env bash

{ # SETTINGS
  declare -ar SERVANTS_DIRS=(
    /root/servants/conf/servant1
    /root/servants/data/servant1/ovpn
    /root/servants/data/servant1/wg
    /root/servants/conf/servant2
    /root/servants/data/servant2/ovpn
    /root/servants/data/servant2/wg
  )
  # ownership, in UID:GID format, likely to be 1000
  declare -ar OWNER_UID_GID="1000:1000"
}

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    text_decore "
      Create servants directories on NAS host machine
     .
      $(pve_ls_supported_versions)
    "
  }

  trap_help_opt "${@}" && { print_help; exit 0; }

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

create_servants_dirs() {
  (
    set -x \
    && mkdir -p "${SERVANTS_DIRS[@]}" \
    && chown "${OWNER_UID_GID}" "${SERVANTS_DIRS[@]}"
  ) || {
    trap_fatal 1 "Can't create directories"
  }
}

create_servants_dirs
