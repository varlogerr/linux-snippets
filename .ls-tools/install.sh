#!/usr/bin/env bash

BRANCH=${1:-master}
DL_URL=https://github.com/varlogerr/linux-snippets/archive/refs/heads/${BRANCH}.tar.gz

SCRIPT_PATH="$(realpath -- "${BASH_SOURCE[0]}" 2>/dev/null)"
DEST_DIR="${HOME}/ls-tools"
[[ -f "${SCRIPT_PATH}" ]] && DEST_DIR="$(dirname -- "${SCRIPT_PATH}")"

log_framed() {
  local frame_char="${1}"
  local msg="${2}"

  grep -v '^\s*$' <<< "${msg}" | sed -e 's/^\s*//' -e 's/^\.//' \
  | {
    printf -- "${frame_char}"'%.0s' {1..10}; echo
    cat
    printf -- "${frame_char}"'%.0s' {1..10}; echo
  } >&2
}

log_info() {
  log_framed "~" "${1}"
}

fail_with_msg() {
  log_framed "!" "${1}"
  exit 1
}

declare -a DL_CMD
if curl --version &>/dev/null; then
  DL_CMD+=(curl -fsL -o -)
elif wget --version &>/dev/null; then
  DL_CMD+=(wget -qO-)
else
  fail_with_msg 'curl or wget is required'
fi
DL_CMD+=("${DL_URL}")

TMP_DIR="$(set -x; mktemp -d --suffix .ls 2>/dev/null)" || {
  fail_with_msg 'Error creating tmp directory'
}

(
  set -o pipefail
  set -x
  "${DL_CMD[@]}" 2>/dev/null | tar -xzf - -C "${TMP_DIR}" 2>/dev/null
) || {
  fail_with_msg 'Downloaded LS tools package is corrupted'
}

(set -x; mkdir -p "${DEST_DIR}" 2>/dev/null) || {
  fail_with_msg 'Error creating destination directory'
}

(set -x; cp -rf "${TMP_DIR}/linux-snippets-${BRANCH}/.ls-tools/." "${DEST_DIR}" 2>/dev/null) || {
  fail_with_msg 'Error installing LS tools to destination directory'
}

TMP_PARENT="$(dirname -- "${TMP_DIR}")"
TMP_BASE="$(basename -- "${TMP_DIR}")"

(set -x; cd "${TMP_PARENT}" && rm -rf "${TMP_BASE}")

__final_note_iife() {
  echo >&2
  log_info "
    USAGE:
  .  ${DEST_DIR}/bin/<TOOLNAME>
  .
    UPGRADE:
  .  ${DEST_DIR}/install.sh
  .
    ADD LS TOOLS TO PATH (OPTIONAL):
  .   echo \". '${DEST_DIR}/pathadd.bash'\" >> ~/.bashrc
  .   . ~/.bashrc
  "
}; __final_note_iife; unset __final_note_iife
