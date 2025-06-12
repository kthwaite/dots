# File manipulation shortcuts for power users

# --- Batch operations ---

# Batch rename files
function rename_batch() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: rename_batch <pattern> <replacement> [files...]"
        echo "Example: rename_batch 'IMG' 'Photo' *.jpg"
        return 1
    fi
    
    local pattern="$1"
    local replacement="$2"
    shift 2
    
    # If no files specified, use current directory
    local files=("$@")
    [[ ${#files[@]} -eq 0 ]] && files=(*)
    
    for file in "${files[@]}"; do
        if [[ -e "$file" ]]; then
            local new_name="${file//$pattern/$replacement}"
            if [[ "$file" != "$new_name" ]]; then
                echo "$file -> $new_name"
                mv -i "$file" "$new_name"
            fi
        fi
    done
}

# Rename files to lowercase
function lowercase_files() {
    for file in "$@"; do
        [[ -f "$file" ]] || continue
        local new_name=$(echo "$file" | tr '[:upper:]' '[:lower:]')
        [[ "$file" != "$new_name" ]] && mv -i "$file" "$new_name"
    done
}

# Add prefix/suffix to files
function add_prefix() {
    local prefix="$1"
    shift
    for file in "$@"; do
        [[ -e "$file" ]] && mv -i "$file" "${prefix}${file}"
    done
}

function add_suffix() {
    local suffix="$1"
    shift
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            local base="${file%.*}"
            local ext="${file##*.}"
            if [[ "$base" == "$file" ]]; then
                # No extension
                mv -i "$file" "${file}${suffix}"
            else
                mv -i "$file" "${base}${suffix}.${ext}"
            fi
        fi
    done
}

# --- Safe file operations ---

# Move with progress bar (requires rsync)
function mvp() {
    if [[ -x "$(command -v rsync)" ]]; then
        rsync -ah --progress --remove-source-files "$@"
    else
        mv -v "$@"
    fi
}

# Copy with progress bar
function cpp() {
    if [[ -x "$(command -v rsync)" ]]; then
        rsync -ah --progress "$@"
    else
        cp -v "$@"
    fi
}

# Safe remove - moves to trash instead of deleting
if [[ "$OSTYPE" == "darwin"* ]] && [[ -x "$(command -v trash)" ]]; then
    alias rm='trash'
    alias del='/bin/rm'  # Real delete when needed
elif [[ -x "$(command -v gio)" ]]; then
    # Use gio trash on Linux with GNOME
    function rm() {
        gio trash "$@"
    }
    alias del='/bin/rm'
fi

# --- Quick backup ---

# Backup file with timestamp
function backup() {
    for file in "$@"; do
        if [[ -e "$file" ]]; then
            local timestamp=$(date +%Y%m%d_%H%M%S)
            cp -p "$file" "${file}.backup.${timestamp}"
            echo "Backed up: ${file} -> ${file}.backup.${timestamp}"
        fi
    done
}

# Quick backup with .bak extension
function bak() {
    for file in "$@"; do
        [[ -e "$file" ]] && cp -p "$file" "${file}.bak"
    done
}

# --- Archive operations ---

# Smart extract - handles multiple archive types
function extract() {
    for file in "$@"; do
        if [[ -f "$file" ]]; then
            case "$file" in
                *.tar.bz2|*.tbz2) tar xjf "$file" ;;
                *.tar.gz|*.tgz)   tar xzf "$file" ;;
                *.tar.xz)         tar xJf "$file" ;;
                *.tar.zst)        tar --zstd -xf "$file" ;;
                *.tar)            tar xf "$file" ;;
                *.bz2)            bunzip2 "$file" ;;
                *.gz)             gunzip "$file" ;;
                *.zip)            unzip "$file" ;;
                *.rar)            unrar x "$file" ;;
                *.7z)             7z x "$file" ;;
                *.xz)             unxz "$file" ;;
                *.Z)              uncompress "$file" ;;
                *)                echo "Unknown archive type: $file" ;;
            esac
        else
            echo "File not found: $file"
        fi
    done
}

# Create archive
function archive() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: archive <archive_name> <files...>"
        echo "Supported formats: .tar.gz, .tar.bz2, .tar.xz, .zip, .7z"
        return 1
    fi
    
    local archive="$1"
    shift
    
    case "$archive" in
        *.tar.gz|*.tgz)   tar czf "$archive" "$@" ;;
        *.tar.bz2|*.tbz2) tar cjf "$archive" "$@" ;;
        *.tar.xz)         tar cJf "$archive" "$@" ;;
        *.tar)            tar cf "$archive" "$@" ;;
        *.zip)            zip -r "$archive" "$@" ;;
        *.7z)             7z a "$archive" "$@" ;;
        *)                echo "Unknown archive format" && return 1 ;;
    esac
}

# --- File search ---

# Find files by name with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function ff() {
        local query="${1:-.}"
        find . -type f -iname "*${query}*" 2>/dev/null | fzf --preview 'file {}; echo; head -50 {}'
    }
    
    # Find and edit
    function fe() {
        local file=$(ff "$@")
        [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
    }
    
    # Find and cd to directory
    function fd() {
        local dir=$(find . -type d -iname "*${1:-}*" 2>/dev/null | fzf --preview 'ls -la {}')
        [[ -n "$dir" ]] && cd "$dir"
    }
fi

# Find large files
function large_files() {
    local size="${1:-100M}"
    local path="${2:-.}"
    find "$path" -type f -size +$size -exec ls -lh {} \; | sort -k5 -rh
}

# Find recently modified files
function recent_files() {
    local days="${1:-1}"
    local path="${2:-.}"
    find "$path" -type f -mtime -$days -ls | sort -k11 -r
}

# --- File content operations ---

# Replace text in multiple files
function replace_in_files() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: replace_in_files <search> <replace> [files...]"
        return 1
    fi
    
    local search="$1"
    local replace="$2"
    shift 2
    
    # Use remaining args as files, or find files if none specified
    local files=("$@")
    if [[ ${#files[@]} -eq 0 ]]; then
        files=($(find . -type f -not -path '*/\.*' 2>/dev/null))
    fi
    
    for file in "${files[@]}"; do
        if [[ -f "$file" ]] && grep -q "$search" "$file" 2>/dev/null; then
            echo "Updating: $file"
            if [[ "$OSTYPE" == "darwin"* ]]; then
                sed -i '' "s|$search|$replace|g" "$file"
            else
                sed -i "s|$search|$replace|g" "$file"
            fi
        fi
    done
}

# --- Temporary files ---

# Create and edit temporary file
function tmpfile() {
    local ext="${1:-txt}"
    local tmpfile=$(mktemp -t "tmp.XXXXXX.$ext")
    ${EDITOR:-vim} "$tmpfile"
    echo "$tmpfile"
}

# Create temporary directory and cd into it
function tmpdir() {
    local tmpdir=$(mktemp -d -t "tmp.XXXXXX")
    cd "$tmpdir"
    echo "Created and entered: $tmpdir"
}

# --- File comparison ---

# Visual diff with color
if [[ -x "$(command -v colordiff)" ]]; then
    alias diff='colordiff'
elif [[ -x "$(command -v git)" ]]; then
    function diff() {
        git diff --no-index --color "$@"
    }
fi

# Side-by-side diff
function diffsbs() {
    if [[ -x "$(command -v icdiff)" ]]; then
        icdiff "$@"
    elif [[ -x "$(command -v sdiff)" ]]; then
        sdiff -w $(tput cols) "$@"
    else
        diff -y "$@"
    fi
}

# --- Quick file creation ---

# Touch with directories
function touchp() {
    for file in "$@"; do
        mkdir -p "$(dirname "$file")"
        touch "$file"
    done
}

# Create executable script
function mkscript() {
    local file="${1:-script.sh}"
    cat > "$file" << 'EOF'
#!/usr/bin/env bash
set -euo pipefail

EOF
    chmod +x "$file"
    ${EDITOR:-vim} "$file"
}

# --- File permissions ---

# Make files executable
alias +x='chmod +x'
alias -x='chmod -x'

# Fix permissions recursively
function fix_perms() {
    local dir="${1:-.}"
    find "$dir" -type d -exec chmod 755 {} \;
    find "$dir" -type f -exec chmod 644 {} \;
}

# --- Disk usage ---

# Human-readable disk usage
alias duh='du -h --max-depth=1 | sort -h'
alias dus='du -s * | sort -n'

# Interactive disk usage with ncdu
if [[ -x "$(command -v ncdu)" ]]; then
    alias du='ncdu'
fi