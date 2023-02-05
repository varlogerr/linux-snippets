#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  # must be exposed
  TPLDIR="$(realpath -- "${curdir}/../tpl")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

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