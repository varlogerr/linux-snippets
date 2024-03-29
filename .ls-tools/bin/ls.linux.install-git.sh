#!/usr/bin/env bash

{ # SETTINGS
  declare -ar TOOLS=(
    git
  )
}

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    echo "Install git"
    exit 0
  }
  trap_help_opt "${@}" && print_help

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_ID_OR_LIKE[@]}"
  sys_must_root
}

configure_repo() {
  local gpg_key_url='https://keyserver.ubuntu.com/pks/lookup?op=get&search=0xe1dd270288b4e6030699e45fa1715d88e1df1f24'
  local gpg_key_file='/etc/apt/keyrings/git.gpg'
  local gpg_key_dir; gpg_key_dir="$(dirname -- "${gpg_key_file}")"
  local repo_codename; repo_codename="$(sys_match_ubu_codename)" || {
    trap_fatal 1 "Can't map ubuntu codename"
  }

  local repo_file_content; repo_file_content="$(text_clean "
    deb [signed-by=${gpg_key_file}] https://ppa.launchpadcontent.net/git-core/ppa/ubuntu ${repo_codename} main
    deb-src [signed-by=${gpg_key_file}] https://ppa.launchpadcontent.net/git-core/ppa/ubuntu ${repo_codename} main
  ")"
  local repo_file=/etc/apt/sources.list.d/git.list

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

git_install() {
  configure_repo
  (set -x; apt-get install -y "${TOOLS[@]}")
}

git_install
