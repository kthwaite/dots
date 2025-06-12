# CMUS music player utilities

# Only load if cmus is available
if [[ -x "$(command -v cmus)" ]]; then

# Refresh cmus library
function refresh-cmus {
    if [[ -z $CMUS_LIBRARY ]]; then
        echo "CMUS_LIBRARY is not set"
        return
    fi
    cmus-remote -C clear
    cmus-remote -C "add $CMUS_LIBRARY"
    cmus-remote -C "update-cache --force"
}

# Control aliases
alias play='cmus-remote -p'
alias pause='cmus-remote -u'
alias next='cmus-remote -n'
alias prev='cmus-remote -r'
alias stop='cmus-remote -s'

# Volume control
function vol {
    if [[ -z "$1" ]]; then
        cmus-remote -Q | grep "vol_" | sed 's/set //'
    else
        cmus-remote -v "$1%"
    fi
}

# Now playing info
function np {
    if cmus-remote -Q &>/dev/null; then
        local status=$(cmus-remote -Q)
        local artist=$(echo "$status" | grep "tag artist" | cut -d' ' -f3-)
        local title=$(echo "$status" | grep "tag title" | cut -d' ' -f3-)
        local album=$(echo "$status" | grep "tag album" | cut -d' ' -f3-)
        local position=$(echo "$status" | grep "position" | cut -d' ' -f2)
        local duration=$(echo "$status" | grep "duration" | cut -d' ' -f2)
        
        # Format time
        local pos_min=$((position / 60))
        local pos_sec=$((position % 60))
        local dur_min=$((duration / 60))
        local dur_sec=$((duration % 60))
        
        printf "♫ %s - %s\n" "$artist" "$title"
        printf "  %s\n" "$album"
        printf "  %02d:%02d / %02d:%02d\n" "$pos_min" "$pos_sec" "$dur_min" "$dur_sec"
    else
        echo "cmus is not running"
    fi
}

# Search library
function cmus-search {
    if [[ -z "$1" ]]; then
        echo "Usage: cmus-search <query>"
        return 1
    fi
    cmus-remote -C "live-filter $*"
}

# Clear search filter
function cmus-clear {
    cmus-remote -C "live-filter"
}

# Add current directory to library
function cmus-add-dir {
    local dir="${1:-$(pwd)}"
    cmus-remote -C "add $dir"
}

# Save current playlist
function cmus-save-playlist {
    if [[ -z "$1" ]]; then
        echo "Usage: cmus-save-playlist <name>"
        return 1
    fi
    cmus-remote -C "save ~/.cmus/playlists/$1.pl"
}

# Load playlist
function cmus-load-playlist {
    if [[ -z "$1" ]]; then
        echo "Usage: cmus-load-playlist <name>"
        return 1
    fi
    cmus-remote -C "load ~/.cmus/playlists/$1.pl"
}

# List playlists
function cmus-playlists {
    ls ~/.cmus/playlists/*.pl 2>/dev/null | xargs -n1 basename | sed 's/\.pl$//'
}

# Toggle shuffle
function shuffle {
    cmus-remote -S
}

# Toggle repeat
function repeat {
    cmus-remote -R
}

# Seek forward/backward
function seek+ {
    cmus-remote -k +${1:-10}
}

function seek- {
    cmus-remote -k -${1:-10}
}

# Queue management
function queue {
    if [[ -z "$1" ]]; then
        # Show queue
        cmus-remote -Q | grep "file" | grep -A1000 "queue"
    else
        # Add to queue
        cmus-remote -q "$1"
    fi
}

# Clear queue
function queue-clear {
    cmus-remote -c -q
}

# Interactive playlist creation with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function cmus-fzf-add {
        find "${1:-.}" -type f \( -name "*.mp3" -o -name "*.flac" -o -name "*.ogg" -o -name "*.m4a" \) | \
            fzf -m --preview 'mediainfo {} | head -20' | \
            while read -r file; do
                cmus-remote -q "$file"
            done
    }
fi

# Start cmus with tmux integration
function cmus-tmux {
    if tmux has-session -t cmus 2>/dev/null; then
        tmux attach-session -t cmus
    else
        tmux new-session -d -s cmus cmus
        tmux attach-session -t cmus
    fi
}

fi # End of cmus check
