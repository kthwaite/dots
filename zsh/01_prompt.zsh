if [[ -x "$(command -v starship)" ]]; then
    eval "$(starship init zsh)"
else
    setopt PROMPT_SUBST

    autoload -Uz vcs_info
    zstyle ':vcs_info:*' enable git
    zstyle ':vcs_info:git*' formats "%b %m%u%c "

    precmd() {
        vcs_info
    }

    rprompt_git() {
        if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            print "%B%F{2}${vcs_info_msg_0_}%f%b"
        fi
    }

    prompt_path_part() {
        local -r current_dir="${PWD/#$HOME/~}"
        if [[ "$current_dir" == (#m)[/~] ]]; then
            print "$current_dir"
        else
            # `s:string:` splits on `string`
            # `@` applies this to elements of an array
            # `j:string:` joins them back together again, using `string` as a separator
            # M includes the matched portion in the result
            # :h takes the directory part of the path, dropping the last item
            # :t takes the last part of the path
            print "${${${${(@j:/:M)${(@s:/:)current_dir}##.#?}:h}%/}//\%/%%}/${${current_dir:t}//\%/%%}"
        fi
    }

    build_prompt() {
        if [[ -n $VIRTUAL_ENV ]]; then
            # prompt expansion, no newline
            print -Pn "$(basename $VIRTUAL_ENV) "
        fi
        PROMPT='%F{4}$(prompt_path_part) %B%F{2}»%f%b '

        # Set up non-zero return value display
        # Set up git branch display
        # ↑
        RPROMPT='%(?..%F{1}%Bx %b%?%f) $(rprompt_git)'
    }

    build_prompt
fi
