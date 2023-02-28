#!/usr/bin/env bash

# When some USB ports don't work with enabled IOMMU
# in BIOS. Issue discussion:
# https://bbs.minisforum.com/threads/rear-usb-unstable-not-working.2130/
# The solution is based on point 3 from:
# https://bbs.minisforum.com/threads/the-iommu-issue-boot-and-usb-problems.2180/
# Applied fix requires reboot

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

REBOOT_RECOMMENDED=false

check_proc() {
  local match_name='amd ryzen'
  local model_name; model_name="$(
    set -o pipefail
    grep -i '^model name\s*:' /proc/cpuinfo 2>/dev/null | head -n 1 \
    | cut -d: -f2 | text_trim | tr '[:upper:]' '[:lower:]'
  )" || {
    log_err "Can't detect model name"
    return 1
  }

  [[ "${model_name} " == "${match_name} "* ]] || {
    trap_fatal 1 "Not AMD Ryzen model"
  }
}

fix_grub_usb_issue() {
  local grub_path=/etc/default/grub
  local entry_name=GRUB_CMDLINE_LINUX_DEFAULT
  local conf_changed=false
  local old_entry

  declare -A instructions=(
    [amd_iommu]=force_enable
    [iommu]=pt
  )

  old_entry="$(grep '^\s*'"${entry_name}=" "${grub_path}" 2>/dev/null)"
  local RC=$?

  [[ ${RC} -gt 1 ]] && return

  local new_value
  [[ ${RC} -lt 1 ]] && new_value="$(
    cut -d= -f2- <<< "${old_entry}" \
    | sed -e 's/^"//' -e 's/"$//' -e "s/^'//" -e "s/'$//"
  )"

  new_value="${new_value:-quiet}"

  local k; local v; for k in "${!instructions[@]}"; do
    v="${instructions[$k]}"
    grep -Fq " ${k}=${v} " <<< " ${new_value} " && continue

    grep -vFq " ${k}=" <<< " ${new_value}" \
    && new_value+="${new_value:+ }${k}=${v}" \
    || new_value="$(
      sed -E "s/ ${k}=[^"'\s'"]* / ${k}=${v} /" <<< " ${new_value} " | text_trim
    )"

    conf_changed=true
  done

  if ${conf_changed}; then
    local new_entry="${entry_name}=\"${new_value}\""
    local ts="$(date +%F_%H-%M-%S)"

    log_info "Old entry: ${old_entry}"
    log_info "New entry: ${new_entry}"
    : \
    && (set -x; /bin/cp -f "${grub_path}" "${grub_path}.bak.${ts}" &>/dev/null) \
    && (set -x; sed -i "s/^"'\s*'"${entry_name}=/#${entry_name}=/" "${grub_path}" &>/dev/null) \
    && (set -x; echo "${new_entry}" | tee -a "${grub_path}" &>/dev/null) \
    && (set -x; update-grub &>/dev/null)

    REBOOT_RECOMMENDED=true
  else
    log_info ""
    log_info '~~~~~~~~~'
    log_info "No change"
    log_info '~~~~~~~~~'
    log_info ""
  fi
}

print_post_info() {
  ${REBOOT_RECOMMENDED} || return

  log_info ""
  log_info '~~~~~~~~~~~~~~~~~~'
  log_info "Reboot recommended"
  log_info '~~~~~~~~~~~~~~~~~~'
  log_info ""
}

check_proc

fix_grub_usb_issue
print_post_info
