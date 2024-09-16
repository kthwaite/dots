# list commits and changed files since a given date
function whatchanged() {
    if [[ $# -eq 0 ]]; then
        echo 'Usage: whatchanged [SINCE_DATE]'
        return
    fi
    git whatchanged --since=$1 --numstat --oneline
}
