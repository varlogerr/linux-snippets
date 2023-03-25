{ # GLOBALS
  declare -A OPTS
}

{ # FUNCTIONS
  # Trap `--genconf` flag
  # USAGE:
  #   opts_trap_genconf [OPTION...] \
  #     [--genconf] [CONFFILE]
  # RC:
  # * 0 - genconf flag is detected
  # * 1 - no genconf flag
  # GLOBALS:
  #   OPTS[genconf]
  #     (boolean) genconf flag is detected
  #   OPTS[conffile]
  #     (string) conffile path
  opts_trap_genconf() {
    local endopts=false
    local rc=1

    OPTS+=(
      [genconf]=false
      # [conffile]=
    )

    local arg; while :; do
      [[ -n "${1+x}" ]] || break
      ${endopts} && arg='*' || arg="${1}"

      case "${arg}" in
        --        ) endopts=true ;;
        --genconf ) OPTS[genconf]=true; rc=0 ;;
        *         ) OPTS[conffile]="${1}" ;;
      esac

      shift
    done

    return ${rc}
  }
}
