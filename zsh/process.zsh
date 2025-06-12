# Process and job management utilities

# --- Enhanced process viewing ---

# Better ps output
alias psa='ps aux'
alias psg='ps aux | grep -v grep | grep -i'
alias pstree='pstree -p'

# Top alternatives
if [[ -x "$(command -v htop)" ]]; then
    alias top='htop'
elif [[ -x "$(command -v btop)" ]]; then
    alias top='btop'
fi

# Show process by name with details
function psgrep() {
    if [[ -z "$1" ]]; then
        echo "Usage: psgrep <process_name>"
        return 1
    fi
    ps aux | head -1
    ps aux | grep -v grep | grep -i "$1"
}

# --- Port management ---

# What's listening on ports
function ports() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo lsof -iTCP -sTCP:LISTEN -P -n
    else
        sudo ss -tulpn
    fi
}

# Check what's using a specific port
function port() {
    if [[ -z "$1" ]]; then
        echo "Usage: port <port_number>"
        return 1
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sudo lsof -i :$1
    else
        sudo ss -tulpn | grep ":$1"
    fi
}

# Kill process using a specific port
function killport() {
    if [[ -z "$1" ]]; then
        echo "Usage: killport <port_number>"
        return 1
    fi
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        local pid=$(lsof -t -i:$1)
    else
        local pid=$(sudo lsof -t -i:$1)
    fi
    
    if [[ -n "$pid" ]]; then
        echo "Killing process $pid using port $1"
        kill -9 $pid
    else
        echo "No process found using port $1"
    fi
}

# --- Process control ---

# Interactive process killer with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function fkill() {
        local pid
        pid=$(ps -ef | sed 1d | fzf -m --header='Select process to kill' | awk '{print $2}')
        
        if [[ -n "$pid" ]]; then
            echo "Killing processes: $pid"
            kill -${1:-9} $pid
        fi
    }
fi

# Kill all processes matching a pattern
function killall_pattern() {
    if [[ -z "$1" ]]; then
        echo "Usage: killall_pattern <pattern>"
        return 1
    fi
    
    local pids=$(pgrep -f "$1")
    if [[ -n "$pids" ]]; then
        echo "Killing processes matching '$1':"
        ps -p $pids
        kill -9 $pids
    else
        echo "No processes found matching '$1'"
    fi
}

# --- Resource monitoring ---

# Memory usage by process
function mem_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ps aux | awk 'NR>1 {print $11, $4"%"}' | sort -k2 -rn | head -20
    else
        ps aux --sort=-%mem | head -20
    fi
}

# CPU usage by process
function cpu_usage() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        ps aux | awk 'NR>1 {print $11, $3"%"}' | sort -k2 -rn | head -20
    else
        ps aux --sort=-%cpu | head -20
    fi
}

# System resource summary
function sysres() {
    echo "=== CPU Usage ==="
    if [[ "$OSTYPE" == "darwin"* ]]; then
        top -l 1 | grep "CPU usage"
    else
        grep 'cpu ' /proc/stat | awk '{usage=($2+$4)*100/($2+$4+$5)} END {printf "CPU Usage: %.2f%%\n", usage}'
    fi
    
    echo -e "\n=== Memory Usage ==="
    if [[ "$OSTYPE" == "darwin"* ]]; then
        vm_stat | perl -ne '/page size of (\d+)/ and $size=$1; /Pages\s+([^:]+)[^\d]+(\d+)/ and printf("%-16s % 16.2f MB\n", "$1:", $2 * $size / 1048576);'
    else
        free -h
    fi
    
    echo -e "\n=== Disk Usage ==="
    df -h | grep -E '^/dev/'
    
    echo -e "\n=== Load Average ==="
    uptime
}

# --- Background job management ---

# Run command in background and disown
function bkg() {
    if [[ -z "$1" ]]; then
        echo "Usage: bkg <command>"
        return 1
    fi
    nohup "$@" > /dev/null 2>&1 &
    disown
    echo "Started in background: $@"
}

# List background jobs with more detail
function jobs_detail() {
    local job_list=$(jobs -l)
    if [[ -n "$job_list" ]]; then
        echo "$job_list"
        echo ""
        jobs -l | while read -r line; do
            local pid=$(echo "$line" | awk '{print $2}')
            if [[ -n "$pid" ]]; then
                ps -p "$pid" -o pid,ppid,state,start,time,cmd | tail -n +2
            fi
        done
    else
        echo "No background jobs"
    fi
}

# --- Process utilities ---

# Wait for process to finish
function wait_for_process() {
    if [[ -z "$1" ]]; then
        echo "Usage: wait_for_process <pid|name>"
        return 1
    fi
    
    # Check if argument is PID or process name
    if [[ "$1" =~ ^[0-9]+$ ]]; then
        # It's a PID
        while kill -0 "$1" 2>/dev/null; do
            echo -n "."
            sleep 1
        done
    else
        # It's a process name
        while pgrep -x "$1" > /dev/null; do
            echo -n "."
            sleep 1
        done
    fi
    echo " Done!"
}

# Monitor command output
function monitor() {
    if [[ -z "$1" ]]; then
        echo "Usage: monitor <command> [interval_seconds]"
        return 1
    fi
    
    local interval="${2:-2}"
    while true; do
        clear
        echo "=== $(date) ==="
        eval "$1"
        sleep "$interval"
    done
}

# --- System information ---

# Show system info
function sysinfo() {
    echo "=== System Information ==="
    echo "Hostname: $(hostname)"
    echo "OS: $(uname -s) $(uname -r)"
    echo "Kernel: $(uname -v)"
    echo "Architecture: $(uname -m)"
    echo "CPU: $(sysctl -n hw.ncpu 2>/dev/null || nproc) cores"
    echo "Memory: $(free -h 2>/dev/null | awk '/^Mem:/{print $2}' || sysctl -n hw.memsize | awk '{print $0/1024/1024/1024 " GB"}')"
    echo "Uptime: $(uptime | awk -F'up ' '{print $2}' | awk -F',' '{print $1}')"
}

# --- Process limits ---

# Show current limits
alias limits='ulimit -a'

# Increase file descriptor limit
function increase_fd_limit() {
    local new_limit="${1:-10240}"
    ulimit -n "$new_limit"
    echo "File descriptor limit set to: $(ulimit -n)"
}

# --- Notifications ---

# Notify when command completes (macOS)
if [[ "$OSTYPE" == "darwin"* ]]; then
    function notify() {
        "$@"
        local exit_code=$?
        if [[ $exit_code -eq 0 ]]; then
            osascript -e "display notification \"Command completed successfully\" with title \"Terminal\""
        else
            osascript -e "display notification \"Command failed with exit code $exit_code\" with title \"Terminal\""
        fi
        return $exit_code
    }
fi

# Long running command notification
function alert() {
    local start_time=$(date +%s)
    "$@"
    local exit_code=$?
    local end_time=$(date +%s)
    local duration=$((end_time - start_time))
    
    if [[ "$OSTYPE" == "darwin"* ]]; then
        if [[ $exit_code -eq 0 ]]; then
            osascript -e "display notification \"Completed in ${duration}s\" with title \"${1}\""
        else
            osascript -e "display notification \"Failed after ${duration}s (exit: $exit_code)\" with title \"${1}\""
        fi
    else
        # Use notify-send on Linux if available
        if command -v notify-send &> /dev/null; then
            if [[ $exit_code -eq 0 ]]; then
                notify-send "${1}" "Completed in ${duration}s"
            else
                notify-send "${1}" "Failed after ${duration}s (exit: $exit_code)"
            fi
        fi
    fi
    
    return $exit_code
}