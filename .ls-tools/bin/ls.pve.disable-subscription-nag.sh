#!/usr/bin/env bash

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  TPLDIR="$(realpath -- "${CURDIR}/../tpl")"
  declare -r CURDIR LIBDIR TPLDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

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
