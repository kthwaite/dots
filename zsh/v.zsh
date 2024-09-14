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

v_install_completion
