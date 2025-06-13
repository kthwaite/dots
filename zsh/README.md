# ZSH Configuration

A modular ZSH configuration system with core functionality and optional modules.

## Installation

Run the install script to set up your `.zshrc`:

```bash
./install-zsh.sh
```

This will:
1. Back up your existing `.zshrc` (if any)
2. Let you select which optional modules to include
3. Generate a new `.zshrc` that loads modules from this directory

## Structure

### Core Modules (Always Loaded)

- **00_prelude.zsh** - Essential ZSH configuration: environment variables, aliases, vi-mode, history settings
- **01_prompt.zsh** - Custom prompt (only loads if `starship` is not available)
- **02_completion.zsh** - ZSH completion system configuration

### Optional Modules

#### Development
- **python.zsh** - Python development utilities
  - `pytouch` / `pt` - Create Python package structures
  - `vvv` - Virtual environment management with UV support
  - `auto_activate_venv` - Auto-activate venvs when entering directories
  - UV helpers: `uvs`, `uva`, `uvr`, `uv-init`, `uvpy`, `uv-tools`
- **git.zsh** - Git helper functions
  - `whatchanged` - Show commits since a date
  - `clone_subdir` - Clone specific subdirectories
- **llm.zsh** - LLM integration utilities
  - `suggest-commit` - Generate commit messages
  - `files-to-tokens` - Count tokens in files
  - Requires: `llm`, `jq`, `ttok`, `files-to-prompt`

#### Power User Tools
- **nav.zsh** - Enhanced directory navigation
  - Zoxide integration (`j`, `ji`)
  - Directory bookmarks (`bookmark`, `goto`, `unbookmark`)
  - Recent directories tracking (`recent`)
  - Project navigation (`proj`, `cdg`)
  - Quick navigation (`up`, `scd`, `mkcd`)
- **file.zsh** - File manipulation shortcuts
  - Batch operations (`rename_batch`, `lowercase_files`, `add_prefix/suffix`)
  - Safe operations with progress (`mvp`, `cpp`)
  - Archive handling (`extract`, `archive`)
  - File search with fzf (`ff`, `fe`, `fd`)
  - Quick backup (`backup`, `bak`)
- **process.zsh** - Process and job management
  - Port utilities (`ports`, `port`, `killport`)
  - Process control (`fkill`, `psgrep`, `killall_pattern`)
  - Resource monitoring (`mem_usage`, `cpu_usage`, `sysres`)
  - Notifications (`notify`, `alert`)
- **ssh.zsh** - SSH utilities
  - Key management (`ssh-keygen-best`, `ssh-add-key`, `ssh-copy-key`)
  - Config management (`ssh-add-host`, `ssh-hosts`, `ssf`)
  - Tunnels (`ssh-tunnel`, `ssh-rtunnel`, `ssh-socks`)
  - Multiplexing (`ssh-multiplex`, `ssh-masters`)
- **docker.zsh** - Docker management
  - Interactive selection with fzf (`dsh`, `dstopf`, `drmf`)
  - Container inspection (`dinspect`, `denv`, `dmounts`)
  - Volume backup/restore (`dbackup`, `drestore`)
  - Cleanup utilities (`dclean`, `dclean-all`)
- **net.zsh** - Network utilities
  - IP/DNS tools (`myip`, `ipinfo`, `dns`, `rdns`)
  - Port checking (`port-check`, `port-scan`)
  - HTTP utilities (`headers`, `follow`, `serve`)
  - SSL/TLS (`ssl-check`, `ssl-expiry`)
  - API testing (`get`, `post`)

#### System-Specific
- **arch.zsh** - Arch Linux utilities
  - Package management with fzf (`pacfzf`, `yayfzf`)
  - System maintenance (`sysup`, `pacclean`, `pacmirror`)
  - Package info (`pacsize`, `pacown`, `pacfiles`)
- **deb.zsh** - Debian/Ubuntu utilities
  - Package search and info (`pkg-search`, `pkg-info`, `pkg-fzf`)
  - System maintenance (`sysupdate`, `clean-kernels`)
  - Package management (`pkg-hold`, `pkg-manual`)
- **brew.zsh** - Homebrew helpers
  - `brew-list-installed` - List user-installed packages

#### Utilities
- **evalcache.zsh** - Shell initialization caching
  - Automatically caches slow commands (mise, nvm, conda, etc.)
  - Significantly improves shell startup time
- **whoa.zsh** - Git safety (warns on `git add .`)
- **ffmpeg.zsh** - Media manipulation
  - Video operations (`trim_video`, `compress_video`, `video_to_gif`)
  - Audio operations (`extract_audio`, `remove_audio`)
  - Batch processing (`batch_compress`)
- **cmus.zsh** - cmus music player helpers
- **v.zsh** - V language utilities

## Managing Modules

After installation, your `.zshrc` will contain an array of enabled modules:

```zsh
# Optional modules (customize this array to add/remove modules)
zsh_modules=(
    "python"
    "git"
    "llm"
)
```

To add/remove modules, simply edit this array in your `.zshrc`.

## Manual Setup

If you prefer manual setup, add this to your `.zshrc`:

```zsh
# Path to dotfiles
DOTS_DIR="${HOME}/.dots"

# Source core modules
source "${DOTS_DIR}/zsh/00_prelude.zsh"
source "${DOTS_DIR}/zsh/02_completion.zsh"

# Source prompt if starship is not available
if ! command -v starship &>/dev/null; then
    source "${DOTS_DIR}/zsh/01_prompt.zsh"
fi

# Source optional modules as needed
source "${DOTS_DIR}/zsh/python.zsh"
source "${DOTS_DIR}/zsh/git.zsh"
# ... etc
```

## Dependencies

### Core Dependencies
- **00_prelude.zsh**: 
  - Optional: `eza` (better ls), `bat` (better cat), `fzf` (fuzzy finder)
  - Optional: `starship` (prompt - disables 01_prompt.zsh)

### Module-Specific Dependencies
- **python.zsh**: `uv` (recommended), `mise` (for version management)
- **llm.zsh**: `llm`, `jq`, `ttok`, `files-to-prompt`
- **nav.zsh**: `zoxide` (for j/ji commands), `fzf` (for interactive selection)
- **file.zsh**: `fzf`, `rsync` (for progress bars), `trash` (macOS) or `gio` (Linux)
- **process.zsh**: `fzf`, `htop`/`btop` (better top)
- **ssh.zsh**: `fzf`, `sshfs` (for mounting)
- **docker.zsh**: `docker`, `fzf`, `jq`, `trivy` (for security scanning)
- **net.zsh**: `jq`, `mtr`, `speedtest-cli`, `nethogs`
- **arch.zsh**: Arch Linux only, `fzf`, `yay` (AUR helper), `expac`, `reflector`
- **deb.zsh**: Debian/Ubuntu only, `fzf`, `apt-file`
- **ffmpeg.zsh**: `ffmpeg`, `jq`
- **cmus.zsh**: `cmus`
- **evalcache.zsh**: No dependencies, but caches tools if present

### Recommended Tools
For the best experience, install:
```bash
# macOS (using Homebrew)
brew install fzf zoxide eza bat jq rsync trash htop mtr speedtest-cli

# Linux (Debian/Ubuntu)
apt install fzf zoxide eza bat jq rsync htop mtr speedtest-cli

# UV for Python development
curl -LsSf https://astral.sh/uv/install.sh | sh
```

## Customization

The prelude module checks for and uses modern replacements if available:
- `eza` instead of `ls`
- `bat` instead of `cat`
- `starship` for prompt (disables 01_prompt.zsh)