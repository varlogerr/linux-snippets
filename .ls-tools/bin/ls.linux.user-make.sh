#!/usr/bin/env bash

# @CONFBLOCK
declare -A USER_MAKE_CONF=(
  # (required) Login name
  [login]=""
  # (optional) Full name
  [fullname]=""
  # (optional, bool, default: false)
  # Make a system user.
  # Works only if user doesn't exist
  [is_system]=false
  # (optional, bool, default: true)
  # Make the user sudoer
  [is_sudoer]=true
  # (optional, bool, default: false)
  # Change user password
  [chpass]=false
)
# @/CONFBLOCK

{ # BOOTSTRAP
  CURDIR="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  LIBDIR="$(realpath -- "${CURDIR}/../lib")"
  TOOLNAME="$(basename -- "${0}")"
  declare -r CURDIR LIBDIR

  for f in "${LIBDIR}"/*.sh; do . "${f}"; done

  print_help() {
    text_decore "
      Create a user.
     .
      USAGE
      =====
     .  # Generate a conffile dummy to stdout or a file.
     .  # For file it will try to create parent directories
     .  ${TOOLNAME} --genconf [--] [CONFFILE]
     .
     .  # Create a user based on conffile
     .  ${TOOLNAME} [--] CONFFILE
     .
      $(sys_ls_supported_platforms)
    "
  }

  gen_conf() {
    local destfile="${OPTS[conffile]-/dev/stdout}"
    local destdir; destdir="$(dirname -- "${destfile}")"

    (set -x; mkdir -p "${destdir}" 2>/dev/null) || {
      trap_fatal $? "Can't create destination directory"
    }

    cat "${0}" \
    | tag_node_get --prefix '# @' -- CONFBLOCK \
    | (sed -e '1d;$d;' > "${destfile}") 2>/dev/null || {
      trap_fatal $? "Can't write to ${destfile}"
    }
  }

  trap_help_opt "${@}" && { print_help; exit 0; }
  opts_trap_genconf "${@}" && { gen_conf; exit 0; }

  sys_dist_must_id_or_like_in "${SYS_SUPPORTED_ID_OR_LIKE[@]}"
  sys_must_root
}

[[ -n "${OPTS[conffile]}" ]] || trap_fatal 1 "CONFFILE is required"

. "${OPTS[conffile]}" &>/dev/null || {
  trap_fatal 1 "Can't open or process conffile ${OPTS[conffile]}"
}

_install_mk_chfn_chpass_sudoer_deps() {
  declare -a deps=(
    passwd
  )
  local missing; missing="$(
    printf -- '%s\n' "${deps[@]}" | tr ' ' '\n' \
    | grep -vFxf <(
      apt list --installed 2>/dev/null | cut -d'/' -f1
    )
  )"

  [[ -n "${missing}" ]] || {
    log_info "No dependencies to be installed"
    return 0
  }

  local -a deps; mapfile -t deps <<< "${missing}"
  (
    set -x
    apt-get update &>/dev/null
    apt-get install -y "${deps[@]}" &>/dev/null
  ) || {
    log_warn "Can't install dependencies:" "$(printf -- '* %s\n' "${deps[@]}")"
  }
}

user_mk() {
  local login="${USER_MAKE_CONF[login]}"
  local -a args=(-m "${login}")
  local shell=/bin/bash

  id -u "${login}" &>/dev/null && {
    log_info "User ${login} already exists"
    return 0
  }

  [[ -f /usr/bin/bash ]] && shell=/usr/bin/bash
  ${USER_MAKE_CONF[is_system]:-false} && args+=('-r')
  args+=(-s "${shell}")

  _install_mk_chfn_chpass_sudoer_deps
  (set -x; useradd "${args[@]}" &>/dev/null) || {
    log_warn "Can't create user ${login}"
    return 1
  }
}

user_chpass() {
  local login="${USER_MAKE_CONF[login]}"
  local again=n

  ${USER_MAKE_CONF[chpass]:-false} || {
    log_info "No change password for ${login}"
    return 0
  }

  _install_mk_chfn_chpass_sudoer_deps
  while :; do
    (set -x; passwd "${login}") && break 1

    log_warn "Can't set the password"

    while :; do
      read -e -p "Another try? [y/n]: " -i "y" again
      [[ "${again,,}" == y ]] && break 1
      [[ "${again,,}" == n ]] && break 2

      log_warn "Invalid choice"
    done
  done
}

user_chfn() {
  local login="${USER_MAKE_CONF[login]}"
  local fullname="${USER_MAKE_CONF[fullname]}"

  [[ -n "${fullname}" ]] || {
    log_info "Fullname for ${login} will not be changed"
    return 0
  }

  if ! (
    getent passwd "${login}" 2>/dev/null \
    | cut -d ':' -f 5 | cut -d ',' -f 1 \
    | grep -qFx "${fullname}"
  ); then
    log_info "Fullname for ${login} will not be changed"
    return 0
  fi

  _install_mk_chfn_chpass_sudoer_deps
  (set -x; usermod -c "${fullname}" "${login}" &>/dev/null) || {
    log_warn "Can't change ${login} fullname to ${fullname}"
    return 1
  }
}

user_apply_sudoer() {
  local login="${USER_MAKE_CONF[login]}"
  local groups; groups="$(id -Gn "${login}" 2>/dev/null)"
  local group=sudo

  if (: \
    && ${USER_MAKE_CONF[is_sudoer]} \
    && [[ " ${groups} " == *" ${group} "* ]] \
  ) || (: \
    && ! ${USER_MAKE_CONF[is_sudoer]} \
    && [[ " ${groups} " != *" ${group} "* ]] \
  ); then
    log_info "No sudoer status change to be done to ${login}"
    return 0
  fi

  local -a cmd=(usermod -aG "${group}" "${login}")
  ${USER_MAKE_CONF[is_sudoer]} || cmd=(gpasswd -d "${login}" "${group}")

  _install_mk_chfn_chpass_sudoer_deps
  (set -x; "${cmd[@]}" &>/dev/null) || {
    log_info "Can't change sudoer status for ${login}"
    return 1
  }
}

: \
&& user_mk \
&& {
  user_chpass
  user_chfn
  user_apply_sudoer
}
