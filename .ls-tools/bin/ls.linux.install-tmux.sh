#!/usr/bin/env bash

{ # SETTINGS
  declare -ar TOOLS=(
    tmux
  )
  declare -ar TMUX_DEFAULT_CONFFILE=/etc/tmux/default.conf
  declare -ar TMUX_USER_CONFFILE="${HOME}/.tmux.conf"
}

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  TPLDIR="$(realpath -- "${CURDIR}/../tpl")"
  declare -r CURDIR LIBDIR TPLDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_ID_OR_LIKE[@]}"
  sys_must_root
}

install_tmux() {
  (set -x; apt-get update; apt-get install -y "${TOOLS[@]}")
}

configure_tmux() {
  local default_tpl_path="${TPLDIR}/tmux-default.conf"
  # create default tmux configuration
  local tmux_default_conf_dir
  tmux_default_conf_dir="$(dirname -- "${TMUX_DEFAULT_CONFFILE}" 2>/dev/null)"
  (
    set -x
    mkdir -p "${tmux_default_conf_dir}" 2>/dev/null
  ) || {
    trap_fatal 1 "Can't create default tmux conffile diriectory"
  }
  (
    set -x
    cp "${default_tpl_path}" "${TMUX_DEFAULT_CONFFILE}" &>/dev/null
  ) || {
    trap_fatal 1 "Can't create default tmux conffile"
  }
  (
    set -x \
    && chown 0:0 "${TMUX_DEFAULT_CONFFILE}" &>/dev/null \
    && chmod 0644 "${TMUX_DEFAULT_CONFFILE}" &>/dev/null
  ) || {
    trap_fatal 1 "Can't change default tmux conffile permissions"
  }

  local conffile_path_ptn; conffile_path_ptn="$(sed_quote_pattern "${TMUX_DEFAULT_CONFFILE}")"

  # update user tmux configuration
  if ! grep -q '^\s*source-file\s\+'"${conffile_path_ptn}"'\s*$' "${TMUX_USER_CONFFILE}" 2>/dev/null; then
    (
      set -x
      echo "source-file ${TMUX_DEFAULT_CONFFILE}" \
      | tee -a "${TMUX_USER_CONFFILE}" &>/dev/null
    ) || {
      trap_fatal 1 "Can't update user tmux conffile"
    }
  fi
}

install_tmux
configure_tmux
