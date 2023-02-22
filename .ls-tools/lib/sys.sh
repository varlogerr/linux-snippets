#
# CONSTANTS
#

declare -ra SYS_SUPPORTED_ID_OR_LIKE=(debian ubuntu)

#
# FUNCTIONS
#

sys_is_root() { test $(id -u) -eq 0; }

sys_must_root() {
  sys_is_root || trap_fatal $? 'Must run as root!'
}

sys_dist_id() {
  grep '^ID=.*' /etc/os-release \
  | cut -d= -f2 | tr '[:upper:]' '[:lower:]'
}

sys_dist_id_like() {
  grep '^ID_LIKE=.*' /etc/os-release \
  | cut -d= -f2 | tr '[:upper:]' '[:lower:]'
}

# Searches in both ID and ID_LIKE
#
# Usage:
#   sys_dist_id_or_like_in debian ubuntu [...]
#   # RC:
#   # * 0 - current distro is one of
#   # * 1 - current distro is not one of
sys_dist_id_or_like_in() {
  local search_ids="${@}"

  local dist_id; dist_id="$(sys_dist_id)"
  if [[ (-n "${dist_id}" && " ${search_ids[@]} " == *" ${dist_id} "*) ]]; then
    return 0
  fi

  local dist_id_like; dist_id_like="$(sys_dist_id_like)"
  if [[ (-n "${dist_id}" && " ${search_ids[@]} " == *" ${dist_id_like} "*) ]]; then
    return 0
  fi

  return 1
}

sys_dist_must_id_or_like_in() {
  sys_dist_id_or_like_in "${@}" || trap_fatal --decore $? "
    Not supported distro ID, must be one of:
  " "$(printf -- '* %s\n' "${@}")"
}
