# Create directory structure for Python packages, with verbosity and help text.
pytouch() {
    # Show help text if -h or --help is passed
    if [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
        cat << EOF
Usage: pytouch [OPTIONS] module1 [module2] ...

Create directory structures for Python modules (packages),
ensuring each directory contains an empty __init__.py file.

Example:
  pytouch mypackage.subpackage.module

Which creates:
  mypackage/
      __init__.py
      subpackage/
          __init__.py
          module/
              __init__.py

Options:
  -h, --help    Show this help text and exit
EOF
  return 0
    fi

    # Process each module argument
    for module in "$@"; do
        # Initialize the base path
        mod_path=""

        # Split the module string by dots into an array
        parts=(${module//./ })

        # Iterate over each part to build the directory structure
        for part in "${parts[@]}"; do
            # Append the current part to the path
            if [ -z "$mod_path" ]; then
                path="$part"
            else
                path="$mod_path/$part"
            fi

            # Create the directory if it doesn't exist, and be verbose about it
            if [ ! -d "$mod_path" ]; then
                mkdir -p "$mod_path"
                echo "Created directory: $mod_path"
            else
                echo "Directory already exists: $mod_path"
            fi

            # Create an empty __init__.py file inside the directory, and be verbose about it
            if [ ! -f "$mod_path/__init__.py" ]; then
                touch "$mod_path/__init__.py"
                echo "Created file: $mod_path/__init__.py"
            else
                echo "File already exists: $mod_path/__init__.py"
            fi
        done
    done
}

alias pt=pytouch

# -- local dir venv (uv-first approach)
function vvv() {
    if [[ -v VIRTUAL_ENV ]]; then
        deactivate
    else
        if [[ ! -d .venv ]]; then
            name=${$(basename $(pwd))// /_}
            
            if [[ -x "$(command -v uv)" ]]; then
                # Use uv's project initialization if no pyproject.toml exists
                if [[ ! -f pyproject.toml ]]; then
                    echo "Initializing uv project..."
                    uv init --name "$name" --no-readme
                else
                    echo "Creating venv with uv..."
                    uv venv .venv --prompt "$name"
                fi
            else
                ver=$(python --version | cut -d ' ' -f 2)
                venv_prompt="$name-$ver"
                echo "Creating venv with name '$venv_prompt'"
                python3 -m venv .venv --prompt $venv_prompt --upgrade-deps $@
            fi

            if [[ -x "$(command -v mise)" ]]; then
                if [[ ! -f mise.toml ]] && [[ ! -f .mise.toml ]]; then
                    echo "Creating mise.toml file..."
                    cat > mise.toml << EOF
[env]
_.python.venv = ".venv"
EOF
                fi
            fi
        fi
        source .venv/bin/activate
    fi
}


# -- UV specific helpers
if [[ -x "$(command -v uv)" ]]; then
    # Quick aliases for common uv operations
    alias uvs='uv sync'
    alias uva='uv add'
    alias uvr='uv run'
    alias uvn='uv run nvim'
    alias uvl='uv lock'
    alias uvi='uv pip install'
    alias uviu='uv pip install --upgrade'
    
    # Initialize a new uv project with common setup
    function uv-init() {
        local name="${1:-$(basename $(pwd))}"
        uv init --name "$name" --no-readme
        uv add --dev ruff ty pytest pytest-cov
        uv sync
    }
    
    # Quick Python version switcher for current project
    function uvpy() {
        if [[ $# -eq 0 ]]; then
            echo "Current Python: $(uv run python --version 2>&1)"
            echo "Available versions:"
            uv python list --installed
        else
            uv python pin "$1"
            echo "Pinned Python to $1"
        fi
    }
    
    # Install common CLI tools via uv
    function uv-tools() {
        local tools=("ruff" "ty" "ipython" "httpie" )
        echo "Installing common Python CLI tools..."
        for tool in "${tools[@]}"; do
            echo "Installing $tool..."
            uv tool install "$tool"
        done
    }
    
    # Show outdated packages in current project
    function uv-outdated() {
        if [[ -f "pyproject.toml" ]]; then
            uv pip list --outdated
        else
            echo "No pyproject.toml found in current directory"
        fi
    }
fi
