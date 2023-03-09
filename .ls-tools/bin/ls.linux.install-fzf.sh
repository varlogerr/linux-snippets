#!/usr/bin/env bash

{ # SETTINGS
  # https://github.com/junegunn/fzf/releases
  declare -r FZF_VERSION="0.38.0"
  declare -r FZF_HOME=/opt/junegunn/fzf
  declare -r FZF_HOME_BIN="${FZF_HOME}/bin"
  declare -r FZF_HOME_SHELL="${FZF_HOME}/shell"
}

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  TPLDIR="$(realpath -- "${CURDIR}/../tpl")"
  declare -r CURDIR LIBDIR TPLDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    text_decore "
      Install fzf
     .
      $(sys_ls_supported_platforms)
    "
  }

  trap_help_opt "${@}" && { print_help; exit 0; }

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_ID_OR_LIKE[@]}"
  sys_must_root
}

declare -r FZF_PKG_DL_URL="https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
declare -r FZF_SRC_DL_URL="https://github.com/junegunn/fzf/archive/refs/tags/${FZF_VERSION}.tar.gz"
declare -r FZF_BASH_CONFFILE="${FZF_HOME}/source.bash"

RELOGIN_RECOMMENDED=false

install_fzf() {
  # Install binary
  (set -x; mkdir -p "${FZF_HOME_BIN}" 2>/dev/null) || {
    trap_fatal 1 "Can't create binary directory"
  }
  common_dl_file_to_stdout "${FZF_PKG_DL_URL}" | (set -x; tar -xzf - -C "${FZF_HOME_BIN}" 2>/dev/null) || {
    trap_fatal 1 "Can't download package"
  }

  (set -x; chmod 0755 "${FZF_HOME_BIN}/fzf" 2>/dev/null) || {
    trap_fatal 1 "Can't chmod binary"
  }

  # Install source code
  local src_tmp_dir
  src_tmp_dir="$(set -x; mktemp -d --suffix .tmux-source 2>/dev/null)" || {
    trap_fatal 1 "Can't create temp directory"
  }
  (set -x; mkdir -p "${FZF_HOME_SHELL}" 2>/dev/null) || {
    trap_fatal 1 "Can't create shell directory"
  }
  common_dl_file_to_stdout "${FZF_SRC_DL_URL}" | (set -x; tar -xzf - -C "${src_tmp_dir}" 2>/dev/null) || {
    trap_fatal 1 "Can't download package"
  }

  (
    set -x
    /bin/cp -f "${src_tmp_dir}"/*/bin/* "${FZF_HOME_BIN}" 2>/dev/null
    /bin/cp -f "${src_tmp_dir}"/*/shell/* "${FZF_HOME_SHELL}" 2>/dev/null
  ) || {
    trap_fatal 1 "Can't copy scripts or binaries"
  }

  local src_tmp_dir_parent; src_tmp_dir_parent="$(dirname -- "${src_tmp_dir}")"
  local src_tmp_dir_name; src_tmp_dir_name="$(basename -- "${src_tmp_dir}")"
  (
    set -x
    cd "${src_tmp_dir_parent}" \
    && rm -rf "${src_tmp_dir_name}"
  )
}

configure_fzf() {
  local default_tpl_path="${TPLDIR}/fzf-default.bash"
  local bin_home_replace; bin_home_replace="$(sed_quote_replace "${FZF_HOME_BIN}")"
  local shell_home_replace; shell_home_replace="$(sed_quote_replace "${FZF_HOME_SHELL}")"

  (
    set -o pipefail
    set -x

    sed -e 's/{{\s*bin_home\s*}}/'"${bin_home_replace}"'/g' \
        -e 's/{{\s*shell_home\s*}}/'"${shell_home_replace}"'/g' \
        "${default_tpl_path}" 2>/dev/null \
    | tee "${FZF_BASH_CONFFILE}" &>/dev/null
  ) || {
    trap_fatal 1 "Can't create default fzf conffile"
  }
  (
    set -x \
    && chown 0:0 "${FZF_BASH_CONFFILE}" &>/dev/null \
    && chmod 0644 "${FZF_BASH_CONFFILE}" &>/dev/null
  ) || {
    trap_fatal 1 "Can't change default fzf conffile permissions"
  }

  if ! grep -qFx ". '${FZF_HOME}/source.bash'" ~/.bashrc; then
    (set -x; echo ". '${FZF_HOME}/source.bash'" | tee -a ~/.bashrc &>/dev/null) || {
      trap_fatal 1 "Can't update user ~/.bashrc"
    }

    RELOGIN_RECOMMENDED=true
  fi
}

print_post_info() {
  ${RELOGIN_RECOMMENDED} || return

  log_info ""
  log_info '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
  log_info "Execute to use fzf immediately:"
  log_info '```'
  log_info ". ~/.bashrc"
  log_info '```'
  log_info '~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~'
  log_info ""
}

install_fzf
configure_fzf
print_post_info
