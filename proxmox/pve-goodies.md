# <a id="top"></a> PVE goodies

* [Back](readme.md)
---
* [fzf](#fzf)
---

## fzf

**Install**:
```sh
# https://github.com/junegunn/fzf/releases
FZF_VERSION="0.35.1"
FZF_HOME=/opt/junegunn/fzf

# Install binary
mkdir -p "${FZF_HOME}/bin"
wget -qO- https://github.com/junegunn/fzf/releases/download/${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz | tar -xzf - -C "${FZF_HOME}/bin"
chmod 0755 "${FZF_HOME}/bin/fzf"

# Install source code
FZF_SRC_TMP="$(mktemp -d)"
mkdir -p "${FZF_HOME}/shell"
wget -qO- https://github.com/junegunn/fzf/archive/refs/tags/${FZF_VERSION}.tar.gz | tar -xzf - -C "${FZF_SRC_TMP}"
/bin/cp -f "${FZF_SRC_TMP}"/*/bin/* "${FZF_HOME}/bin"
/bin/cp -f "${FZF_SRC_TMP}"/*/shell/* "${FZF_HOME}/shell"
```

Hook to `~/.bashrc`
```sh
echo "
  [[ \":\${PATH}\:\" == *\":${FZF_HOME}/bin:\"* ]] || PATH+=\"\${PATH:+:}${FZF_HOME}/bin\"

  # Auto-completion
  # ---------------
  [[ \$- == *i* ]] && . '${FZF_HOME}/shell/completion.bash' 2> /dev/null

  # Key bindings
  # ------------
  . '${FZF_HOME}/shell/key-bindings.bash' 2> /dev/null

  __iife() {
    local -a opts

    opts+=(--height '100%' --border --history-size 999999)
    # https://github.com/junegunn/fzf/issues/577#issuecomment-225953097
    opts+=(--preview \"'echo {}'\" --bind ctrl-p:toggle-preview)
    opts+=(--preview-window down:50%:wrap)

    [[ -n \"\${FZF_DEFAULT_OPTS}\" ]] && export FZF_DEFAULT_OPTS
    FZF_DEFAULT_OPTS=\"\${FZF_DEFAULT_OPTS:+ }\$(printf -- '%s ' \"\${opts[@]}\" | sed -E 's/\s+$//')\"
  }; __iife; unset __iife
" > "${FZF_HOME}/source.bash"
grep -qFx ". '${FZF_HOME}/source.bash'" ~/.bashrc || {
  echo ". '${FZF_HOME}/source.bash'" >> ~/.bashrc
}
```

Log out and log in again.

[To top]

[To top]: #top
