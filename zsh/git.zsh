# list commits and changed files since a given date
function whatchanged() {
    if [[ $# -eq 0 ]]; then
        echo 'Usage: whatchanged [SINCE_DATE]'
        return
    fi
    git log --since=$1 --pretty=tformat: --numstat | awk '{added+=$1; removed+=$2} END {print "Added:", added, "Removed:", removed, "Total:", added + removed}'
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

alias gc="git clone"
alias gs="git status"
alias gd="git diff"
alias ga="git add"
alias gco="git checkout"
alias gcb="git checkout -b"
alias gcm="git commit -m"
