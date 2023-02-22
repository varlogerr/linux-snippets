#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir; curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir; libdir="$(realpath -- "${curdir}/../lib")"

  local f; for f in "${libdir}"/*.sh; do . "${f}"; done

  # must be exposed
  TPLDIR="$(realpath -- "${curdir}/../tpl")"

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

disable_subscription_nag() {
  local dest=/etc/apt/apt.conf.d/no-nag-script
  local unnag_script_path="${TPLDIR}/pve-unnag-script.txt"

  (
    set -x
    /bin/cp -f "${unnag_script_path}" "${dest}" 2>/dev/null \
    && apt --reinstall install proxmox-widget-toolkit &>/dev/null
  ) || trap_fatal 1 "Can't disable subscription nag"
}

disable_subscription_nag
