#!/usr/bin/env zsh
#
# Links config files to their respective directories / destinations

set -o errexit
set -o pipefail
set -o nounset

# Dry-run mode flag
DRY_RUN=0

## Associative array of source -> destination pairs
declare -A pairs=(
    ["./nvim"]="$HOME/.config/nvim"
    ["./wezterm"]="$HOME/.config/wezterm"
    ["./gitconfig"]="$HOME/.gitconfig"
    ["./ruff/ruff.toml"]="$HOME/.ruff.toml"
    ["./zellij"]="$HOME/.config/zellij"
)

## Associative array of names -> source pairs
declare -A names=(
    ["nvim"]="./nvim"
    ["wezterm"]="./wezterm"
    ["gitconfig"]="./gitconfig"
    ["ruff"]="./ruff/ruff.toml"
    ["zellij"]="./zellij"
)

function realpath_fallback() {
    perl -MCwd -e 'print Cwd::abs_path(shift)' "$1"
}


# check if a directory is linked
# @param src: source directory
# @param dest: destination directory
function is_linked() {
    local src=$1
    local dest=$2
    if [[ -L $dest ]]; then
        local src_real dest_real
        src_real=$(realpath_fallback "$src")
        dest_real=$(realpath_fallback "$dest")
        if [[ "$src_real" == "$dest_real" ]]; then
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
    local dest_dir
    dest_dir=$(dirname "$dest")
    if [[ ! -d $dest_dir ]]; then
        echo "Parent directory $dest_dir does not exist"
        return 1
    fi
    if [[ -e $dest ]]; then
        if is_linked "$src" "$dest"; then
            echo "Already linked $src to $dest"
            return 0
        else
            echo "Destination $dest exists and is not the expected symlink"
            return 1
        fi
    fi
    echo "Linking $src to $dest"
    ln -s "$src" "$dest"
}


# show status of all sources
function cmd_status() {
    local green="\033[0;32m"
    local red="\033[0;31m"
    local reset="\033[0m"
    for src dest in "${(@kv)pairs}"; do
        if is_linked "$src" "$dest"; then
            echo "${green}$src -> $dest${reset}"
        else
            echo "${red}$src -> $dest${reset}"
        fi
    done
}


function link_all() {
    for src dest in "${(@kv)pairs}"; do
        link "$src" "$dest"
    done
}

# if argument is provided, link that source; otherwise, link all sources
# if --dry-run is provided, show what would be done
function cmd_link() {
    local name=""
    while [[ $# -gt 0 ]]; do
        case $1 in
            --dry-run)
                DRY_RUN=1
                ;;
            *)
                name=$1
                ;;
        esac
        shift
    done

    if [[ -n $name ]]; then
        if [[ -z ${names[$name]:-} ]]; then
            echo "Invalid name: $name"
            exit 1
        fi
        local src=${names[$name]}
        local dest=${pairs[$src]}
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "Would link $src to $dest"
        else
            link "$src" "$dest"
        fi
    else
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "Dry-run mode: would link all dotfiles"
        else
            link_all
        fi
    fi
}

function unlink_link() {
    local dest=$1
    if [[ -L $dest ]]; then
        if [[ $DRY_RUN -eq 1 ]]; then
            echo "Would remove symlink at $dest"
        else
            echo "Removing symlink at $dest"
            rm "$dest"
        fi
    else
        echo "No symlink found at $dest"
    fi
}

function cmd_unlink_all() {
    for src dest in "${(@kv)pairs}"; do
        echo "Unlinking $src from $dest"
        unlink_link "$dest"
    done
}

# main entrypoint
# subcommands: status, link, unlink
function usage() {
    echo "Usage: $0 <subcommand> [options]"
    echo "Subcommands:"
    echo "  status                   Show status of dotfile symlinks"
    echo "  link [name] [--dry-run]    Link a specific dotfile (or all if no name given)"
    echo "  unlink [name]            Unlink a specific dotfile (or all if no name given)"
    exit 1
}

if [[ $# -eq 0 ]]; then
    usage
fi

subcommand=$1
shift

case $subcommand in
    status)
        cmd_status
        ;;
    link)
        cmd_link "$@"
        ;;
    unlink)
local name=""
        while [[ $# -gt 0 ]]; do
            case $1 in
                --dry-run)
                    DRY_RUN=1
                    ;;
                *)
                    name=$1
                    ;;
            esac
            shift
        done

        if [[ -n $name ]]; then
            if [[ -z ${names[$name]:-} ]]; then
                echo "Invalid name: $name"
                exit 1
            fi
            local src=${names[$name]}
            local dest=${pairs[$src]}
            unlink_link "$dest"
        else
            cmd_unlink_all
        fi
        ;;
    *)
        echo "Invalid subcommand: $subcommand"
        usage
        ;;
esac
