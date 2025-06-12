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

- **python.zsh** - Python development utilities
  - `pytouch` / `pt` - Create Python package structures
  - `vvv` - Virtual environment management
  - `auto_activate_venv` - Auto-activate venvs when entering directories
- **git.zsh** - Git helper functions
  - `whatchanged` - Show commits since a date
  - `clone_subdir` - Clone specific subdirectories
- **llm.zsh** - LLM integration utilities
  - `suggest-commit` - Generate commit messages
  - `files-to-tokens` - Count tokens in files
  - Requires: `llm`, `jq`, `ttok`, `files-to-prompt`
- **brew.zsh** - Homebrew helpers
  - `brew-list-installed` - List user-installed packages
- **evalcache.zsh** - Cache expensive shell commands
- **whoa.zsh** - Git safety (warns on `git add .`)
- **arch.zsh** - Arch Linux utilities
- **cmus.zsh** - cmus music player helpers
- **deb.zsh** - Debian/Ubuntu utilities
- **ffmpeg.zsh** - FFmpeg helper functions
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

Some modules require external tools:
- **llm.zsh**: `llm`, `jq`, `ttok`, `files-to-prompt`
- **python.zsh**: Works best with `mise` and `uv`
- **00_prelude.zsh**: Optional tools like `eza`, `bat`, `fzf` enhance functionality

## Customization

The prelude module checks for and uses modern replacements if available:
- `eza` instead of `ls`
- `bat` instead of `cat`
- `starship` for prompt (disables 01_prompt.zsh)