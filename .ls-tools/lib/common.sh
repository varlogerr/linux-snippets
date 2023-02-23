{ # FUNCTIONS
  common_dl_file_to_stdout() {
    local dl_url="${1}"
    declare -a dl_cmd

    if curl --version &>/dev/null; then
      dl_cmd=(curl -fsL -o - "${dl_url}")
    elif wget --version &>/dev/null; then
      dl_cmd=(wget -qL -O - "${dl_url}")
    else
      trap_fatal 1 "curl or wget is required"
    fi

    (set -x; "${dl_cmd[@]}" 2>/dev/null) || {
      trap_fatal 1 "Can't download url"
    }
  }

  common_dl_file_to() {
    local dl_url="${1}"
    local dest_path="${2}"
    declare -a dl_cmd

    if curl --version &>/dev/null; then
      dl_cmd=(curl -f -s -L -o "${dest_path}" "${dl_url}")
    elif wget --version &>/dev/null; then
      dl_cmd=(wget -q -L -O "${dest_path}" "${dl_url}")
    else
      echo "curl or wget is required"
      return 1
    fi

    (set -x; "${dl_cmd[@]}" &>/dev/null) || {
      echo "Can't download tool package"
      return 1
    }
  }
}
