# Docker and container management utilities

# Only load if Docker is available
if [[ -x "$(command -v docker)" ]]; then

# --- Common Docker aliases ---

alias d='docker'
alias dc='docker compose'
alias dps='docker ps'
alias dpsa='docker ps -a'
alias di='docker images'
alias dlog='docker logs'
alias dex='docker exec'
alias drm='docker rm'
alias drmi='docker rmi'
alias dstop='docker stop'
alias dstart='docker start'

# --- Container management ---

# Interactive container selection with fzf
if [[ -x "$(command -v fzf)" ]]; then
    # Select and enter container
    function dsh() {
        local container=$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | tail -n +2 | fzf --preview 'docker logs --tail 50 {}' | awk '{print $1}')
        if [[ -n "$container" ]]; then
            local shell="${1:-/bin/bash}"
            echo "Entering $container with $shell..."
            docker exec -it "$container" "$shell" || docker exec -it "$container" /bin/sh
        fi
    }
    
    # Select and stop containers
    function dstopf() {
        local containers=$(docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | tail -n +2 | fzf -m | awk '{print $1}')
        if [[ -n "$containers" ]]; then
            echo "$containers" | xargs docker stop
        fi
    }
    
    # Select and remove containers
    function drmf() {
        local containers=$(docker ps -a --format "table {{.Names}}\t{{.Image}}\t{{.Status}}" | tail -n +2 | fzf -m | awk '{print $1}')
        if [[ -n "$containers" ]]; then
            echo "$containers" | xargs docker rm
        fi
    }
    
    # Select and remove images
    function drmif() {
        local images=$(docker images --format "table {{.Repository}}:{{.Tag}}\t{{.ID}}\t{{.Size}}" | tail -n +2 | fzf -m | awk '{print $2}')
        if [[ -n "$images" ]]; then
            echo "$images" | xargs docker rmi
        fi
    }
fi

# Quick shell into container
function dshell() {
    local container="${1}"
    local shell="${2:-/bin/bash}"
    
    if [[ -z "$container" ]]; then
        echo "Usage: dshell <container> [shell]"
        return 1
    fi
    
    docker exec -it "$container" "$shell" || docker exec -it "$container" /bin/sh
}

# Follow logs
function dlogs() {
    local container="${1}"
    local lines="${2:-100}"
    
    if [[ -z "$container" ]]; then
        echo "Usage: dlogs <container> [lines]"
        return 1
    fi
    
    docker logs -f --tail "$lines" "$container"
}

# --- Container inspection ---

# Inspect container with jq
function dinspect() {
    if [[ -z "$1" ]]; then
        echo "Usage: dinspect <container> [jq_filter]"
        return 1
    fi
    
    local container="$1"
    local filter="${2:-.}"
    
    if [[ -x "$(command -v jq)" ]]; then
        docker inspect "$container" | jq "$filter"
    else
        docker inspect "$container"
    fi
}

# Show container environment variables
function denv() {
    if [[ -z "$1" ]]; then
        echo "Usage: denv <container>"
        return 1
    fi
    
    docker inspect "$1" | jq -r '.[0].Config.Env[]' | sort
}

# Show container mounts
function dmounts() {
    if [[ -z "$1" ]]; then
        echo "Usage: dmounts <container>"
        return 1
    fi
    
    docker inspect "$1" | jq -r '.[0].Mounts'
}

# Show container ports
function dports() {
    if [[ -z "$1" ]]; then
        echo "Usage: dports <container>"
        return 1
    fi
    
    docker inspect "$1" | jq -r '.[0].NetworkSettings.Ports'
}

# --- Image management ---

# Search Docker Hub
function dhub() {
    if [[ -z "$1" ]]; then
        echo "Usage: dhub <search_term>"
        return 1
    fi
    
    docker search "$1" --limit 10
}

# Pull image with progress
function dpull() {
    if [[ -z "$1" ]]; then
        echo "Usage: dpull <image>"
        return 1
    fi
    
    docker pull "$1" | cat
}

# Show image layers
function dlayers() {
    if [[ -z "$1" ]]; then
        echo "Usage: dlayers <image>"
        return 1
    fi
    
    docker history --no-trunc "$1"
}

# --- Volume management ---

# List volumes with details
function dvols() {
    docker volume ls -q | xargs -I {} sh -c 'echo "=== Volume: {} ==="; docker volume inspect {} | jq -r ".[0].Mountpoint"; echo'
}

# Backup volume
function dbackup() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: dbackup <volume> <backup_path>"
        return 1
    fi
    
    local volume="$1"
    local backup_path="$2"
    local timestamp=$(date +%Y%m%d_%H%M%S)
    local backup_file="${backup_path}/volume_${volume}_${timestamp}.tar.gz"
    
    echo "Backing up volume $volume to $backup_file..."
    docker run --rm -v "$volume":/data -v "$(dirname "$backup_file")":/backup alpine tar czf "/backup/$(basename "$backup_file")" -C /data .
    echo "Backup completed: $backup_file"
}

# Restore volume
function drestore() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: drestore <volume> <backup_file>"
        return 1
    fi
    
    local volume="$1"
    local backup_file="$2"
    
    echo "Restoring volume $volume from $backup_file..."
    docker run --rm -v "$volume":/data -v "$(dirname "$backup_file")":/backup alpine tar xzf "/backup/$(basename "$backup_file")" -C /data
    echo "Restore completed"
}

# --- Docker Compose helpers ---

# Docker Compose with automatic file detection
function dcu() {
    if [[ -f "docker-compose.yml" ]]; then
        docker compose up "$@"
    elif [[ -f "docker-compose.yaml" ]]; then
        docker compose up "$@"
    elif [[ -f "compose.yml" ]]; then
        docker compose up "$@"
    elif [[ -f "compose.yaml" ]]; then
        docker compose up "$@"
    else
        echo "No docker-compose file found"
        return 1
    fi
}

alias dcup='dcu -d'
alias dcdown='docker compose down'
alias dcrestart='docker compose restart'
alias dclogs='docker compose logs -f'
alias dcexec='docker compose exec'

# --- Cleanup utilities ---

# Remove all stopped containers
function dclean() {
    echo "Removing stopped containers..."
    docker container prune -f
    
    echo "Removing unused networks..."
    docker network prune -f
    
    echo "Removing dangling images..."
    docker image prune -f
    
    echo "Removing unused volumes..."
    docker volume prune -f
}

# Deep clean - remove everything unused
function dclean-all() {
    echo "WARNING: This will remove all unused containers, networks, images, and volumes."
    echo -n "Continue? [y/N] "
    read -r response
    
    if [[ "$response" =~ ^[Yy]$ ]]; then
        docker system prune -a --volumes -f
    fi
}

# Show disk usage
function ddisk() {
    docker system df -v
}

# --- Build helpers ---

# Build with cache info
function dbuild() {
    if [[ -z "$1" ]]; then
        echo "Usage: dbuild <tag> [context]"
        return 1
    fi
    
    local tag="$1"
    local context="${2:-.}"
    
    DOCKER_BUILDKIT=1 docker build --progress=plain -t "$tag" "$context"
}

# Build without cache
function dbuild-nocache() {
    if [[ -z "$1" ]]; then
        echo "Usage: dbuild-nocache <tag> [context]"
        return 1
    fi
    
    local tag="$1"
    local context="${2:-.}"
    
    DOCKER_BUILDKIT=1 docker build --no-cache --progress=plain -t "$tag" "$context"
}

# --- Security scanning ---

# Scan image for vulnerabilities (requires trivy)
function dscan() {
    if [[ -z "$1" ]]; then
        echo "Usage: dscan <image>"
        return 1
    fi
    
    if [[ -x "$(command -v trivy)" ]]; then
        trivy image "$1"
    else
        echo "Trivy not installed. Install with: brew install aquasecurity/trivy/trivy"
    fi
}

# --- Stats and monitoring ---

# Live container stats
alias dstats='docker stats'

# Container resource usage
function dusage() {
    docker ps --format "table {{.Names}}\t{{.Image}}\t{{.Size}}"
}

# Show container processes
function dtop() {
    if [[ -z "$1" ]]; then
        echo "Usage: dtop <container>"
        return 1
    fi
    
    docker top "$1"
}

# --- Networking ---

# List networks
alias dnets='docker network ls'

# Inspect network
function dnet() {
    if [[ -z "$1" ]]; then
        echo "Usage: dnet <network>"
        return 1
    fi
    
    docker network inspect "$1" | jq -r '.[0].Containers'
}

# --- Registry operations ---

# Login to registry
function dlogin() {
    local registry="${1:-docker.io}"
    docker login "$registry"
}

# Push with retag
function dpush() {
    if [[ $# -lt 2 ]]; then
        echo "Usage: dpush <local_image> <remote_tag>"
        return 1
    fi
    
    local local_image="$1"
    local remote_tag="$2"
    
    docker tag "$local_image" "$remote_tag"
    docker push "$remote_tag"
}

fi # End of Docker check