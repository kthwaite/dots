# ~/.config/zsh/widgets.zsh


# -----------------------------------------------------------------------------
# _zle_read_file_exact FILE
#
# Read a whole file into $REPLY *without losing trailing newlines*.
#
# Why not:
#
#     REPLY=$(<"$1")
#
# ?
#
# Because shell command substitution deliberately strips trailing newlines.
#
# We append a NUL byte before command substitution and remove it afterwards.
# Because the output no longer ends in newline, any newlines belonging to the
# actual file survive.
# -----------------------------------------------------------------------------

function _zle_read_file_exact() {
    local file="$1"

    REPLY="$(
        cat -- "$file"
        print -rn -- $'\0'
    )"

    REPLY="${REPLY%$'\0'}"
}


# -----------------------------------------------------------------------------
# _zle_scrollback_editor MODE
#
# Shared implementation.
#
# MODE is either:
#
#     pick
#         visual-select terminal text and insert it at $CURSOR
#
#     compose
#         edit the complete shell $BUFFER alongside terminal scrollback
#
# This isn't itself registered as a ZLE widget.  The tiny wrappers below are.
# -----------------------------------------------------------------------------

function _zle_scrollback_editor() {
    emulate -L zsh

    local mode="$1"

    local workdir
    local scrollback_file
    local command_file
    local prefix_file
    local result_file
    local cursor_result_file
    local accepted_file

    local nvim_status

    # -------------------------------------------------------------------------
    # One temporary directory is easier to manage than half a dozen mktemp
    # calls.
    # -------------------------------------------------------------------------

    workdir=$(
        mktemp -d "${TMPDIR:-/tmp}/zle-scrollback.XXXXXX"
    ) || {
        zle -M "scrollback: couldn't create temporary directory"
        return 1
    }

    scrollback_file="$workdir/scrollback"
    command_file="$workdir/command"
    prefix_file="$workdir/prefix"

    result_file="$workdir/result"
    cursor_result_file="$workdir/cursor-result"

    accepted_file="$workdir/accepted"


    # -------------------------------------------------------------------------
    # Snapshot the complete Zellij scrollback.
    #
    # --full means scrollback + visible viewport.
    #
    # We intentionally omit --ansi: this leaves us plain text rather than
    # embedding terminal colour/control sequences.
    # -------------------------------------------------------------------------

    if ! zellij action dump-screen --full > "$scrollback_file"; then
        rm -rf -- "$workdir"

        zle -M "scrollback: couldn't dump current Zellij pane"

        return 1
    fi


    # -------------------------------------------------------------------------
    # Save ZLE state for compose mode.
    #
    # print -n is important: we want the exact string, not an extra newline.
    #
    # $BUFFER
    #     entire current command
    #
    # $LBUFFER
    #     portion before the current cursor
    #
    # Saving the latter lets Neovim position its cursor precisely.
    # -------------------------------------------------------------------------

    print -rn -- "$BUFFER"  > "$command_file"
    print -rn -- "$LBUFFER" > "$prefix_file"


    # These may legitimately contain nothing, so acceptance is signalled with
    # a separate file rather than testing result-file size.
    : > "$result_file"
    : > "$cursor_result_file"

    rm -f -- "$accepted_file"


    # -------------------------------------------------------------------------
    # Let the full-screen application take control of the terminal.
    # -------------------------------------------------------------------------

    zle -I


    # -------------------------------------------------------------------------
    # Start Neovim.
    #
    # We load the ordinary Neovim config deliberately:
    #
    #   * your mappings work
    #   * your search tools work
    #   * text objects work
    #   * shell syntax highlighting can work in compose mode
    #
    # -n disables swapfiles for this disposable session.
    # -------------------------------------------------------------------------

    ZLE_SCROLLBACK_MODE="$mode" \
    ZLE_SCROLLBACK_RESULT="$result_file" \
    ZLE_SCROLLBACK_ACCEPTED="$accepted_file" \
    ZLE_SCROLLBACK_COMMAND="$command_file" \
    ZLE_SCROLLBACK_PREFIX="$prefix_file" \
    ZLE_SCROLLBACK_CURSOR_RESULT="$cursor_result_file" \
        nvim \
            -n \
            "$scrollback_file" \
            -c 'lua require("k6e.scrollback_pick").setup()'

    nvim_status=$?


    # -------------------------------------------------------------------------
    # Only alter ZLE if Neovim explicitly accepted.
    #
    # Merely quitting Neovim, crashing it, Ctrl-C'ing it, etc. therefore leaves
    # the current shell command untouched.
    # -------------------------------------------------------------------------

    if (( nvim_status == 0 )) && [[ -s "$accepted_file" ]]; then

        case "$mode" in

            pick)
                # -------------------------------------------------------------
                # Quick picker:
                #
                # insert selected terminal text immediately before the ZLE
                # cursor. Assigning LBUFFER automatically advances CURSOR.
                # -------------------------------------------------------------

                _zle_read_file_exact "$result_file"

                LBUFFER+="$REPLY"
                ;;


            compose)
                # -------------------------------------------------------------
                # Composer:
                #
                # Replace the ENTIRE ZLE edit buffer.
                # -------------------------------------------------------------

                local new_buffer
                local new_prefix

                _zle_read_file_exact "$result_file"
                new_buffer="$REPLY"

                _zle_read_file_exact "$cursor_result_file"
                new_prefix="$REPLY"

                BUFFER="$new_buffer"

                # ${#...} is evaluated by zsh itself, so we don't have to make
                # Lua and zsh agree about UTF-8 byte vs character offsets.
                CURSOR=${#new_prefix}
                ;;


            *)
                zle -M "scrollback: unknown mode '$mode'"
                ;;
        esac
    fi


    # -------------------------------------------------------------------------
    # Cleanup and restore the ordinary shell UI.
    # -------------------------------------------------------------------------

    rm -rf -- "$workdir"

    zle reset-prompt
}


# -----------------------------------------------------------------------------
# Public widgets
# -----------------------------------------------------------------------------

function scrollback-pick() {
    _zle_scrollback_editor pick
}

function scrollback-compose() {
    _zle_scrollback_editor compose
}


zle -N scrollback-pick
zle -N scrollback-compose


# -----------------------------------------------------------------------------
# Bindings
#
# Alt-s       quick picker
# Alt-Shift-s composer
#
# Bind in all modes in which you're plausibly going to want them.
# -----------------------------------------------------------------------------

for keymap in emacs viins vicmd; do
    bindkey -M "$keymap" '^X^P' scrollback-pick
    # legacy binding
    bindkey -M "$keymap" '^X^C' scrollback-compose
    bindkey -M vicmd 'v' scrollback-compose
done
