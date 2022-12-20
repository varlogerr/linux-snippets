#!/usr/bin/env bash

# SETTINGS START
  declare -a TOOLS=(
    vim
    htop
    bash-completion
  )
# SETTINGS END

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

install_basic_tools() {
  (set -x; apt-get update; apt-get install -y "${TOOLS[@]}")
}

install_basic_tools
