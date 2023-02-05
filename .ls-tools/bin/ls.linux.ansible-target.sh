#!/usr/bin/env bash

# SETTINGS START
  declare -a TOOLS=(
    openssh-server
    python3
  )
# SETTINGS END

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

ansible_target_install() {
  (
    set -x
    apt-get update
    apt-get install -y "${TOOLS[@]}"
    systemctl enable --now sshd
  )
}

ansible_target_install
