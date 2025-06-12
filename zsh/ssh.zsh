# SSH and network utilities for power users

# --- SSH key management ---

# Generate SSH key with best practices
function ssh-keygen-best() {
    local email="${1:-$(git config --global user.email 2>/dev/null)}"
    local keyname="${2:-id_ed25519}"
    
    if [[ -z "$email" ]]; then
        echo "Usage: ssh-keygen-best <email> [keyname]"
        return 1
    fi
    
    ssh-keygen -t ed25519 -C "$email" -f "$HOME/.ssh/$keyname"
    echo "Generated key: $HOME/.ssh/$keyname"
    echo "Don't forget to add to ssh-agent and your Git hosting service!"
}

# Add SSH key to agent
function ssh-add-key() {
    local key="${1:-$HOME/.ssh/id_ed25519}"
    
    # Start ssh-agent if not running
    if ! ssh-add -l &>/dev/null; then
        eval "$(ssh-agent -s)"
    fi
    
    # Add key with macOS keychain support
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ssh-add --apple-use-keychain "$key"
    else
        ssh-add "$key"
    fi
}

# List SSH keys in agent
alias ssh-list='ssh-add -l'

# Copy SSH public key to clipboard
function ssh-copy-key() {
    local key="${1:-$HOME/.ssh/id_ed25519.pub}"
    
    if [[ ! -f "$key" ]]; then
        echo "Key not found: $key"
        return 1
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        cat "$key" | pbcopy
        echo "SSH public key copied to clipboard"
    elif [[ -x "$(command -v xclip)" ]]; then
        cat "$key" | xclip -selection clipboard
        echo "SSH public key copied to clipboard"
    else
        echo "Install xclip or manually copy:"
        cat "$key"
    fi
}

# --- SSH config management ---

# Edit SSH config
alias ssh-config='${EDITOR:-vim} ~/.ssh/config'

# Add SSH host to config
function ssh-add-host() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: ssh-add-host <alias> <hostname> [user] [port]"
        return 1
    fi
    
    local alias="$1"
    local hostname="$2"
    local user="${3:-$USER}"
    local port="${4:-22}"
    
    cat >> ~/.ssh/config << EOF

Host $alias
    HostName $hostname
    User $user
    Port $port
    ServerAliveInterval 60
    ServerAliveCountMax 3
EOF
    
    echo "Added SSH host '$alias' to config"
}

# List SSH hosts from config
function ssh-hosts() {
    if [[ -f ~/.ssh/config ]]; then
        grep "^Host " ~/.ssh/config | awk '{print $2}' | grep -v "\*" | sort
    else
        echo "No SSH config file found"
    fi
}

# Interactive SSH connection with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function ssf() {
        local host=$(ssh-hosts | fzf --preview 'grep -A 5 "^Host {}" ~/.ssh/config')
        [[ -n "$host" ]] && ssh "$host"
    }
fi

# --- SSH tunnel management ---

# Create SSH tunnel
function ssh-tunnel() {
    if [[ $# -lt 3 ]]; then
        echo "Usage: ssh-tunnel <local_port> <remote_host:remote_port> <ssh_host>"
        echo "Example: ssh-tunnel 8080 localhost:80 myserver"
        return 1
    fi
    
    local local_port="$1"
    local remote="$2"
    local ssh_host="$3"
    
    echo "Creating tunnel: localhost:$local_port -> $remote (via $ssh_host)"
    ssh -N -L "$local_port:$remote" "$ssh_host"
}

# Create reverse SSH tunnel
function ssh-rtunnel() {
    if [[ $# -lt 3 ]]; then
        echo "Usage: ssh-rtunnel <remote_port> <local_host:local_port> <ssh_host>"
        echo "Example: ssh-rtunnel 8080 localhost:3000 myserver"
        return 1
    fi
    
    local remote_port="$1"
    local local="$2"
    local ssh_host="$3"
    
    echo "Creating reverse tunnel: $ssh_host:$remote_port -> $local"
    ssh -N -R "$remote_port:$local" "$ssh_host"
}

# SOCKS proxy
function ssh-socks() {
    local port="${1:-1080}"
    local host="${2:-}"
    
    if [[ -z "$host" ]]; then
        echo "Usage: ssh-socks [port] <ssh_host>"
        return 1
    fi
    
    echo "Starting SOCKS proxy on localhost:$port via $host"
    echo "Configure your browser to use SOCKS5 proxy at localhost:$port"
    ssh -D "$port" -C -N "$host"
}

# --- SSH connection management ---

# SSH with automatic reconnection
function ssh-persist() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssh-persist <host>"
        return 1
    fi
    
    while true; do
        ssh -o ServerAliveInterval=60 -o ServerAliveCountMax=3 "$@"
        if [[ $? -eq 0 ]]; then
            break
        fi
        echo "Connection lost. Reconnecting in 5 seconds..."
        sleep 5
    done
}

# SSH with tmux/screen session
function ssht() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssht <host> [session_name]"
        return 1
    fi
    
    local host="$1"
    local session="${2:-main}"
    
    # Try tmux first, fall back to screen
    ssh -t "$host" "tmux attach-session -t $session || tmux new-session -s $session || screen -R $session"
}

# --- SSH multiplexing ---

# Enable SSH multiplexing for a host
function ssh-multiplex() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssh-multiplex <host>"
        return 1
    fi
    
    local host="$1"
    local socket="$HOME/.ssh/controlmasters/%r@%h:%p"
    
    mkdir -p "$HOME/.ssh/controlmasters"
    
    echo "Starting SSH control master for $host"
    ssh -M -N -f -o ControlPath="$socket" -o ControlPersist=4h "$host"
}

# List active SSH control masters
function ssh-masters() {
    local cm_dir="$HOME/.ssh/controlmasters"
    if [[ -d "$cm_dir" ]]; then
        echo "Active SSH control masters:"
        ls -la "$cm_dir"
    else
        echo "No control masters directory found"
    fi
}

# --- SSH file operations ---

# Interactive SCP with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function scpf() {
        local host=$(ssh-hosts | fzf --preview 'grep -A 5 "^Host {}" ~/.ssh/config')
        if [[ -n "$host" ]]; then
            echo "Selected host: $host"
            echo -n "Remote path: "
            read remote_path
            echo -n "Local path: "
            read local_path
            
            if [[ -n "$remote_path" ]] && [[ -n "$local_path" ]]; then
                scp "$host:$remote_path" "$local_path"
            fi
        fi
    }
fi

# Mount remote directory via SSHFS
function ssh-mount() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: ssh-mount <host:remote_path> <local_mount_point>"
        return 1
    fi
    
    local remote="$1"
    local local_mount="$2"
    
    if ! command -v sshfs &> /dev/null; then
        echo "sshfs not installed"
        return 1
    fi
    
    mkdir -p "$local_mount"
    sshfs -o reconnect,ServerAliveInterval=15,ServerAliveCountMax=3 "$remote" "$local_mount"
    echo "Mounted $remote at $local_mount"
}

# Unmount SSHFS
function ssh-umount() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssh-umount <mount_point>"
        return 1
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        umount "$1"
    else
        fusermount -u "$1"
    fi
}

# --- SSH security ---

# Test SSH key authentication
function ssh-test() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssh-test <host>"
        return 1
    fi
    
    ssh -o PasswordAuthentication=no -o BatchMode=yes "$1" echo "SSH key authentication successful"
}

# Check SSH host key
function ssh-hostkey() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssh-hostkey <host>"
        return 1
    fi
    
    ssh-keyscan -t ed25519,rsa "$1" 2>/dev/null
}

# --- Utilities ---

# SSH connection speed test
function ssh-speed() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssh-speed <host>"
        return 1
    fi
    
    local host="$1"
    local size="${2:-10}"  # MB
    
    echo "Testing SSH speed to $host with ${size}MB file..."
    local start=$(date +%s)
    dd if=/dev/zero bs=1M count=$size 2>/dev/null | ssh "$host" "cat > /dev/null"
    local end=$(date +%s)
    local duration=$((end - start))
    local speed=$(echo "scale=2; $size / $duration" | bc)
    
    echo "Transfer completed in ${duration}s (${speed} MB/s)"
}

# SSH config syntax check
function ssh-check-config() {
    ssh -G localhost > /dev/null && echo "SSH config syntax OK" || echo "SSH config has errors"
}