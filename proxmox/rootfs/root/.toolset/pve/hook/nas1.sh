#!/usr/bin/env bash

ID="${1}"
PHASE="${2}"
# PHASE:
# * pre-start
# * post-start
# * pre-stop
# * post-stop - the only stable, that works also
#               with `poweroff` from inside continer

PVE_HOME=/root/.toolset/pve

. "${PVE_HOME}/lib/shlib.sh" 2>/dev/null || { echo "Can't source ${PVE_HOME}/lib/shlib.sh" >&2; exit 1; }
. "${PVE_HOME}/lib/pve.sh" 2>/dev/null || trap_fatal --decore $? "Can't source ${PVE_HOME}/lib/pve.sh"
. "${PVE_HOME}/lib/lxc.sh" 2>/dev/null || trap_fatal --decore $? "Can't source ${PVE_HOME}/lib/lxc.sh"

# detect devmode
DEVMODE=false
cat /root/.toolset-conf/pve/devmode/${ID} &>/dev/null && {
  log_info "(${PHASE}) Devmode"
  DEVMODE=true
}

LXC_CONFFILE="/etc/pve/lxc/${ID}.conf"
MOUNT_THROUGH_CONFFILE="${PVE_HOME}/conf/${ID}.mount.conf"
INSECURE_CONFFILE="${PVE_HOME}/conf/lib/insecure.conf"
VPN_READY_CONFFILE="${PVE_HOME}/conf/lib/vpn-ready.conf"

LXC_CONF="$(cat "${LXC_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${LXC_CONFFILE}"
MOUNT_THROUGH_CONF="$(cat "${MOUNT_THROUGH_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${MOUNT_THROUGH_CONFFILE}"
MAIN_CONF="$(cat "${INSECURE_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${INSECURE_CONFFILE}"
MAIN_CONF+=$'\n'"$(cat "${VPN_READY_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${VPN_READY_CONFFILE}"

declare -A MOUNT_THROUGH_MAP; pve_conf_txt_to_map "${MOUNT_THROUGH_CONF}" MOUNT_THROUGH_MAP
declare -A MAIN_CONF_MAP; pve_conf_txt_to_map "${MAIN_CONF}" MAIN_CONF_MAP

ensure_host_mountpoints() {
  # check all mount points
  declare -a host_mps; [[ -n "${MOUNT_THROUGH_MAP[@]}" ]] \
    && mapfile -t host_mps <<< "$(
      printf -- '%s\n' "${MOUNT_THROUGH_MAP[@]}" \
      | cut -d: -f1 | sort -n | uniq
    )"

  local mps_count=${#host_mps[@]}
  local mp
  local ix=0; while [[ ${ix} -lt ${mps_count} ]]; do
    mp="${host_mps[${ix}]}"
    (( ix++ ))

    [[ -n "${mp}" ]] || continue

    # continue if already mounted or succeeded to mount
    mountpoint -q -- "${mp}" 2>/dev/null && continue
    mount "${mp}" &>/dev/null
    mountpoint -q -- "${mp}" 2>/dev/null && continue

    log_warn "${mp} not mounted"
    # freeze for 60 secs and go to check all mountpoints again
    sleep 60
    ix=0
  done
}

# validate format and configure config line
prepare_bind_mount_map() {
  declare -a inval_form
  local item
  local volume
  local mp
  local key; for key in "${!MOUNT_THROUGH_MAP[@]}"; do
    item="${MOUNT_THROUGH_MAP[${key}]}"
    volume="$(cut -d: -f2 <<< "${item}:")"
    mp="$(cut -d: -f3 <<< "${item}:")"

    grep -qx '^mp[0-9]\+$' <<< "${key}" || { inval_form+=("${key}: ${item}"); continue; }
    [[ "${volume:0:1}" == '/' ]] || { inval_form+=("${key}: ${item}"); continue; }
    [[ "${mp:0:1}" == '/' ]] || { inval_form+=("${key}: ${item}"); continue; }

    MOUNT_THROUGH_MAP[${key}]="${volume},mp=${mp}"
    MOUNT_THROUGH_MAP[${key}]+=",mountoptions=noatime,replicate=0,backup=0"
  done

  [[ ${#inval_form[@]} -lt 1 ]] || trap_fatal --decore $? "
    Invalid format
  " "$(printf -- '* %s\n' "${inval_form}")"
}

if [[ " pre-start " == *" ${PHASE} "* ]]; then
  ${DEVMODE} && {
    MOUNT_THROUGH_MAP=()
  } || {
    ensure_host_mountpoints
    prepare_bind_mount_map
  }

  for i in "${!MOUNT_THROUGH_MAP[@]}"; do
    MAIN_CONF_MAP["${i}"]="${MOUNT_THROUGH_MAP[${i}]}"
  done

  /bin/cp -f "${LXC_CONFFILE}" "${LXC_CONFFILE}.bak" 2>/dev/null || {
    trap_fatal "Can't backup conffile: ${LXC_CONFFILE}"
    exit 1
  }

  pve_conf_merge_map "${LXC_CONF}" MAIN_CONF_MAP \
  | tee -- "${LXC_CONFFILE}" >/dev/null 2>&1 || {
    trap_fatal "Can't override: ${LXC_CONFFILE}"
    exit 1
  }
fi

if [[ " post-start " == *" ${PHASE} "* ]]; then
  export  LXC_ID="${ID}" \
          LXC_UID=1000 \
          LXC_GROUP=bug1 \
          LXC_GID=1000 \
          LXC_USER=bug1 \
          LXC_HOME=/home/bug1 \
          LXC_SUDO=true \
          LXC_PASS \
          LXC_SSH_PUBKEY

  LXC_PASS="$(cat "/root/.toolset-conf/pve/secrets/homelab/pass/${ID}.pass" 2>/dev/null)" \
  || LXC_PASS="$(cat "/root/.toolset-conf/pve/secrets/homelab/pass/master.pass" 2>/dev/null)" \
  || log_warn "Can't get user password, passwordless user will be created."

  # create user
  lxc_ensure_group
  lxc_ensure_user
  # deploy public ssh key
  lxc_ensure_ssh_pubkey "${PVE_HOME}/assets/ssh/homelab.pub"
fi

if [[ " pre-stop post-stop " == *" ${PHASE} "*  ]]; then
  # unmount bind mounts
  prepare_bind_mount_map
  pve_conf_rm_keys "${LXC_CONF}" "${!MOUNT_THROUGH_MAP[@]}" \
  | tee -- "${LXC_CONFFILE}" >/dev/null 2>&1 || {
    log_warn "Can't override: ${LXC_CONFFILE}"
  }
fi
