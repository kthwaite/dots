# Enhanced directory navigation for power users

# --- Zoxide integration (if available) ---
if [[ -x "$(command -v zoxide)" ]]; then
    eval "$(zoxide init zsh)"
    alias j='z'  # Short alias for muscle memory
    alias ji='zi'  # Interactive selection
fi

# --- Directory bookmarks ---
typeset -A dir_bookmarks
export BOOKMARKS_FILE="${HOME}/.zsh_bookmarks"

# Load bookmarks from file
function _load_bookmarks() {
    [[ -f "$BOOKMARKS_FILE" ]] && source "$BOOKMARKS_FILE"
}

# Save bookmarks to file
function _save_bookmarks() {
    {
        echo "# ZSH directory bookmarks"
        echo "typeset -A dir_bookmarks"
        for key value in ${(kv)dir_bookmarks}; do
            echo "dir_bookmarks[$key]='$value'"
        done
    } > "$BOOKMARKS_FILE"
}

# Bookmark current directory
function bookmark() {
    local name="${1:-$(basename $PWD)}"
    dir_bookmarks[$name]="$PWD"
    _save_bookmarks
    echo "Bookmarked '$PWD' as '$name'"
}

# Go to bookmark
function goto() {
    _load_bookmarks
    if [[ -z "$1" ]]; then
        # List bookmarks
        for key value in ${(kv)dir_bookmarks}; do
            echo "$key -> $value"
        done
    elif [[ -n "${dir_bookmarks[$1]}" ]]; then
        cd "${dir_bookmarks[$1]}"
    else
        echo "Bookmark '$1' not found"
        return 1
    fi
}

# Remove bookmark
function unbookmark() {
    _load_bookmarks
    if [[ -n "${dir_bookmarks[$1]}" ]]; then
        unset "dir_bookmarks[$1]"
        _save_bookmarks
        echo "Removed bookmark '$1'"
    else
        echo "Bookmark '$1' not found"
        return 1
    fi
}

# Interactive bookmark selection with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function gotof() {
        _load_bookmarks
        local selected=$(
            for key value in ${(kv)dir_bookmarks}; do
                echo "$key -> $value"
            done | fzf --preview 'ls -la {3}'
        )
        if [[ -n "$selected" ]]; then
            local bookmark=$(echo "$selected" | cut -d' ' -f1)
            goto "$bookmark"
        fi
    }
fi

# --- Recent directories ---
export RECENT_DIRS_FILE="${HOME}/.zsh_recent_dirs"
export RECENT_DIRS_MAX=50

# Track directory changes
function _track_pwd() {
    # Don't track home directory
    [[ "$PWD" == "$HOME" ]] && return
    
    # Update recent dirs
    if [[ -f "$RECENT_DIRS_FILE" ]]; then
        # Remove current dir if already present and add to top
        grep -v "^${PWD}$" "$RECENT_DIRS_FILE" > "${RECENT_DIRS_FILE}.tmp"
        echo "$PWD" > "$RECENT_DIRS_FILE"
        head -n $((RECENT_DIRS_MAX - 1)) "${RECENT_DIRS_FILE}.tmp" >> "$RECENT_DIRS_FILE"
        rm -f "${RECENT_DIRS_FILE}.tmp"
    else
        echo "$PWD" > "$RECENT_DIRS_FILE"
    fi
}

# Add to directory change hooks
add-zsh-hook chpwd _track_pwd

# Go to recent directory
function recent() {
    if [[ ! -f "$RECENT_DIRS_FILE" ]]; then
        echo "No recent directories"
        return 1
    fi
    
    if [[ -x "$(command -v fzf)" ]]; then
        local dir=$(cat "$RECENT_DIRS_FILE" | fzf --preview 'ls -la {}')
        [[ -n "$dir" ]] && cd "$dir"
    else
        cat -n "$RECENT_DIRS_FILE" | head -20
    fi
}

# --- Quick navigation helpers ---

# Go to git root
function cdg() {
    local root=$(git rev-parse --show-toplevel 2>/dev/null)
    if [[ -n "$root" ]]; then
        cd "$root"
    else
        echo "Not in a git repository"
        return 1
    fi
}

# Go up N directories
function up() {
    local count="${1:-1}"
    local path=""
    for i in $(seq 1 $count); do
        path="../$path"
    done
    cd "$path"
}

# Smart cd - if file, cd to its directory
function scd() {
    if [[ -f "$1" ]]; then
        cd "$(dirname "$1")"
    else
        cd "$1"
    fi
}

# --- Project navigation ---

# Common project directories (customize these)
export PROJECT_DIRS=(
    "$HOME/projects"
    "$HOME/work"
    "$HOME/code"
    "$HOME/dev"
    "$HOME/src"
)

# Go to project
function proj() {
    if [[ -x "$(command -v fzf)" ]]; then
        local project=$(
            for dir in $PROJECT_DIRS; do
                [[ -d "$dir" ]] && find "$dir" -maxdepth 2 -type d -name ".git" 2>/dev/null | xargs dirname
            done | sort -u | fzf --preview 'ls -la {}'
        )
        [[ -n "$project" ]] && cd "$project"
    else
        echo "fzf required for project navigation"
        return 1
    fi
}

# --- Directory stack enhancements ---

# Show directory stack
alias d='dirs -v'

# Quick jumps using directory stack
for i in {1..9}; do
    alias "$i"="cd +$i"
done

# Push current directory and go somewhere
function pushto() {
    pushd "$1" > /dev/null
}

# --- Useful aliases ---

alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias .....='cd ../../../..'
alias -- -='cd -'  # Go to previous directory

# Create and enter directory
function mkcd() {
    mkdir -p "$1" && cd "$1"
}

# --- Fuzzy path jumping ---
if [[ -x "$(command -v fzf)" ]]; then
    # Interactive directory search from current location
    function fcd() {
        local dir=$(find . -type d -not -path '*/\.*' 2>/dev/null | fzf --preview 'ls -la {}')
        [[ -n "$dir" ]] && cd "$dir"
    }
    
    # Interactive directory search from home
    function fcda() {
        local dir=$(find ~ -type d -not -path '*/\.*' 2>/dev/null | fzf --preview 'ls -la {}')
        [[ -n "$dir" ]] && cd "$dir"
    }
fi

# Load bookmarks on shell start
_load_bookmarks