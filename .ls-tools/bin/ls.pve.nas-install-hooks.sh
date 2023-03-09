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

  declare -r HOOKS_SRCDIR=/root/.ls-tools-toolset/pve/hook
  declare -r HOOKS_DESTDIR=/var/lib/vz/snippets

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    echo "Install NAS related hooks on PVE"
    exit 0
  }
  trap_help_opt "${@}" && print_help

  pve_version_must_in "${PVE_SUPPORTED_VERSIONS[@]}"
  sys_must_root
}

install_hooks() {
  (set -x; cp -r "${ROOTFSDIR}/root/.ls-tools-toolset" /root &>/dev/null) || {
    trap_fatal 1 "Can't copy toolset"
  }

  (set -x; mkdir -p "${HOOKS_DESTDIR}" &>/dev/null) || {
    trap_fatal 1 "Can't create snippets directory"
  }

  local src_path
  local dest_path
  local dest_filename; for dest_filename in "${!DEST_SNIPPET_MAP[@]}"; do
    dest_path="${HOOKS_DESTDIR}/${dest_filename}"
    src_path="${HOOKS_SRCDIR}/${DEST_SNIPPET_MAP[${dest_filename}]}"

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
