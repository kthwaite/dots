if [[ "$OSTYPE" == "linux-gnu"* ]] && [[ -f "/etc/arch-release" ]]; then
    # -- Package management helpers
    if [[ -x "$(command -v fzf)" ]]; then
        # Interactive package installation
        alias pacfzf="pacman -Slq | fzf -m --preview 'pacman -Si {1}' | xargs -ro sudo pacman -S"
        alias yayfzf="yay -Slq | fzf -m --preview 'yay -Si {1}' | xargs -ro yay -S"
        # Browse installed packages
        alias pacsrc="pacman -Qeq | fzf -m --preview 'pacman -Qi {1}'"
        # Search and remove packages
        alias pacrm="pacman -Qq | fzf -m --preview 'pacman -Qi {1}' | xargs -ro sudo pacman -Rns"
    fi

    # System update wrapper with better output
    function sysup() {
        echo "==> Updating package databases..."
        sudo pacman -Sy
        
        echo -e "\n==> Upgrading official packages..."
        sudo pacman -Su
        
        if [[ -x "$(command -v yay)" ]]; then
            echo -e "\n==> Upgrading AUR packages..."
            yay -Su --aur
        fi
        
        echo -e "\n==> Cleaning package cache..."
        sudo pacman -Sc --noconfirm
        
        if [[ -x "$(command -v yay)" ]]; then
            yay -Sc --noconfirm
        fi
    }

    # Find orphaned packages
    alias pacorphans='pacman -Qdt'
    
    # Remove orphaned packages
    function pacclean() {
        local orphans=$(pacman -Qdtq)
        if [[ -n "$orphans" ]]; then
            echo "Removing orphaned packages:"
            echo "$orphans"
            echo "$orphans" | sudo pacman -Rns -
        else
            echo "No orphaned packages found."
        fi
    }

    # Show package sizes
    alias pacsize='expac -S -H M "%k\t%n" | sort -rhk 1'
    
    # Show explicitly installed packages by size
    alias pacbig='expac -Q -H M "%k\t%n" | sort -rhk 1 | head -20'

    # Find which package owns a file
    function pacown() {
        if [[ -z "$1" ]]; then
            echo "Usage: pacown <file>"
            return 1
        fi
        pacman -Qo "$1"
    }

    # List files installed by a package
    function pacfiles() {
        if [[ -z "$1" ]]; then
            echo "Usage: pacfiles <package>"
            return 1
        fi
        pacman -Ql "$1"
    }

    # Show package dependency tree
    function pacdeps() {
        if [[ -z "$1" ]]; then
            echo "Usage: pacdeps <package>"
            return 1
        fi
        pactree "$1"
    }

    # Mirror ranking and update
    function pacmirror() {
        echo "Ranking mirrors by speed..."
        sudo reflector --latest 20 --protocol https --sort rate --save /etc/pacman.d/mirrorlist
        echo "Mirror list updated. Running system update..."
        sysup
    }
fi

# Power management (works on most Linux systems)
power-consumption() {
    if [[ -x "$(command -v upower)" ]]; then
        upower -i /org/freedesktop/UPower/devices/battery_BAT0
    else
        echo "upower not installed"
    fi
}

# System information
function sysinfo() {
    echo "==> System Information"
    echo "Kernel: $(uname -r)"
    echo "Uptime: $(uptime -p)"
    echo "Memory: $(free -h | awk '/^Mem:/{print $3 "/" $2}')"
    echo "Disk: $(df -h / | awk 'NR==2{print $3 "/" $2 " (" $5 ")"}')"
    
    if [[ -x "$(command -v sensors)" ]]; then
        echo -e "\n==> Temperature"
        sensors | grep -E "Core|temp1"
    fi
    
    if [[ -f "/etc/arch-release" ]]; then
        echo -e "\n==> Package Statistics"
        echo "Installed packages: $(pacman -Q | wc -l)"
        echo "Explicitly installed: $(pacman -Qe | wc -l)"
        echo "Orphaned packages: $(pacman -Qdt | wc -l)"
    fi
}
