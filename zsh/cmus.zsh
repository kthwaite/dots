# refresh cmus library
function refresh-cmus {
    if [[ -z $CMUS_LIBRARY ]]; then
        echo "CMUS_LIBRARY is not set"
        return
    fi
    cmus-remote -C clear
    cmus-remote -C "add $CMUS_LIBRARY"
    cmus-remote -C "update-cache --force"
}
