#!/usr/bin/env bash

declare PKG_NAME=linux-snippets
declare PKG_BRANCH="${1:-master}"
declare PKG_DL_URL="https://github.com/varlogerr/${PKG_NAME}/archive/refs/heads/${PKG_BRANCH}.tar.gz"
declare TMP_DL_DIR
declare PKG_ARCHIVE_PATH

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/common.sh"
  . "${libdir}/pve.sh"
  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  declare -a supported_pve=(7)
  pve_version_must_in "${supported_pve[@]}"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

TMP_DL_DIR="$(set -x; mktemp --directory --suffix .ls)" || {
  trap_fatal 1 "Can't create temporary directory"
}
PKG_ARCHIVE_PATH="${TMP_DL_DIR}/ls.tar.gz"

pkg_extract() {
  (set -x; tar -xf "${PKG_ARCHIVE_PATH}" -C "${TMP_DL_DIR}" &>/dev/null) || {
    trap_fatal 1 "Can't extract ${PKG_ARCHIVE_PATH}"
  }
  (set -x; cp -rf "${TMP_DL_DIR}/${PKG_NAME}-${PKG_BRANCH}/." "${TMP_DL_DIR}" &>/dev/null) || {
    trap_fatal 1 "Can't copy package content to tmp download directory"
  }
}

perform_cleanup() {
  local base_tmp_dir; base_tmp_dir="$(dirname -- "${TMP_DL_DIR}")"
  local tmp_dl_dirname; tmp_dl_dirname="$(basename -- "${TMP_DL_DIR}")"
  (set -x; cd "${base_tmp_dir}" &>/dev/null && rm -rf "${tmp_dl_dirname}" &>/dev/null)
}

install_hooks() {
  local dest_dirpath="/var/lib/vz/snippets"

  declare -A src_dest_map=(
    ['nas1.sh']=nas.sh
    ['servants.sh']=servants.sh
  )

  (set -x; cp -r "${TMP_DL_DIR}/proxmox/rootfs/root/.toolset" /root &>/dev/null) || {
    trap_fatal 1 "Can't copy toolset"
  }

  (set -x; mkdir -p "${dest_dirpath}" &>/dev/null) || {
    trap_fatal 1 "Can't create snippets directory"
  }

  local dest_filename
  local src; for src in "${!src_dest_map[@]}"; do
    dest_filename="${src_dest_map[${src}]}"

    (set -x; ln -fs "/root/.toolset/pve/hook/${src}" "${dest_dirpath}/${dest_filename}" &>/dev/null) || {
      trap_fatal 1 "Can't create nas snippet"
    }
  done
}

err="$(common_dl_file_to "${PKG_DL_URL}" "${PKG_ARCHIVE_PATH}")" || {
  trap_fatal $? "${err}"
}
pkg_extract
install_hooks
perform_cleanup
