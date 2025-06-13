# tiny virtualenv manager
# using [[ -n $VAR ]] rather than [[ -v VAR ]] here for compatibility with
# zsh 5.0.2 (released 2012-12-21). thanks, Amazon Linux! Thamazonlinux.
export V_VIRTUALENV_HOME="${HOME}/.virtualenvs"

# 'raw' list without python versions, for zsh completion
function v_virtualenv_list_raw {
    local NAME
    local VER
    for python in $(echo "${V_VIRTUALENV_HOME}"/*/bin/python | sort); do
        NAME=$(echo "$python" | sed -E -e "s@${V_VIRTUALENV_HOME}/(.*)/bin/python@\1@g")
        echo "${NAME}"
    done
}

# list virtualenvs with python versions
function v_virtualenv_list {
    local NAME
    local VER
    for python in $(echo "${V_VIRTUALENV_HOME}"/*/bin/python | sort); do
        NAME=$(echo "$python" | sed -E -e "s@${V_VIRTUALENV_HOME}/(.*)/bin/python@\1@g")
        VER=$($python -V | awk '{print $2}')
        echo "${NAME} (${VER})"
    done
}

# upgrade virtualenv to use the current python version
function v_virtualenv_upgrade {
    local -r V_ENV=$1
    local -r V_DIR="$V_VIRTUALENV_HOME/$V_ENV"
    if [ ! -e "$V_DIR" ]; then
        echo "Virtual environment does not exist: '$V_ENV'"
        return 127
    fi
    python3 -m venv --upgrade "$V_DIR"
}

# create a new virtual environment
function v_virtualenv_new {
    local -r V_ENV=$1
    local -r V_DIR="$V_VIRTUALENV_HOME/$V_ENV"
    if [ -e "$V_DIR" ]; then
        echo "Virtual environment already exists: '$V_ENV'"
        return 127
    fi
    python3 -m venv "$V_DIR" --prompt "$V_ENV" --upgrade-deps
}

function v_virtualenv_rm {
    local -r V_ENV=$1
    local -r V_ENV_DIR="${V_VIRTUALENV_HOME}/${V_DIR}"
    if [ -e V_ENV_DIR ]; then
        rm -r "$V_ENV_DIR"
    else
        echo "Virtual environment does not exist: '$V_ENV'"
        return 127
    fi
}

function v_virtualenv_switch {
    local -r V_ENV=$1
    local -r V_ACTIVATE="${V_VIRTUALENV_HOME}/${V_ENV}/bin/activate"
    if [ ! -f "${V_ACTIVATE}" ]; then
        echo "No such virtual environment: '${V_ENV}'"
        return 127
    fi
    if [[ -n $VIRTUAL_ENV ]]; then
        deactivate
    fi
    source "${V_ACTIVATE}"
}

function v_virtualenv_help {
    echo "v :: ${V_VIRTUALENV_HOME}"
    echo
    echo "Usage: v                  list virtualenvs OR deactivate current virtualenv"
    echo "Usage: v <virtualenv>     activate virtualenv"
    echo
    echo "Usage: v <command> [<args>]"
    echo
    echo "      -d / --deactivate   - Deactivate the current virtualenv"
    echo "      -h / --help         - Print this message"
    echo "      -l / --list         - List virtualenvs"
    echo "      -n / --new          - Create a new virtualenv"

}

function v {
    if [[ $# -eq 0 ]]; then
        if [[ -n $VIRTUAL_ENV ]]; then
            deactivate
        else
            v_virtualenv_list
        fi
        return
    fi

    case "$1" in
        -d|--deactivate)
            if [[ -n $VIRTUAL_ENV ]]; then
                deactivate
            else
                echo "No virtual environment currently active."
            fi
            ;;
        -h|--help)
            v_virtualenv_help
            ;;
        -l|--list)
            shift
            v_virtualenv_list "$@"
            ;;
        -n|--new)
            shift;
            v_virtualenv_new "$@"
            ;;
        -u|--upgrade)
            shift;
            v_virtualenv_upgrade "$@"
            ;;
        *)
            v_virtualenv_switch "$@"
            ;;
    esac
}

function v_install_completion {
    _v_virtualenv_list () {
        reply=( $(v_virtualenv_list_raw) )
    }
    compctl -K _v_virtualenv_list v
}

# Create virtualenv with specific Python version (uv only)
function v_virtualenv_python {
    if [[ $# -ne 2 ]]; then
        echo "Usage: v -p <python_version> <env_name>"
        echo "Example: v -p 3.11 myenv"
        return 1
    fi
    
    if [[ ! -x "$(command -v uv)" ]]; then
        echo "This feature requires uv. Install with: curl -LsSf https://astral.sh/uv/install.sh | sh"
        return 1
    fi
    
    local py_version="$1"
    local env_name="$2"
    local env_dir="$V_VIRTUALENV_HOME/$env_name"
    
    if [ -e "$env_dir" ]; then
        echo "Virtual environment already exists: '$env_name'"
        return 127
    fi
    
    echo "Creating virtual environment '$env_name' with Python $py_version..."
    uv venv "$env_dir" --python "$py_version" --prompt "$env_name"
}

# Install packages in current virtual environment
function v_virtualenv_install {
    if [[ -z $VIRTUAL_ENV ]]; then
        echo "No virtual environment is active"
        return 1
    fi
    
    if [[ $# -eq 0 ]]; then
        echo "Usage: v -i <package> [package...]"
        return 1
    fi
    
    if [[ -x "$(command -v uv)" ]]; then
        uv pip install "$@"
    else
        pip install "$@"
    fi
}

# Enhanced virtualenv listing with Python versions and package counts
function v_virtualenv_list_detailed {
    echo "Virtual Environments in $V_VIRTUALENV_HOME:"
    echo "-------------------------------------------"
    
    for python in $(echo "${V_VIRTUALENV_HOME}"/*/bin/python | sort); do
        if [[ -f "$python" ]]; then
            local name=$(echo "$python" | sed -E -e "s@${V_VIRTUALENV_HOME}/(.*)/bin/python@\1@g")
            local ver=$($python -V 2>&1 | awk '{print $2}')
            local pkg_count=0
            
            if [[ -f "${V_VIRTUALENV_HOME}/${name}/bin/pip" ]]; then
                pkg_count=$("${V_VIRTUALENV_HOME}/${name}/bin/pip" list 2>/dev/null | tail -n +3 | wc -l)
            fi
            
            printf "%-20s Python %-10s %3d packages" "$name" "$ver" "$pkg_count"
            
            if [[ "$VIRTUAL_ENV" == "${V_VIRTUALENV_HOME}/${name}" ]]; then
                printf " [ACTIVE]"
            fi
            echo
        fi
    done
}

# Interactive virtualenv selection with fzf
if [[ -x "$(command -v fzf)" ]]; then
    function vi {
        local env=$(v_virtualenv_list_raw | fzf --preview "echo 'Python version:'; ${V_VIRTUALENV_HOME}/{}/bin/python --version 2>&1; echo; echo 'Installed packages:'; ${V_VIRTUALENV_HOME}/{}/bin/pip list 2>/dev/null | head -20")
        if [[ -n "$env" ]]; then
            v_virtualenv_switch "$env"
        fi
    }
fi

v_install_completion
