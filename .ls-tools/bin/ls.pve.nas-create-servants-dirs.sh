#!/usr/bin/env bash

# SETTINGS START
  declare -a SERVANTS_DIRS=(
    /root/servants/conf/servant1
    /root/servants/data/servant1/ovpn
    /root/servants/data/servant1/wg
    /root/servants/conf/servant2
    /root/servants/data/servant2/ovpn
    /root/servants/data/servant2/wg
  )
  # ownership, in UID:GID format, likely to be 1000
  OWNER_UID_GID="1000:1000"
# SETTINGS END

__bootstrap_iife() {
  local curdir; curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir; libdir="$(realpath -- "${curdir}/../lib")"

  local f; for f in "${libdir}"/*.sh; do . "${f}"; done

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

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
