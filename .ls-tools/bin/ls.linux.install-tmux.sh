#!/usr/bin/env bash

# SETTINGS START
  declare -a TOOLS=(tmux)
  TMUX_DEFAULT_CONFFILE=/etc/tmux/default.conf
  TMUX_USER_CONFFILE="${HOME}/.tmux.conf"
# SETTINGS END

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  # must be exposed
  TPLDIR="$(realpath -- "${curdir}/../tpl")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

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
