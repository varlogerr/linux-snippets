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
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/pve.sh"
  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  declare -a supported_pve=(7)
  pve_version_must_in "${supported_pve[@]}"

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
