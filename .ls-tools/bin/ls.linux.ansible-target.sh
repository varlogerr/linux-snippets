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
