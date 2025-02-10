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

# Check whether 'pt' is already declared as an alias or command
if ! type pt >/dev/null 2>&1; then
    alias pt=pytouch
    # echo "Alias 'pt' created for pytouch"
else
    # echo "Warning: 'pt' is already declared as a command or alias. Skipping alias creation."
fi

# -- local dir venv
function vvv() {
    if [[ -v VIRTUAL_ENV ]]; then
        deactivate
    else
        if [[ ! -d .venv ]]; then
            name=${$(basename $(pwd))// /_}
            ver=$(python --version | cut -d ' ' -f 2)
            venv_prompt="$name-$ver"
            echo "Creating venv with name '$venv_prompt'"

            if [[ -x "$(command -v uv)" ]]; then
                uv venv .venv --seed --prompt $venv_prompt
            else
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
        if [[ -x "$(command -v mise)" ]]; then
            source .venv/bin/activate
            fi
    fi
}
