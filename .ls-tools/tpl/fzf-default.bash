# Append fzf binaries directory to the PATH
# -----------------------------------------
[[ ":${PATH}:" == *":{{ bin_home }}:"* ]] || PATH+="${PATH:+:}{{ bin_home }}"

# Auto-completion
# ---------------
[[ $- == *i* ]] && . '{{ shell_home }}/completion.bash' &>/dev/null

# Key bindings
# ------------
. '{{ shell_home }}/key-bindings.bash' &>/dev/null

__iife_fzf() {
  local -a opts=(
    --height '100%' --border --history-size 999999
    # https://github.com/junegunn/fzf/issues/577#issuecomment-225953097
    --preview "'echo {}'" --bind ctrl-p:toggle-preview
    --preview-window down:50%:wrap
  )

  [[ -n "${FZF_DEFAULT_OPTS}" ]] && export FZF_DEFAULT_OPTS
  FZF_DEFAULT_OPTS+="${FZF_DEFAULT_OPTS:+ }$(printf -- '%s ' "${opts[@]}" | sed -E 's/\s+$//')"
}; __iife_fzf; unset __iife_fzf
