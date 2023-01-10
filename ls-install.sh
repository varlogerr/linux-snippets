#!/usr/bin/env bash

fail_with_msg() {
  echo "${1}" >&2
  exit 1
}

PKG_URL=https://github.com/varlogerr/linux-snippets/archive/refs/heads/master.tar.gz
TMP_DIR="$(set -x; mktemp --directory --suffix .ls)" || {
  fail_with_msg "Can't create temporary directory"
}
PKG_ARCHIVE_PATH="${TMP_DIR}/ls.tar.gz"

declare -a dl_cmd

if curl --version &>/dev/null; then
  dl_cmd=(curl -f -s -L -o "${PKG_ARCHIVE_PATH}" "${PKG_URL}")
elif wget --version &>/dev/null; then
  dl_cmd=(wget -q -L -O "${PKG_ARCHIVE_PATH}" "${PKG_URL}")
else
  fail_with_msg "curl or wget is required"
fi

(set -x; "${dl_cmd[@]}" &>/dev/null) || fail_with_msg "Can't download tool package"

cd "${TMP_DIR}" &>/dev/null || fail_with_msg "Can't \`cd ${TMP_DIR}\`"

(set -x; tar -xf "${PKG_ARCHIVE_PATH}") || fail_with_msg "Can't unarchive ${PKG_ARCHIVE_PATH}"

rm "${PKG_ARCHIVE_PATH}" &>/dev/null
