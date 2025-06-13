# Debian/Ubuntu package management utilities

# Only load on Debian-based systems
if [[ -f "/etc/debian_version" ]]; then

# Find which package provides a file
function pkg-where {
    # i can never remember what this flag is
    dpkg-query -L "$@"
}

# Find which package owns a file
function pkg-owns {
    if [[ -z "$1" ]]; then
        echo "Usage: pkg-owns <file>"
        return 1
    fi
    dpkg -S "$1"
}

# Search for packages
function pkg-search {
    apt-cache search "$@"
}

# Show package info
function pkg-info {
    apt-cache show "$@"
}

# List installed packages by size
function pkg-size {
    dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -rn | head -"${1:-20}"
}

# Interactive package search with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function pkg-fzf {
        apt-cache search . | \
            fzf --preview 'apt-cache show {1}' \
                --preview-window=right:50%:wrap | \
            awk '{print $1}'
    }
    
    # Install package interactively
    function pkg-install {
        local pkg=$(pkg-fzf)
        if [[ -n "$pkg" ]]; then
            sudo apt install "$pkg"
        fi
    }
fi

# Update system
function sysupdate {
    echo "==> Updating package lists..."
    sudo apt update
    
    echo -e "\n==> Upgrading packages..."
    sudo apt upgrade
    
    echo -e "\n==> Removing unnecessary packages..."
    sudo apt autoremove
    
    echo -e "\n==> Cleaning package cache..."
    sudo apt autoclean
}

# List upgradable packages
function pkg-upgradable {
    apt list --upgradable
}

# Show package dependencies
function pkg-deps {
    apt-cache depends "$@"
}

# Show reverse dependencies
function pkg-rdeps {
    apt-cache rdepends "$@"
}

# List manually installed packages
function pkg-manual {
    comm -23 <(apt-mark showmanual | sort) <(gzip -dc /var/log/installer/initial-status.gz | sed -n 's/^Package: //p' | sort)
}

# Clean up old kernels
function clean-kernels {
    local current=$(uname -r | sed -E 's/-[a-z]+$//')
    echo "Current kernel: $current"
    echo "Kernels to remove:"
    dpkg -l 'linux-*' | awk '/^ii/ {print $2}' | grep -v "$current" | grep -E 'linux-image-[0-9]' | grep -v 'linux-image-generic'
    
    echo -n "Remove old kernels? [y/N] "
    read -r response
    if [[ "$response" =~ ^[Yy]$ ]]; then
        dpkg -l 'linux-*' | awk '/^ii/ {print $2}' | grep -v "$current" | grep -E 'linux-image-[0-9]' | grep -v 'linux-image-generic' | xargs sudo apt-get -y purge
    fi
}

# Reconfigure package
function pkg-reconf {
    sudo dpkg-reconfigure "$@"
}

# Fix broken packages
function pkg-fix {
    sudo apt --fix-broken install
}

# Download package without installing
function pkg-download {
    apt download "$@"
}

# List package files before installing
function pkg-files {
    if [[ -z "$1" ]]; then
        echo "Usage: pkg-files <package>"
        return 1
    fi
    
    if dpkg -l | grep -q "^ii  $1 "; then
        # Package is installed
        dpkg -L "$1"
    else
        # Package not installed, download and check
        apt-file list "$1" 2>/dev/null || echo "Install apt-file: sudo apt install apt-file && sudo apt-file update"
    fi
}

# Security updates
function security-updates {
    echo "==> Available security updates:"
    sudo apt list --upgradable 2>/dev/null | grep -i security
}

# Hold/unhold packages
function pkg-hold {
    sudo apt-mark hold "$@"
}

function pkg-unhold {
    sudo apt-mark unhold "$@"
}

function pkg-held {
    apt-mark showhold
}

fi # End of Debian check
