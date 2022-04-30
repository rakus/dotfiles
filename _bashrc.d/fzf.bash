
if [ -e "/usr/share/fzf/shell/key-bindings.bash" ]; then

    FZF_ALT_C_COMMAND="cat $HOME/.qc/home.index"
    FZF_ALT_UPPER_C_COMMAND="cat $HOME/.qc/home.index.hidden"

    source /usr/share/fzf/shell/key-bindings.bash


    __fzf_hidden_cd__() {
        local cmd dir
        cmd="${FZF_ALT_UPPER_C_COMMAND:-"cat $HOME/.qc/home.index.hidden"}"
        dir=$(eval "$cmd" | FZF_DEFAULT_OPTS="--height ${FZF_TMUX_HEIGHT:-40%} --reverse --bind=ctrl-z:ignore $FZF_DEFAULT_OPTS $FZF_ALT_C_OPTS" $(__fzfcmd) +m) && printf 'cd -- %q' "$dir"
    }

    # ALT-C - cd into the selected directory
    bind -m emacs-standard '"\eC": " \C-b\C-k \C-u`__fzf_hidden_cd__`\e\C-e\er\C-m\C-y\C-h\e \C-y\ey\C-x\C-x\C-d"'
    bind -m vi-command '"\eC": "\C-z\eC\C-z"'
    bind -m vi-insert '"\eC": "\C-z\eC\C-z"'


fi

# vim:ft=sh
