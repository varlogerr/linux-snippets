#!/usr/bin/env bash

# REFERENCE:
# https://serverfault.com/a/446048

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

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
