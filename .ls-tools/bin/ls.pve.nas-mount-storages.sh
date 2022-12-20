#!/usr/bin/env bash

# SETTINGS START
  DATA_DRIVE_UUID=593427d9-71a9-4b62-8fe1-c840087bf757
  DATA_DRIVE_MP=/mnt/data1
  BAK_DRIVE_UUID=1a64ebc9-17dc-4af2-9d92-9dafe3e42bcc
  BAK_DRIVE_MP=/mnt/bak1

  MOUNT_OPTS=noatime,nosuid,nodev,nofail,x-systemd.device-timeout=3s
  declare -A MP_MAP=(
    ["${DATA_DRIVE_UUID}"]="${DATA_DRIVE_MP}"
    ["${BAK_DRIVE_UUID}"]="${BAK_DRIVE_MP}"
  )
  declare -A SEARCH_REX_MAP=(
    ["${DATA_DRIVE_UUID}"]="^UUID=${DATA_DRIVE_UUID}\\s\\+${MP_MAP[${DATA_DRIVE_UUID}]} "
    ["${BAK_DRIVE_UUID}"]="^UUID=${BAK_DRIVE_UUID}\\s\\+${MP_MAP[${BAK_DRIVE_UUID}]} "
  )
  declare -A ENTRIES_MAP=(
    ["${DATA_DRIVE_UUID}"]="
      # data drive
      UUID=${DATA_DRIVE_UUID} ${MP_MAP[${DATA_DRIVE_UUID}]} ext4 ${MOUNT_OPTS} 0 0
    "
    ["${BAK_DRIVE_UUID}"]="
      # backup drive
      UUID=${BAK_DRIVE_UUID} ${MP_MAP[${BAK_DRIVE_UUID}]} ext4 ${MOUNT_OPTS} 0 0
    "
  )
# SETTINGS END

__bootstrap_iife() {
  local curdir="$(dirname -- "$(realpath -- "${BASH_SOURCE[0]}")")"
  local libdir="$(realpath -- "${curdir}/../lib")"

  . "${libdir}/shlib.sh"
  . "${libdir}/sys.sh"

  sys_must_root
}; __bootstrap_iife; unset __bootstrap_iife

mount_storages() {
  local dest_file=/etc/fstab

  declare -A add_map
  local search_rex
  local uuid; for uuid in "${!ENTRIES_MAP[@]}"; do
    search_rex="${SEARCH_REX_MAP[${uuid}]}"
    grep -q "${search_rex}" "${dest_file}" && continue

    add_map["${uuid}"]="${ENTRIES_MAP[${uuid}]}"
  done

  if [[ ${#add_map[@]} -lt 1 ]]; then
    log_warn "Nothing to mount. Exiting... "
    return
  fi

  local -a mp_dirs
  local uuid; for uuid in "${!add_map[@]}"; do
    log_info "Adding ${uuid} to ${dest_file}."
    (
      set -x
      grep -v '^\s*$' <<< "${add_map[${uuid}]}" \
      | sed 's/^\s\+//' | tee -a "${dest_file}" &>/dev/null
    ) || {
      log_warn "Can't create entry for ${uuid} in ${${dest_file}}"
      continue
    }

    mp_dirs+=("${MP_MAP[${uuid}]}")
  done

  if [[ ${#mp_dirs[@]} -gt 0 ]]; then
    # create directories to mount to and mount
    log_info "Creating mount points and mounting:"
    log_info "$(printf '* %s\n' "${mp_dirs[@]}")"
    (set -x; mkdir -p "${mp_dirs[@]}" && mount -a)
  fi
}

mount_storages
