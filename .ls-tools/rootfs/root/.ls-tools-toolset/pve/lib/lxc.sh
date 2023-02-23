# USAGE:
#   LXC_ID=<CONTAINER_ID, required> \
#     LXC_GROUP=<GROUP, required> \
#     LXC_GID=<GID, optional> \
#     lxc_ensure_group
lxc_ensure_group() {
  declare -a cmd=(groupadd)

  [[ -n "${LXC_GID}" ]] && cmd+=(-g "'${LXC_GID}'")
  cmd+=("'${LXC_GROUP}'")

  lxc-attach "${LXC_ID}" -- bash -c "
    id -g '${LXC_GROUP}' &>/dev/null || $(printf -- '%s ' "${cmd[@]}") 2>/dev/null
  " || log_warn "Can't create group ${group}"
}

# USAGE:
#   LXC_ID=<CONTAINER_ID, required> \
#     LXC_USER=<USER, required> \
#     LXC_UID=<UID, optional> \
#     LXC_GROUP=<GROUP, optional, must be created in advance> \
#     LXC_HOME=<HOMEDIR, optional> \
#     LXC_SUDO=<bool, optional, defaults to true> \
#     LXC_PASS=<PASSWORD, optional> \
#     lxc_ensure_user
lxc_ensure_user() {
  declare -a cmd=(useradd -m -s /bin/bash)

  [[ -n "${LXC_UID}" ]] && cmd+=(-u "'${LXC_UID}'")
  [[ -n "${LXC_GROUP}" ]] && cmd+=(-g "'${LXC_GROUP}'")
  [[ -n "${LXC_HOME}" ]] && cmd+=(-d "'${LXC_HOME}'")
  ${LXC_SUDO:-true} && cmd+=(-G sudo)
  [[ -n "${LXC_PASS}" ]] && cmd+=(-p "'${LXC_PASS}'")
  cmd+=("'${LXC_USER}'")

  lxc-attach "${LXC_ID}" -- bash -c "
    id -u '${LXC_USER}' &>/dev/null || $(printf -- '%s ' "${cmd[@]}") 2>/dev/null
  " \
  && lxc-attach "${ID}" -- bash -c "
    rm -rf /tmp/skel &>/dev/null
    cp -r /etc/skel /tmp
    chown -R \$(id -u '${LXC_USER}'):\$(id -g '${LXC_USER}') /tmp/skel
    # do not overwrite existing files (-n)
    cp -nr /tmp/skel/. ~${LXC_USER} &>/dev/null
    chown \$(id -u '${LXC_USER}'):\$(id -g '${LXC_USER}') ~${LXC_USER} &>/dev/null
    :
  " || log_warn "Can't create user ${user}"
}

# USAGE:
#   LXC_ID=<CONTAINER_ID, required> \
#     LXC_USER=<USER, required, must exist> \
#     lxc_ensure_user PUBKEY_PATH
lxc_ensure_ssh_pubkey() {
  local host_path="${1}"
  local pubkey

  pubkey="$(cat "${host_path}" 2>/dev/null)" || {
    log_warn "Can't read pubkey, skipping pubkey deployment."
    return
  } && lxc-attach "${LXC_ID}" -- bash -c "
    mkdir -p ~${LXC_USER}/.ssh \\
    && touch ~${LXC_USER}/.ssh/authorized_keys \\
    && chown -R \$(id -u '${LXC_USER}'):\$(id -g '${LXC_USER}') ~${LXC_USER}/.ssh \\
    && {
      grep -qFx '${pubkey}' ~${LXC_USER}/.ssh/authorized_keys || echo '${pubkey}' \\
        | tee -a -- ~${LXC_USER}/.ssh/authorized_keys >/dev/null
    }
  " || log_warn "Can't deploy public key"
}
