#!/usr/bin/env bash

# REFERENCE:
# https://serverfault.com/a/446048

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    text_clean "
      Fix locale.
      Not directly related to PVE
    "
    exit 0
  }
  trap_help_opt "${@}" && print_help

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

print_on_change_info() {
  log_info ''
  log_info '~~~~~~~~~~~~~~~~~~~~~~~'
  log_info 'Re-login is recommended'
  log_info '~~~~~~~~~~~~~~~~~~~~~~~'
  log_info ''
}

print_on_nochange_info() {
  log_info ''
  log_info '~~~~~~~~~~'
  log_info 'No changes'
  log_info '~~~~~~~~~~'
  log_info ''
}

fix_locale() {
  local missing_vars; missing_vars="$(locale 2>/dev/null | grep '=$')"

  if [[ -z "${missing_vars}" ]]; then
    return 1
  fi

  local kv_str; kv_str="$(sed 's/$/en_US.UTF-8/' <<< "${missing_vars}")"
  local -a kv_arr; mapfile -t kv_arr <<< "${kv_str}"

  (set -x; update-locale "${kv_arr[@]}" 2>/dev/null)

  return 0
}

fix_locale && {
  print_on_change_info
} || {
  print_on_nochange_info
}
