# Remove all non-data lines from conf text
# USAGE:
#   pve_conf_clean CONF_TXT # or from stdin
#   # => CLEAN_CONF_TXT
pve_conf_clean() {
  text_rmblank "${@}" | text_trim | grep -v '^#'
  return 0
}

# Get current state configuration, i.e. excluding snapshots
# USAGE:
#   pve_conf_head CONF_TXT # or from stdin
#   # => CONF_TXT_HEAD
pve_conf_head() {
  local conf_txt; conf_txt="${1-$(cat)}"
  local snapshot_line
  snapshot_line="$(grep -n '^\s*\[' <<< "${conf_txt}")" || {
    pve_conf_clean "${conf_txt}"
    return
  }

  local line_no="$(head -n 1 <<< "${snapshot_line}" | cut -d: -f 1)"
  head -n $(( line_no - 1 )) <<< "${conf_txt}" | pve_conf_clean
}

# Get snapshot sections, i.e. excluding current state
# USAGE:
#   pve_conf_tail CONF_TXT # or from stdin
#   # => CONF_TXT_TAIL
pve_conf_tail() {
  local conf_txt; conf_txt="${1-$(cat)}"
  local snapshot_line
  snapshot_line="$(grep -n '^\s*\[' <<< "${conf_txt}")" || return 0

  local line_no="$(head -n 1 <<< "${snapshot_line}" | cut -d: -f 1)"
  tail -n +${line_no} <<< "${conf_txt}"
}

# Parse `KEY: VALUE` or `KEY = VALUE` (spaces before and after `:` and `=`
# don't matter) lines from configuration txt to associative array
# USAGE:
#   declare -A map_ref; pve_conf_txt_to_map CONF_TXT map_ref
#   # `map_ref` contains [KEY]=VALUE pairs from CONF_TXT
# NOTES:
#   * only head of CONF_TXT will be processed
pve_conf_txt_to_map() {
  local conf__ctta="${1}"; conf__ctta="$(pve_conf_head "${conf__ctta}")"
  declare -n map__ctta="${2}"

  declare -a conf_arr__ctta
  [[ -n "${conf__ctta}" ]] && mapfile -t conf_arr__ctta <<< "${conf__ctta}"

  local key__ctta
  local val__ctta
  local line__ctta
  for line__ctta in "${conf_arr__ctta[@]}"; do
    key__ctta="$(sed 's/[:= ].*$//' <<< "${line__ctta}")"
    val__ctta="$(sed -e 's/^[^:=]\+[:=]\?\s*\(.*\)/\1/' <<< "${line__ctta}")"
    map__ctta["${key__ctta}"]="${val__ctta}"
  done
}

# Merge conf2_map into CONF1_TXT head. The result will
# be CONF1_TXT head + tail with merged conf2_map
# USAGE:
#   declare -A conf2_map=([one]=1 [two]=2)
#   pve_conf_merge CONF1_TXT conf2_map
#   # => MERGED_CONF_TXT
# NOTES:
#   * all the changes will be applied only to CONF1_TXT head
pve_conf_merge_map() {
  local conf1__pcmm="${1}"
  local -n conf2_map__pcmm="${2}"
  local conf1_head__pcmm; conf1_head__pcmm="$(pve_conf_head "${conf1__pcmm}")"
  local conf1_tail__pcmm; conf1_tail__pcmm="$(pve_conf_tail "${conf1__pcmm}")"

  declare -a conf2_map_keys__pcmm
  [[ ${#conf2_map__pcmm[@]} -gt 0 ]] && mapfile -t conf2_map_keys__pcmm <<< "$(
    printf -- '%s\n' "${!conf2_map__pcmm[@]}" | sort -n
  )"

  local val__pcmm
  local key_rex__pcmm
  local val_repl__pcmm
  local key__pcmm; for key__pcmm in "${conf2_map_keys__pcmm[@]}"; do
    val__pcmm="${conf2_map__pcmm["${key__pcmm}"]}"
    key_rex__pcmm="$(sed_quote_pattern "${key__pcmm}")"

    grep -q '^'"${key_rex__pcmm}"'\s*[:=]\?\s*' <<< "${conf1_head__pcmm}" || {
      conf1_head__pcmm+="${conf1_head__pcmm:+$'\n'}${key__pcmm}: ${val__pcmm}"
      continue
    }

    val_repl__pcmm="$(sed_quote_replace "${val__pcmm}")"
    conf1_head__pcmm="$(
      sed -e 's/^\('"${key_rex__pcmm}"'\)\s*[:=]\?.*/\1: '"${val_repl__pcmm}"'/' \
        <<< "${conf1_head__pcmm}"
    )"
  done

  printf -- '%s%s\n' \
    "$(pve_conf_clean "${conf1_head__pcmm}")" \
    "${conf1_tail__pcmm:+$'\n'$'\n'}${conf1_tail__pcmm}"
}

# Remove KEY from CONF_TXT
# USAGE:
#   pve_conf_rm_keys CONF_TXT KEY...
#   # => MERGED_CONF_TXT
# NOTES:
#   * all the changes will be applied only to CONF_TXT head
pve_conf_rm_keys() {
  local conf="${1}"
  local keys="${@:2}"
  local conf_head; conf_head="$(pve_conf_head "${conf}")"
  local conf_tail; conf_tail="$(pve_conf_tail "${conf}")"

  # ensure keys are new-line separated
  keys="$(sed 's/\s\+/\n/g' <<< "${keys[@]}")"
  key_rex="$(sed_quote_pattern "${keys}")"
  key_rex="$(sed -e 's/^/^/' -e 's/$/\\s*[:=]\\s*/' <<< "${key_rex}")"

  conf_head="$(grep -v -f <(echo "${key_rex}") <<< "${conf_head}")"
  printf -- '%s%s\n' "${conf_head}${conf_tail:+$'\n'$'\n'}" "${conf_tail}"
}
