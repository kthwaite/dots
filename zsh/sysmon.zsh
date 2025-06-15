# System monitoring and network utility functions

# System monitoring functions
cpu_usage() {
    if command -v top >/dev/null 2>&1; then
        top -bn1 | grep "Cpu(s)" | awk '{print $2 + $4 "%"}'
    elif [[ -f /proc/stat ]]; then
        awk '/^cpu / {usage=($2+$4)*100/($2+$4+$5)} END {print usage "%"}' /proc/stat
    else
        echo "CPU usage information not available"
    fi
}

memory_usage() {
    if command -v free >/dev/null 2>&1; then
        free -h | awk '/^Mem:/ {printf "Used: %s/%s (%.1f%%)\n", $3, $2, $3/$2*100}'
    elif [[ -f /proc/meminfo ]]; then
        awk '/MemTotal|MemAvailable/ {
            if($1=="MemTotal:") total=$2
            if($1=="MemAvailable:") avail=$2
        } END {
            used=total-avail
            printf "Used: %.1fG/%.1fG (%.1f%%)\n", used/1024/1024, total/1024/1024, used/total*100
        }' /proc/meminfo
    else
        echo "Memory usage information not available"
    fi
}

disk_usage() {
    local path=${1:-.}
    if command -v df >/dev/null 2>&1; then
        df -h "$path" | awk 'NR==2 {printf "Used: %s/%s (%s)\n", $3, $2, $5}'
    else
        echo "Disk usage information not available"
    fi
}

# System status overview
status() {
    echo "=== System Status ==="
    echo "Date: $(date)"
    echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
    echo "Load: $(uptime | awk -F'load average: ' '{print $2}')"
    echo ""
    
    echo "=== Resource Usage ==="
    echo "CPU: $(cpu_usage)"
    echo "Memory: $(memory_usage)"
    echo "Disk: $(disk_usage)"
    echo ""
    
    echo "=== Network ==="
    echo "Local IP: $(ip route get 1.1.1.1 2>/dev/null | awk '{print $7; exit}' || echo "Unknown")"
    
    if command -v ss >/dev/null 2>&1; then
        echo "Active connections: $(ss -tun | grep -c ESTAB)"
    elif command -v netstat >/dev/null 2>&1; then
        echo "Active connections: $(netstat -tn | grep -c ESTABLISHED)"
    fi
}

# Process monitoring
top_processes() {
    local count=${1:-10}
    echo "Top $count processes by CPU usage:"
    if command -v ps >/dev/null 2>&1; then
        ps aux --sort=-%cpu | head -$((count + 1))
    else
        echo "Process information not available"
    fi
}

top_memory() {
    local count=${1:-10}
    echo "Top $count processes by memory usage:"
    if command -v ps >/dev/null 2>&1; then
        ps aux --sort=-%mem | head -$((count + 1))
    else
        echo "Process information not available"
    fi
}

# Network utilities
port_check() {
    local host="$1"
    local port="$2"
    
    if [[ -z "$host" || -z "$port" ]]; then
        echo "Usage: port_check <host> <port>"
        return 1
    fi
    
    if command -v nc >/dev/null 2>&1; then
        if nc -z -w3 "$host" "$port" 2>/dev/null; then
            echo "Port $port is open on $host"
            return 0
        else
            echo "Port $port is closed on $host"
            return 1
        fi
    elif command -v telnet >/dev/null 2>&1; then
        (echo > /dev/tcp/"$host"/"$port") 2>/dev/null && \
            echo "Port $port is open on $host" || \
            echo "Port $port is closed on $host"
    else
        echo "No port checking tool available"
        return 1
    fi
}

# Find what's using a port
who_port() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: who_port <port>"
        return 1
    fi
    
    if command -v lsof >/dev/null 2>&1; then
        echo "Processes using port $port:"
        lsof -i :$port
    elif command -v ss >/dev/null 2>&1; then
        echo "Processes using port $port:"
        ss -tulpn | grep ":$port "
    elif command -v netstat >/dev/null 2>&1; then
        echo "Processes using port $port:"
        netstat -tulpn | grep ":$port "
    else
        echo "No port monitoring tool available"
    fi
}

# Network speed test (simple)
speedtest() {
    if command -v curl >/dev/null 2>&1; then
        echo "Testing download speed..."
        curl -o /dev/null -s -w "Speed: %{speed_download} bytes/sec\nTime: %{time_total}s\n" \
            http://speedtest.wdc01.softlayer.com/downloads/test10.zip
    else
        echo "curl not available for speed test"
    fi
}

# DNS lookup utilities
dns_lookup() {
    local domain="$1"
    if [[ -z "$domain" ]]; then
        echo "Usage: dns_lookup <domain>"
        return 1
    fi
    
    echo "DNS lookup for $domain:"
    if command -v dig >/dev/null 2>&1; then
        dig +short "$domain"
    elif command -v nslookup >/dev/null 2>&1; then
        nslookup "$domain" | grep -A 2 "Non-authoritative answer:"
    else
        echo "No DNS lookup tool available"
    fi
}

# Get public IP
public_ip() {
    local services=(
        "ifconfig.me"
        "ipinfo.io/ip"
        "icanhazip.com"
        "ident.me"
    )
    
    for service in "${services[@]}"; do
        local ip=$(curl -s --max-time 5 "$service" 2>/dev/null)
        if [[ -n "$ip" && "$ip" =~ ^[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}$ ]]; then
            echo "$ip"
            return 0
        fi
    done
    
    echo "Failed to get public IP"
    return 1
}

# Network interface information
netinfo() {
    echo "=== Network Interfaces ==="
    if command -v ip >/dev/null 2>&1; then
        ip addr show | grep -E '^[0-9]+:|inet ' | sed 's/^[[:space:]]*//'
    elif command -v ifconfig >/dev/null 2>&1; then
        ifconfig | grep -E '^[a-z]|inet '
    else
        echo "No network interface tool available"
    fi
    
    echo ""
    echo "=== Routing Table ==="
    if command -v ip >/dev/null 2>&1; then
        ip route show
    elif command -v route >/dev/null 2>&1; then
        route -n
    else
        echo "No routing tool available"
    fi
}

# System cleanup utilities
cleanup_logs() {
    echo "Cleaning up system logs..."
    
    # Clear journal logs older than 7 days (if systemd)
    if command -v journalctl >/dev/null 2>&1; then
        sudo journalctl --vacuum-time=7d
    fi
    
    # Clear old log files
    if [[ -d /var/log ]]; then
        echo "Old log files:"
        find /var/log -name "*.log.*" -o -name "*.gz" -o -name "*.old" 2>/dev/null | head -10
    fi
}

cleanup_cache() {
    echo "Cleaning up caches..."
    
    # User cache
    if [[ -d "$HOME/.cache" ]]; then
        local cache_size=$(du -sh "$HOME/.cache" 2>/dev/null | cut -f1)
        echo "User cache size: $cache_size"
    fi
    
    # Package manager caches
    if command -v apt >/dev/null 2>&1; then
        echo "APT cache size:"
        du -sh /var/cache/apt/archives 2>/dev/null || echo "N/A"
    fi
    
    if command -v yum >/dev/null 2>&1; then
        echo "YUM cache size:"
        du -sh /var/cache/yum 2>/dev/null || echo "N/A"
    fi
}

# Hardware information
hwinfo() {
    echo "=== Hardware Information ==="
    
    # CPU info
    if [[ -f /proc/cpuinfo ]]; then
        echo "CPU: $(grep 'model name' /proc/cpuinfo | head -1 | cut -d: -f2 | sed 's/^[[:space:]]*//')"
        echo "Cores: $(grep -c ^processor /proc/cpuinfo)"
    fi
    
    # Memory info
    if [[ -f /proc/meminfo ]]; then
        echo "RAM: $(grep MemTotal /proc/meminfo | awk '{printf "%.1f GB\n", $2/1024/1024}')"
    fi
    
    # Disk info
    echo "Storage:"
    if command -v lsblk >/dev/null 2>&1; then
        lsblk -d -o NAME,SIZE,MODEL | grep -v loop
    elif command -v df >/dev/null 2>&1; then
        df -h | grep -v tmpfs | grep -v udev
    fi
    
    # USB devices
    if command -v lsusb >/dev/null 2>&1; then
        echo ""
        echo "USB devices:"
        lsusb | head -5
    fi
    
    # PCI devices
    if command -v lspci >/dev/null 2>&1; then
        echo ""
        echo "PCI devices:"
        lspci | grep -E 'VGA|Audio|Network|Wireless' | head -5
    fi
}
