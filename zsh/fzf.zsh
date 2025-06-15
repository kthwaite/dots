# Enhanced fzf integration for better navigation and search

# Only proceed if fzf is available
if ! command -v fzf >/dev/null 2>&1; then
    return 0
fi

# fzf configuration
export FZF_DEFAULT_OPTS="
    --height 40%
    --layout=reverse
    --border
    --info=inline
    --preview-window=:hidden
    --preview '([[ -f {} ]] && (bat --style=numbers --color=always {} || cat {})) || ([[ -d {} ]] && (tree -C {} | head -200))'
    --color='hl:148,hl+:154,pointer:032,marker:010,bg+:237,gutter:008'
    --prompt='∼ '
    --pointer='▶'
    --marker='✓'
    --bind='?:toggle-preview'
    --bind='ctrl-a:select-all'
    --bind='ctrl-y:execute-silent(echo {+} | pbcopy)'
    --bind='ctrl-e:execute(echo {+} | xargs -o vim)'
    --bind='ctrl-v:execute(code {+})'
"

# Use fd for file search if available
if command -v fd >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
    export FZF_ALT_C_COMMAND='fd --type d --hidden --follow --exclude .git'
elif command -v rg >/dev/null 2>&1; then
    export FZF_DEFAULT_COMMAND='rg --files --hidden --follow --glob "!.git/*"'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
fi

# Enhanced history search with fzf
fh() {
    print -z $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac --query="$*" | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# Enhanced directory navigation
fd_nav() {
    local dir
    dir=$(find ${1:-.} -path '*/\.*' -prune -o -type d -print 2> /dev/null | fzf +m) &&
    cd "$dir"
}

# Jump to frequently used directories
cdf() {
    local dir
    dir=$(find ~ -type d -name .git -prune -o -type d -print 2>/dev/null | head -100 | fzf +m) && cd "$dir"
}

# Find and edit files
vf() {
    local files
    IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
    [[ -n "$files" ]] && ${EDITOR:-vim} "${files[@]}"
}

# Find and open with default application
of() {
    local files
    IFS=$'\n' files=($(fzf-tmux --query="$1" --multi --select-1 --exit-0))
    [[ -n "$files" ]] && open "${files[@]}"
}

# Kill processes with fzf
fkill() {
    local pid
    if [ "$UID" != "0" ]; then
        pid=$(ps -f -u $UID | sed 1d | fzf -m | awk '{print $2}')
    else
        pid=$(ps -ef | sed 1d | fzf -m | awk '{print $2}')
    fi

    if [ "x$pid" != "x" ]
    then
        echo $pid | xargs kill -${1:-9}
    fi
}

# Search in command history and execute
fhx() {
    eval $( ([ -n "$ZSH_NAME" ] && fc -l 1 || history) | fzf +s --tac | sed -E 's/ *[0-9]*\*? *//' | sed -E 's/\\/\\\\/g')
}

# Git branch selector
fgb() {
    local branches branch
    branches=$(git --no-pager branch -vv) &&
    branch=$(echo "$branches" | fzf +m) &&
    git checkout $(echo "$branch" | awk '{print $1}' | sed "s/.* //")
}

# Git log browser
fgl() {
    git log --graph --color=always \
        --format="%C(auto)%h%d %s %C(black)%C(bold)%cr" "$@" |
    fzf --ansi --no-sort --reverse --tiebreak=index --bind=ctrl-s:toggle-sort \
        --bind "ctrl-m:execute:
                (grep -o '[a-f0-9]\{7\}' | head -1 |
                xargs -I % sh -c 'git show --color=always % | less -R') << 'FZF-EOF'
                {}
FZF-EOF"
}

# Search file contents
rga-fzf() {
    RG_PREFIX="rga --files-with-matches"
    local file
    file="$(
        FZF_DEFAULT_COMMAND="$RG_PREFIX '$1'" \
            fzf --sort --preview="[[ ! -z {} ]] && rga --pretty --context 5 {q} {}" \
                --phony -q "$1" \
                --bind "change:reload:$RG_PREFIX {q}" \
                --preview-window="70%:wrap"
    )" &&
    echo "opening $file" &&
    open "$file"
}

# Keybindings for fzf functions
bindkey -s '^p' 'fh^M'           # Ctrl-P for history
bindkey -s '^f' 'fd_nav^M'       # Ctrl-F for directory navigation
bindkey -s '^g' 'fgb^M'          # Ctrl-G for git branch selection

# Load fzf key bindings if available
if [[ -f ~/.fzf.zsh ]]; then
    source ~/.fzf.zsh
elif [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
elif [[ -f /opt/homebrew/opt/fzf/shell/key-bindings.zsh ]]; then
    source /opt/homebrew/opt/fzf/shell/key-bindings.zsh
fi

# Load fzf completion if available
if [[ -f ~/.fzf/shell/completion.zsh ]]; then
    source ~/.fzf/shell/completion.zsh
elif [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
elif [[ -f /opt/homebrew/opt/fzf/shell/completion.zsh ]]; then
    source /opt/homebrew/opt/fzf/shell/completion.zsh
fi
