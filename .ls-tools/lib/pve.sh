{ # CONSTANTS
  declare -ra PVE_SUPPORTED_VERSIONS=(7)
}

{ # FUNCTIONS
  # Usage:
  #   pve_version_in 6 7 [...]
  #   # RC:
  #   # * 0 - version matches
  #   # * 1 - version doesn't match
  pve_version_in() {
    local req_versions="${@}"
    local actual_version; actual_version="$(
      pveversion 2>/dev/null | cut -d'/' -f2 | cut -d'.' -f1
    )"

    [[ (-n "${actual_version}" && " ${req_versions[@]} " == *" ${actual_version} "*) ]]
  }

  pve_version_must_in() {
    pve_version_in "${@}" || trap_fatal --decore $? "
      The platform is required to be PVE of the following versions:
    " "$(printf -- '* %s\n' "${@}")"
  }

  pve_ls_supported_versions() {
    printf -- '%s\n%s\n' \
      "SUPPORTED PVE VERSIONS" \
      "======================"
    printf -- '* %s\n' "${PVE_SUPPORTED_VERSIONS[@]}"
  }
}
