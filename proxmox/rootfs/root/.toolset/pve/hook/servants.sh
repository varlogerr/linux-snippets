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
BIND_MOUNT_CONFFILE="${PVE_HOME}/conf/${ID}.bind-mount.conf"
ORDER_FIRST_CONFFILE="${PVE_HOME}/conf/lib/first.conf"
INSECURE_CONFFILE="${PVE_HOME}/conf/lib/insecure.conf"
VPN_READY_CONFFILE="${PVE_HOME}/conf/lib/vpn-ready.conf"

LXC_CONF="$(cat "${LXC_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${LXC_CONFFILE}"
BIND_MOUNT_CONF="$(cat "${BIND_MOUNT_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${BIND_MOUNT_CONFFILE}"
MAIN_CONF="$(cat "${ORDER_FIRST_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${ORDER_FIRST_CONFFILE}"
MAIN_CONF+=$'\n'"$(cat "${INSECURE_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${INSECURE_CONFFILE}"
MAIN_CONF+=$'\n'"$(cat "${VPN_READY_CONFFILE}" 2>/dev/null)" || trap_fatal $? "Can't read conffile: ${VPN_READY_CONFFILE}"

declare -A BIND_MOUNT_MAP; pve_conf_txt_to_map "${BIND_MOUNT_CONF}" BIND_MOUNT_MAP
declare -A MAIN_CONF_MAP; pve_conf_txt_to_map "${MAIN_CONF}" MAIN_CONF_MAP

# validate format and configure config line
prepare_bind_mount_map() {
  declare -a inval_form
  local item
  local volume
  local mp
  local key; for key in "${!BIND_MOUNT_MAP[@]}"; do
    item="${BIND_MOUNT_MAP[${key}]}"
    volume="$(cut -d: -f1 <<< "${item}")"
    mp="$(cut -d: -f2 <<< "${item}:")"

    grep -qx '^mp[0-9]\+$' <<< "${key}" || { inval_form+=("${key}: ${item}"); continue; }
    [[ "${volume:0:1}" == '/' ]] || { inval_form+=("${key}: ${item}"); continue; }
    [[ "${mp:0:1}" == '/' ]] || { inval_form+=("${key}: ${item}"); continue; }

    BIND_MOUNT_MAP[${key}]="${volume},mp=${mp}"
    BIND_MOUNT_MAP[${key}]+=",mountoptions=noatime,replicate=0,backup=0"
  done

  [[ ${#inval_form[@]} -lt 1 ]] || trap_fatal --decore $? "
    Invalid format
  " "$(printf -- '* %s\n' "${inval_form}")"
}

if [[ " pre-start " == *" ${PHASE} "* ]]; then
  ${DEVMODE} && {
    BIND_MOUNT_MAP=()
  } || {
    prepare_bind_mount_map
  }

  for i in "${!BIND_MOUNT_MAP[@]}"; do
    MAIN_CONF_MAP["${i}"]="${BIND_MOUNT_MAP[${i}]}"
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
          LXC_USER=bug1 \
          LXC_UID=1000 \
          LXC_GROUP=bug1 \
          LXC_GID=1000 \
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
  pve_conf_rm_keys "${LXC_CONF}" "${!BIND_MOUNT_MAP[@]}" \
  | tee -- "${LXC_CONFFILE}" >/dev/null 2>&1 || {
    log_warn "Can't override: ${LXC_CONFFILE}"
  }
fi
