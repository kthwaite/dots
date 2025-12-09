# list commits and changed files since a given date
function whatchanged() {
    if [[ $# -eq 0 ]]; then
        echo 'Usage: whatchanged [SINCE_DATE]'
        return
    fi
    git whatchanged --since=$1 --numstat --oneline
}

# clone a subdirectory from a Git repository
clone_subdir() {
    if [[ "$1" == "-h" || "$1" == "--help" ]]; then
        echo "Usage: clone_subdir <repo_url> <subdir_path> [destination_dir]"
        echo ""
        echo "Clones only the specified subdirectory from a Git repository."
        echo ""
        echo "Arguments:"
        echo "  <repo_url>       URL of the Git repository"
        echo "  <subdir_path>    Path to the subdirectory within the repository"
        echo "  [destination_dir] Optional destination directory name"
        return
    fi

    if [[ $# -lt 2 ]]; then
        echo "Error: Missing arguments."
        clone_subdir --help
        return 1
    fi

    local repo_url="$1"
    local subdir="$2"
    local dest="${3:-$(basename "$repo_url" .git)}"

    git clone --no-checkout "$repo_url" "$dest" || return 1
    cd "$dest" || return 1
    git sparse-checkout init --cone
    git sparse-checkout set "$subdir"
    git checkout
}

# Enhanced git status with more information
gst() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not in a git repository"
        return 1
    fi
    
    echo "=== Git Status ==="
    git status --short --branch
    
    # Show stash count if any
    local stash_count=$(git stash list 2>/dev/null | wc -l)
    if [[ $stash_count -gt 0 ]]; then
        echo "📦 Stashes: $stash_count"
    fi
    
    # Show ahead/behind info
    local ahead_behind=$(git rev-list --left-right --count HEAD...@{upstream} 2>/dev/null)
    if [[ -n "$ahead_behind" ]]; then
        local ahead=$(echo "$ahead_behind" | cut -f1)
        local behind=$(echo "$ahead_behind" | cut -f2)
        if [[ $ahead -gt 0 ]] || [[ $behind -gt 0 ]]; then
            echo "🔄 Ahead: $ahead, Behind: $behind"
        fi
    fi
    
    # Show last commit
    echo "📝 Last commit:"
    git log -1 --oneline --color=always 2>/dev/null || echo "No commits yet"
}

# Quick git add and commit
gac() {
    if [[ -z "$1" ]]; then
        echo "Usage: gac <commit_message>"
        return 1
    fi
    git add -A && git commit -m "$1"
}

# Git branch management
gb() {
    case "$1" in
        "clean"|"cleanup")
            echo "Cleaning up merged branches..."
            git branch --merged | grep -v "\*\|main\|master\|develop" | xargs -n 1 git branch -d
            ;;
        "recent"|"r")
            echo "Recent branches:"
            git for-each-ref --sort=-committerdate refs/heads/ --format='%(HEAD) %(color:yellow)%(refname:short)%(color:reset) - %(color:red)%(objectname:short)%(color:reset) - %(contents:subject) - %(authorname) (%(color:green)%(committerdate:relative)%(color:reset))'
            ;;
        *)
            git branch "$@"
            ;;
    esac
}

# Quick git log with nice formatting
gl() {
    local count=${1:-10}
    git log --oneline --graph --decorate --color=always -n "$count"
}

# Git diff with word-level highlighting
gd() {
    if [[ "$1" == "--cached" ]] || [[ "$1" == "--staged" ]]; then
        git diff --cached --color-words "$@"
    else
        git diff --color-words "$@"
    fi
}

# Show git repository info
ginfo() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        echo "Not in a git repository"
        return 1
    fi
    
    echo "=== Repository Information ==="
    echo "Repository: $(basename $(git rev-parse --show-toplevel))"
    echo "Branch: $(git branch --show-current)"
    echo "Remote: $(git remote get-url origin 2>/dev/null || echo 'No remote')"
    echo "Root: $(git rev-parse --show-toplevel)"
    
    local tag=$(git describe --tags --abbrev=0 2>/dev/null)
    if [[ -n "$tag" ]]; then
        echo "Latest tag: $tag"
    fi
    
    echo ""
    echo "=== Statistics ==="
    echo "Total commits: $(git rev-list --all --count)"
    echo "Contributors: $(git shortlog -sn | wc -l)"
    echo "Files tracked: $(git ls-files | wc -l)"
}

# Git aliases for common operations
alias ga='git add'
alias gaa='git add -A'
alias gc='git commit'
alias gcm='git commit -m'
alias gco='git checkout'
alias gcb='git checkout -b'
alias gp='git push'
alias gpl='git pull'
alias gf='git fetch'
alias gs='gst'  # Use our enhanced status
alias glog='gl'
alias gdiff='gd'
alias gcl="git clone"
