#!/usr/bin/env bash

# REFERENCE:
# https://docs.ansible.com/ansible/latest/installation_guide/installation_distros.html

# SETTINGS START
  declare -a TOOLS=(
    ansible
    openssh-client
    python3
    # optional completion
    python3-argcomplete
  )
# SETTINGS END

__bootstrap_iife() {
  local curdir; curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir; libdir="$(realpath -- "${curdir}/../lib")"

  local f; for f in "${libdir}"/*.sh; do . "${f}"; done

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_PLATFORMS[@]}"
  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

declare -A DEB_CODENAME_MAP=(
  [bullseye]=focal
  [buster]=bionic
)

get_ubu_codename() {
  local os_release_file=/etc/os-release
  local mapped_codename

  if [[ "$(sys_dist_id)" == debian ]]; then
    local dist_codename
    dist_codename="$(grep '^VERSION_CODENAME=.*' "${os_release_file}" | cut -d= -f2)"
    mapped_codename="${DEB_CODENAME_MAP[${dist_codename}]}"
  elif [[ "$(sys_dist_id)" == ubuntu ]]; then
    mapped_codename="$(grep '^VERSION_CODENAME=.*' "${os_release_file}" | cut -d= -f2)"
  elif [[ "$(sys_dist_id_like)" == ubuntu ]]; then
    mapped_codename="$(grep '^UBUNTU_CODENAME=.*' "${os_release_file}" | cut -d= -f2)"
  else
    trap_fatal 1 "Can't map ubuntu codename"
  fi

  printf -- '%s\n' "${mapped_codename}"
}

configure_repo() {
  local gpg_key_url='https://keyserver.ubuntu.com/pks/lookup?op=get&search=0x6125e2a8c77f2818fb7bd15b93c4a3fd7bb9c367'
  local gpg_key_file='/etc/apt/keyrings/ansible.gpg'
  local gpg_key_dir; gpg_key_dir="$(dirname -- "${gpg_key_file}")"
  local repo_codename; repo_codename="$(get_ubu_codename)"
  local repo_file_content; repo_file_content="$(text_clean "
    deb [signed-by=${gpg_key_file}] https://ppa.launchpadcontent.net/ansible/ansible/ubuntu ${repo_codename} main
    deb-src [signed-by=${gpg_key_file}] https://ppa.launchpadcontent.net/ansible/ansible/ubuntu ${repo_codename} main
  ")"
  local repo_file=/etc/apt/sources.list.d/ansible.list

  (
    set -x
    apt-get update
    apt-get install -y software-properties-common
    mkdir -p -- "${gpg_key_dir}"
  )

  (
    set -o pipefail
    common_dl_file_to_stdout "${gpg_key_url}" | (
      set -x
      gpg --dearmor | tee "${gpg_key_file}" >/dev/null
      cat <(set +x; echo "${repo_file_content}") | tee "${repo_file}" >/dev/null
      apt-get update
    )
  )
}

ansible_ctl_install() {
  configure_repo
  (set -x; apt-get install -y "${TOOLS[@]}")
}

ansible_ctl_install
