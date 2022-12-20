#!/usr/bin/env bash

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

REBOOT_RECOMMENDED=false

# When some USB ports don't work with enabled IOMMU
# in BIOS. The solution is based on point 3 from:
# https://bbs.minisforum.com/threads/the-iommu-issue-boot-and-usb-problems.2180/
# Applied fix requires reboot
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

fix_grub_usb_issue
print_post_info
