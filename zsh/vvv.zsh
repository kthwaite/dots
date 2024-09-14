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
        fi
        source .venv/bin/activate
    fi
}
