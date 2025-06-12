# https://github.com/mroth/evalcache
# Caches the output of a binary initialization command, to avoid the time to
# execute it in the future.
#
# Usage: _evalcache <command> <generation args...>

# default cache directory
export ZSH_EVALCACHE_DIR=${ZSH_EVALCACHE_DIR:-"$HOME/.zsh-evalcache"}

function _evalcache () {
  local cacheFile="$ZSH_EVALCACHE_DIR/init-${1##*/}.sh"

  if [ "$ZSH_EVALCACHE_DISABLE" = "true" ]; then
    eval "$("$@")"
  elif [ -s "$cacheFile" ]; then
    source "$cacheFile"
  else
    if type "$1" > /dev/null; then
      (>&2 echo "$1 initialization not cached, caching output of: $*")
      mkdir -p "$ZSH_EVALCACHE_DIR"
      "$@" > "$cacheFile"
      source "$cacheFile"
    else
      echo "evalcache ERROR: $1 is not installed or in PATH"
    fi
  fi
}

function _evalcache_clear () {
  rm -i "$ZSH_EVALCACHE_DIR"/init-*.sh
}

# Common tool initializations that benefit from caching
function _evalcache_common_inits() {
  # Mise (formerly rtx) - tool version manager
  if type mise > /dev/null 2>&1; then
    _evalcache mise activate zsh
  fi
  
  # Node Version Manager
  if [ -s "$HOME/.nvm/nvm.sh" ]; then
    export NVM_DIR="$HOME/.nvm"
    [ -s "$NVM_DIR/bash_completion" ] && source "$NVM_DIR/bash_completion"
    _evalcache source "$NVM_DIR/nvm.sh"
  fi
  
  # Cargo/Rust environment
  if [ -f "$HOME/.cargo/env" ]; then
    source "$HOME/.cargo/env"
  fi
  
  # Conda/Mamba initialization
  if type conda > /dev/null 2>&1; then
    _evalcache conda "shell.zsh" "hook"
  elif type mamba > /dev/null 2>&1; then
    _evalcache mamba "shell.zsh" "hook"
  fi
  
  # GitHub CLI completion
  if type gh > /dev/null 2>&1; then
    _evalcache gh completion -s zsh
  fi
  
  # Direnv hook
  if type direnv > /dev/null 2>&1; then
    _evalcache direnv hook zsh
  fi
}

# Call common initializations if not disabled
if [ "$ZSH_EVALCACHE_DISABLE" != "true" ]; then
  _evalcache_common_inits
fi
