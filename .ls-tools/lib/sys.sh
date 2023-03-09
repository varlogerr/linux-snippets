{ # CONSTANTS
  declare -Ar SYS_DEB_TO_UBU_CODENAME_MAP=(
    [bullseye]=focal
    [buster]=bionic
  )
  declare -ar SYS_SUPPORTED_ID_OR_LIKE=(
    debian
    ubuntu
  )
}

{ # FUNCTIONS
  sys_is_root() { test $(id -u) -eq 0; }

  sys_must_root() {
    sys_is_root || trap_fatal $? 'Must run as root!'
  }

  # Print current distro id in lowercase
  #
  # RC:
  # * 0 - distro id is detected and printed to stdout
  # * other - couldn't detect distro id
  sys_dist_id() {
    local -l id; id="$(
      set -o pipefail
      grep '^ID=.\+' /etc/os-release 2>/dev/null | cut -d= -f2-
    )" || return $?

    printf '%s\n' "${id}"
    return 0
  }

  # Check if the current distro id is in range from input
  #
  # Usage:
  #   sys_dist_id_in DIST_ID...
  # RC:
  # * 0 - current distro is one of DIST_ID
  # * other - current distro is not one of DIST_ID
  sys_dist_id_in() {
    local -l search_ids="${@}"
    local id; id="$(sys_dist_id)" || return $?
    [[ " ${search_ids[@]} " == *" ${id} "* ]]
  }

  # Print current distro id like in lowercase, one like at a line
  #
  # RC:
  # * 0 - distro id like is detected and printed to stdout
  # * other - couldn't detect distro id like
  sys_dist_id_like() {
    local -l id_like; id_like="$(
      set -o pipefail
      grep '^ID_LIKE=.\+' /etc/os-release 2>/dev/null | cut -d= -f2- \
      | sed -e 's/^"\([^"]*\)"$/\1/' -e "s/^'\\([^']*\\)'\$/\\1/" \
      | tr ' ' '\n' | grep -v '^\s*$'
    )" || return $?

    printf '%s\n' "${id_like}"
    return 0
  }

  # Check if the current distro id like is in range from input
  #
  # Usage:
  #   sys_dist_id_in DIST_ID...
  # RC:
  # * 0 - current distro like is one of DIST_ID
  # * other - current distro like is not one of DIST_ID
  sys_dist_id_like_in() {
    local -l search_ids="${@}"
    local id_like; id_like="$(sys_dist_id_like)" || return $?
    tr ' ' '\n' <<< "${search_ids[@]}" | grep -v '^\s*$' \
    | grep -qFxf <(printf -- '%s\n' "${id_like}")
  }

  # Check if the current distro id or id like is in range from input
  #
  # Usage:
  #   sys_dist_id_or_like_in DIST_ID...
  # RC:
  # * 0 - current distro id or id like is one of DIST_ID
  # * other - current distro id or id like is not one of DIST_ID
  sys_dist_id_or_like_in() {
    sys_dist_id_in "${@}" || sys_dist_id_like_in "${@}"
  }

  sys_dist_must_id_or_like_in() {
    sys_dist_id_or_like_in "${@}" || trap_fatal --decore $? "
      Not supported distro ID, must be one of:
      $(printf -- '* %s\n' "${@}")
    "
  }

  # Detect if ubuntu codename can be matched with the distro
  # and print matching codename
  #
  # Usage:
  #   sys_match_ubu_codename
  # RC:
  # * 0 - match found and printed
  # * other - match is not found
  sys_match_ubu_codename() {
    local os_release_file=/etc/os-release
    local mapped_codename
    local id; id="$(sys_dist_id)" || return $?

    [[ "${id}" == debian ]] && {
      local dist_codename
      dist_codename="$(grep '^VERSION_CODENAME=.*' "${os_release_file}" | cut -d= -f2)"

      [[ "${SYS_DEB_TO_UBU_CODENAME_MAP[${dist_codename}]+x}" ]] || return 1

      printf -- '%s\n' "${SYS_DEB_TO_UBU_CODENAME_MAP[${dist_codename}]}"
      return 0
    }

    [[ "${id}" == ubuntu ]] && {
      grep '^VERSION_CODENAME=.*' "${os_release_file}" | cut -d= -f2
      return 0
    }

    sys_dist_id_like_in ubuntu && {
      grep '^UBUNTU_CODENAME=.*' "${os_release_file}" | cut -d= -f2
      return 0
    }

    return 1
  }
}
