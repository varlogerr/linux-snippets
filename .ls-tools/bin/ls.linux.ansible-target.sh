#!/usr/bin/env bash

{ # SETTINGS
  declare -ar TOOLS=(
    openssh-server
    python3
  )
}

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    text_decore "
      Install ansible target machine dependencies
     .
      $(sys_ls_supported_platforms)
    "
  }

  trap_help_opt "${@}" && { print_help; exit 0; }

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_ID_OR_LIKE[@]}"
  sys_must_root
}

ansible_target_install() {
  (set -x; apt-get update; apt-get install -y "${TOOLS[@]}")

  local service_name; service_name="$(
    systemctl list-units --type service --all --plain --quiet \
    | grep -o '^\s*sshd\?\.service' \
    | sed -e 's/^\s*//' -e 's/\s*$//' | head -n 1 | cut -d' ' -f1
  )"
  service_name="${service_name:-sshd.service}"

  (set -x; systemctl enable --now "${service_name}")
}

ansible_target_install
