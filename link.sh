#!/usr/bin/env zsh
#
# Links config files to their respective directories / destinations

set -o errexit
set -o pipefail
set -o nounset

# array of source, target pairs
declare -A pairs=(
    ["./nvim"]="$HOME/.config/nvim"
    ["./wezterm"]="$HOME/.config/wezterm"
    ["./gitconfig"]="$HOME/.gitconfig"
    ["./ruff/ruff.toml"]="$HOME/.ruff.toml"
    ["./zellij"]="$HOME/.config/zellij"
)
# array of name, source pairs
declare -A names=(
    ["nvim"]="./nvim"
    ["wezterm"]="./wezterm"
    ["gitconfig"]="./gitconfig"
    ["ruff"]="./ruff/ruff.toml"
    ["zellij"]="./zellij"
)

# check if a directory is linked
# @param src: source directory
# @param dest: destination directory
function is_dir_linked() {
    local src=$1
    local dest=$2
    local src_real
    local dest_real
    if [[ -L $dest ]]; then
        src_real=$(readlink -f "$src")
        dest_real=$(readlink -f "$dest")
        if [[ $src_real == "$dest_real" ]]; then
            return 0
        fi
    fi
    return 1
}

# link a directory to another
# @param src: source directory
# @param dest: destination directory
function link() {
    local src=$1
    local dest=$2
    if [[ -d $dest ]]; then
        if is_dir_linked "$src" "$dest"; then
            echo "Already linked $src to $dest"
        else
            echo "Linking $src to $dest"
            ln -s "$src" "$dest"
        fi
    else
        echo "Destination $dest does not exist"
    fi
}


# show status of all sources
function cmd_status() {
    # ANSI green escape sequence
    local green="\033[0;32m"
    # ANSI red escape sequence
    local red="\033[0;31m"
    # ANSI reset escape sequence
    local reset="\033[0m"
    for src dest in "${(@kv)pairs}"; do
        if is_dir_linked "$src" "$dest"; then
            echo "${green}$src -> $dest${reset}"
        else
            echo "${red}$src -> $dest${reset}"
        fi
    done
}

function link_all() {

    for pair in "${pairs[@]}"; do
        local src=${pair[0]}
        local dest=${pair[1]}
        link "$src" "$dest"
    done
}

# if argument is provided, link that source; otherwise, link all sources
# if --dry-run is provided, show what would be done
function cmd_link() {
    if [[ $# -eq 1 ]]; then
        local name=$1
        shift
        if [[ -z ${names[$name]} ]]; then
            echo "Invalid name: $name"
            exit 1
        fi
        local dry_run=0
        case $1 in
            --dry-run)
                dry_run=1
                shift
                ;;
            *)
                echo "Invalid argument: $1"
                exit 1
                ;;
        esac
        local src=${names[$name]}
        local dest=${pairs[$src]}
        if [[ $dry_run -eq 1 ]]; then
            echo "Would link $src to $dest"
        else
            link "$src" "$dest"
        fi
    else
        link_all
    fi
}

# unlink all sources
function cmd_unlink_all() {
    for pair in "${pairs[@]}"; do
        local src=${pair[0]}
        local dest=${pair[1]}
        echo "Unlinking $src from $dest"
        unlink "$src" "$dest"
    done
}

# main entrypoint
# subcommands: status, link, unlink
if [[ $# -eq 0 ]]; then
    echo "Usage: $0 <subcommand>"
    echo "Subcommands: status, link, unlink"
    exit 1
fi

subcommand=$1
shift

case $subcommand in
    status)
        cmd_status
        ;;
    link)
        link ./nvim $HOME/.config/nvim
        ;;
    unlink)
        unlink $HOME/.config/nvim
        ;;
    *)
        echo "Invalid subcommand: $subcommand"
        exit 1
        ;;
esac
