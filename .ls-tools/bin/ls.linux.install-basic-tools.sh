#!/usr/bin/env bash

{ # SETTINGS
  declare -ar TOOLS=(
    bash-completion
    curl
    htop
    nano
    tar
    tree
    vim
    wget
  )
}

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    text_decore "
      Install basic linux tools:
      $(printf -- '%s\n' "${TOOLS[@]}" | sort -n | sed 's/^/* /')
     .
      $(sys_ls_supported_platforms)
    "
  }

  trap_help_opt "${@}" && { print_help; exit 0; }

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_ID_OR_LIKE[@]}"
  sys_must_root
}

install_basic_tools() {
  (set -x; apt-get update; apt-get install -y "${TOOLS[@]}")
}

install_basic_tools
