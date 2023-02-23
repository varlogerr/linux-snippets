#!/usr/bin/env bash

{ # SETTINGS
  declare -Ar DEST_SNIPPET_MAP=(
    # [DEST_SYMLINK_FILENAME]=SRC_FILENAME
    ['nas1.sh']=nas1.sh
    ['nas1-servant1.sh']=nas1-servants.sh
    ['nas1-servant2.sh']=nas1-servants.sh
  )
}

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  ROOTFSDIR="$(realpath -- "${CURDIR}/../rootfs")"
  declare -r CURDIR LIBDIR ROOTFSDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

install_hooks() {
  local hooks_dir="/root/.ls-tools-toolset/pve/hook"
  local dest_dir="/var/lib/vz/snippets"

  (set -x; cp -r "${ROOTFSDIR}/root/.ls-tools-toolset" /root &>/dev/null) || {
    trap_fatal 1 "Can't copy toolset"
  }

  (set -x; mkdir -p "${dest_dir}" &>/dev/null) || {
    trap_fatal 1 "Can't create snippets directory"
  }

  local src_path
  local dest_path
  local dest_filename; for dest_filename in "${!DEST_SNIPPET_MAP[@]}"; do
    dest_path="${dest_dir}/${dest_filename}"
    src_path="${hooks_dir}/${DEST_SNIPPET_MAP[${dest_filename}]}"

    (set -x; chmod 0755 "${src_path}" &>/dev/null) || {
      log_warn "Can't chmod nas snippet"
      continue
    }

    (set -x; ln -fs "${src_path}" "${dest_path}" &>/dev/null) || {
      log_warn "Can't symlink nas snippet"
    }
  done
}

install_hooks
