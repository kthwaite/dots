# Network utilities for power users

# --- IP and DNS utilities ---

# Get public IP
function myip() {
    echo "Public IP: $(curl -s https://ipinfo.io/ip)"
    echo "Local IPs:"
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ifconfig | grep "inet " | grep -v 127.0.0.1 | awk '{print $2}'
    else
        ip -4 addr show | grep -oP '(?<=inet\s)\d+(\.\d+){3}' | grep -v 127.0.0.1
    fi
}

# Detailed IP info
function ipinfo() {
    local ip="${1:-}"
    curl -s "https://ipinfo.io/$ip" | jq '.'
}

# DNS lookup with multiple servers
function dns() {
    if [[ -z "$1" ]]; then
        echo "Usage: dns <domain>"
        return 1
    fi
    
    local domain="$1"
    echo "=== Cloudflare DNS (1.1.1.1) ==="
    dig @1.1.1.1 "$domain" +short
    
    echo -e "\n=== Google DNS (8.8.8.8) ==="
    dig @8.8.8.8 "$domain" +short
    
    echo -e "\n=== Default DNS ==="
    dig "$domain" +short
}

# Reverse DNS lookup
function rdns() {
    if [[ -z "$1" ]]; then
        echo "Usage: rdns <ip>"
        return 1
    fi
    
    dig -x "$1" +short
}

# --- Port checking ---

# Check if port is open
function port-check() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: port-check <host> <port>"
        return 1
    fi
    
    local host="$1"
    local port="$2"
    
    if timeout 2 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
        echo "Port $port is open on $host"
    else
        echo "Port $port is closed or filtered on $host"
    fi
}

# Scan common ports
function port-scan() {
    if [[ -z "$1" ]]; then
        echo "Usage: port-scan <host>"
        return 1
    fi
    
    local host="$1"
    local common_ports=(22 80 443 3306 5432 6379 8080 8443 9000)
    
    echo "Scanning common ports on $host..."
    for port in "${common_ports[@]}"; do
        if timeout 1 bash -c "echo >/dev/tcp/$host/$port" 2>/dev/null; then
            echo "Port $port: OPEN"
        fi
    done
}

# --- HTTP utilities ---

# HTTP headers
function headers() {
    if [[ -z "$1" ]]; then
        echo "Usage: headers <url>"
        return 1
    fi
    
    curl -sI "$1" | sed -n '/^[[:space:]]*$/q;p'
}

# Follow redirects and show chain
function follow() {
    if [[ -z "$1" ]]; then
        echo "Usage: follow <url>"
        return 1
    fi
    
    curl -sIL "$1" | grep -E "^(HTTP|Location)"
}

# Quick HTTP server
function serve() {
    local port="${1:-8000}"
    local dir="${2:-.}"
    
    echo "Serving $dir on http://localhost:$port"
    
    if [[ -x "$(command -v python3)" ]]; then
        (cd "$dir" && python3 -m http.server "$port")
    elif [[ -x "$(command -v python)" ]]; then
        (cd "$dir" && python -m SimpleHTTPServer "$port")
    elif [[ -x "$(command -v ruby)" ]]; then
        (cd "$dir" && ruby -run -e httpd . -p "$port")
    else
        echo "No suitable HTTP server found (python/ruby)"
    fi
}

# Download with resume support
function dl() {
    if [[ -z "$1" ]]; then
        echo "Usage: dl <url> [output_file]"
        return 1
    fi
    
    local url="$1"
    local output="${2:-$(basename "$url")}"
    
    curl -L -C - -o "$output" "$url"
}

# --- Network monitoring ---

# Monitor network connections
function netmon() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo lsof -i -n -P
    else
        sudo ss -tunap
    fi
}

# Show bandwidth usage by process (requires nethogs)
function bandwidth() {
    if [[ -x "$(command -v nethogs)" ]]; then
        sudo nethogs
    else
        echo "nethogs not installed"
        echo "Install with: brew install nethogs (macOS) or apt install nethogs (Linux)"
    fi
}

# Connection count by IP
function connections() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        netstat -an | grep ESTABLISHED | awk '{print $5}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -20
    else
        ss -tan state established | tail -n +2 | awk '{print $4}' | cut -d: -f1 | sort | uniq -c | sort -rn | head -20
    fi
}

# --- Speed testing ---

# Speed test
function speedtest() {
    if [[ -x "$(command -v speedtest-cli)" ]]; then
        speedtest-cli
    elif [[ -x "$(command -v speedtest)" ]]; then
        speedtest
    else
        echo "Speedtest not installed"
        echo "Install with: brew install speedtest-cli"
    fi
}

# Quick bandwidth test with curl
function bwtest() {
    local url="http://speedtest.tele2.net/100MB.zip"
    echo "Testing download speed..."
    curl -o /dev/null -w "Download speed: %{speed_download} bytes/sec\n" "$url"
}

# --- SSL/TLS utilities ---

# Check SSL certificate
function ssl-check() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssl-check <domain> [port]"
        return 1
    fi
    
    local domain="$1"
    local port="${2:-443}"
    
    echo | openssl s_client -connect "$domain:$port" -servername "$domain" 2>/dev/null | openssl x509 -noout -dates -subject -issuer
}

# SSL certificate expiry
function ssl-expiry() {
    if [[ -z "$1" ]]; then
        echo "Usage: ssl-expiry <domain> [port]"
        return 1
    fi
    
    local domain="$1"
    local port="${2:-443}"
    
    echo | openssl s_client -connect "$domain:$port" -servername "$domain" 2>/dev/null | openssl x509 -noout -enddate
}

# --- API testing ---

# GET request with formatted JSON
function get() {
    if [[ -z "$1" ]]; then
        echo "Usage: get <url>"
        return 1
    fi
    
    if [[ -x "$(command -v jq)" ]]; then
        curl -s "$1" | jq '.'
    else
        curl -s "$1"
    fi
}

# POST request
function post() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: post <url> <data>"
        echo "Example: post https://api.example.com/users '{\"name\":\"test\"}'"
        return 1
    fi
    
    local url="$1"
    local data="$2"
    
    if [[ -x "$(command -v jq)" ]]; then
        curl -s -X POST -H "Content-Type: application/json" -d "$data" "$url" | jq '.'
    else
        curl -s -X POST -H "Content-Type: application/json" -d "$data" "$url"
    fi
}

# --- Network diagnostics ---

# MTR (My Traceroute) - better traceroute
function trace() {
    if [[ -z "$1" ]]; then
        echo "Usage: trace <host>"
        return 1
    fi
    
    if [[ -x "$(command -v mtr)" ]]; then
        mtr "$1"
    else
        traceroute "$1"
    fi
}

# Ping with timestamp
function tping() {
    if [[ -z "$1" ]]; then
        echo "Usage: tping <host>"
        return 1
    fi
    
    ping "$1" | while read line; do
        echo "$(date '+%Y-%m-%d %H:%M:%S') $line"
    done
}

# --- Firewall management ---

# Show firewall rules (platform-specific)
function fw-list() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo pfctl -sr 2>/dev/null || echo "PF firewall not enabled"
    elif [[ -x "$(command -v ufw)" ]]; then
        sudo ufw status verbose
    elif [[ -x "$(command -v iptables)" ]]; then
        sudo iptables -L -n -v
    else
        echo "No supported firewall found"
    fi
}

# --- Network interfaces ---

# Show network interfaces with details
function interfaces() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        networksetup -listallhardwareports
    else
        ip -c addr show
    fi
}

# Wi-Fi info (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    function wifi() {
        local interface="${1:-en0}"
        /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -I
    }
    
    # Scan for Wi-Fi networks
    function wifi-scan() {
        local interface="${1:-en0}"
        sudo /System/Library/PrivateFrameworks/Apple80211.framework/Versions/Current/Resources/airport -s
    }
fi

# --- Proxy management ---

# Set HTTP proxy
function proxy-set() {
    if [[ -z "$1" ]]; then
        echo "Usage: proxy-set <proxy_url>"
        echo "Example: proxy-set http://proxy.example.com:8080"
        return 1
    fi
    
    export http_proxy="$1"
    export https_proxy="$1"
    export HTTP_PROXY="$1"
    export HTTPS_PROXY="$1"
    echo "Proxy set to: $1"
}

# Unset proxy
function proxy-unset() {
    unset http_proxy https_proxy HTTP_PROXY HTTPS_PROXY
    echo "Proxy settings cleared"
}

# Show proxy settings
function proxy-show() {
    echo "http_proxy: ${http_proxy:-not set}"
    echo "https_proxy: ${https_proxy:-not set}"
}