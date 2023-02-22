#!/usr/bin/env bash

# SETTINGS START
  declare -a TOOLS=(
    bash-completion
    curl
    htop
    nano
    tar
    tree
    vim
    wget
  )
# SETTINGS END

__bootstrap_iife() {
  local curdir; curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir; libdir="$(realpath -- "${curdir}/../lib")"

  local f; for f in "${libdir}"/*.sh; do . "${f}"; done

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_PLATFORMS[@]}"
  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

install_basic_tools() {
  (set -x; apt-get update; apt-get install -y "${TOOLS[@]}")
}

install_basic_tools
