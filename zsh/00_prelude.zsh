#-------------------------------------------------------------------------------
#[    prelude                                                                  ]
#-------------------------------------------------------------------------------

# -- keybinds
export KEYTIMEOUT=20
# vi mode
bindkey -v
# Allow command line editing in an external editor.
autoload -Uz edit-command-line
zle -N edit-command-line
# custom vikeys
bindkey -M viins 'jk' vi-cmd-mode
bindkey -M vicmd "\C-X\C-E" edit-command-line
bindkey -M vicmd "^[[3~" delete-char
# ctrl-right/left for word skip
bindkey "^[[1;5C" forward-word
bindkey "^[[1;5D" backward-word

# allow comments in shell
set -k


#==== Env vars =================================================================
#

# -- language & locale
if [[ -z "$LANG" ]]; then
    export LANG='en_GB.UTF-8'
fi

if [[ "$OSTYPE" == "darwin"* ]]; then
    export BROWSER='open'
    mant() {
        local -r MANPAGE=$1
        man -t "$MANPAGE" | open -f -a Preview
    }
elif [[ "$OSTYPE" == cygwin* ]]; then
  alias open='cygstart'
else
  alias open='xdg-open'
fi

# -- editor
if [[ -x "$(command -v nvim)" ]]; then
    export EDITOR='nvim'
    alias vi='nvim'
    alias vim='nvim'
    alias v='nvim'
else
    export EDITOR='vim'
    alias v='vim'
fi

export VISUAL=$EDITOR
export VISUDO=$EDITOR
export SUDO_EDITOR=$EDITOR

# -- pager
export PAGER='less'
# Set the default Less options.
# Mouse-wheel scrolling has been disabled by -X (disable screen clearing).
# Remove -X and -F (exit if the content fits on one screen) to enable it.
export LESS='-F -g -i -M -R -S -w -X -z-4'

# -- rust
if [[ -x "$(command -v rustc)" ]]; then
    export RUST_ROOT="$(rustc --print sysroot)"
    export RUST_SRC_PATH="${RUST_ROOT}/lib/rustlib/src/rust/src/"
fi


#
# Smart URLs
#

autoload -Uz url-quote-magic
zle -N self-insert url-quote-magic

#
# Jobs
#

setopt LONG_LIST_JOBS     # List jobs in the long format by default.
setopt AUTO_RESUME        # Attempt to resume existing job before creating a new process.
setopt NOTIFY             # Report status of background jobs immediately.
unsetopt BG_NICE          # Don't run all background jobs at a lower priority.
unsetopt HUP              # Don't kill jobs on shell exit.
unsetopt CHECK_JOBS       # Don't report on jobs when shell exit.

#
# General
#

setopt BRACE_CCL          # Allow brace character class list expansion.
setopt COMBINING_CHARS    # Combine zero-length punctuation characters (accents)
                          # with the base character.
setopt RC_QUOTES          # Allow 'Henry''s Garage' instead of 'Henry'\''s Garage'.
unsetopt MAIL_WARNING     # Don't print a warning message if a mail file has been accessed.
#
# Termcap
#

# FIXME
if zstyle -t ':prezto:environment:termcap' color; then
  export LESS_TERMCAP_mb=$'\E[01;31m'      # Begins blinking.
  export LESS_TERMCAP_md=$'\E[01;31m'      # Begins bold.
  export LESS_TERMCAP_me=$'\E[0m'          # Ends mode.
  export LESS_TERMCAP_se=$'\E[0m'          # Ends standout-mode.
  export LESS_TERMCAP_so=$'\E[00;47;30m'   # Begins standout-mode.
  export LESS_TERMCAP_ue=$'\E[0m'          # Ends underline.
  export LESS_TERMCAP_us=$'\E[01;32m'      # Begins underline.
fi

#==== zsh ==================================================================

# == history
#

# -- Variables
HISTFILE="${ZDOTDIR:-$HOME}/.zhistory"       # The path to the history file.
HISTSIZE=10000                   # The maximum number of events to save in the internal history.
SAVEHIST=10000                   # The maximum number of events to save in the history file.

# -- Options
setopt BANG_HIST                 # Treat the '!' character specially during expansion.
setopt EXTENDED_HISTORY          # Write the history file in the ':start:elapsed;command' format.
setopt INC_APPEND_HISTORY        # Write to the history file immediately, not when the shell exits.
setopt SHARE_HISTORY             # Share history between all sessions.
setopt HIST_EXPIRE_DUPS_FIRST    # Expire a duplicate event first when trimming history.
setopt HIST_IGNORE_DUPS          # Do not record an event that was just recorded again.
setopt HIST_IGNORE_ALL_DUPS      # Delete an old recorded event if a new event is a duplicate.
setopt HIST_FIND_NO_DUPS         # Do not display a previously found event.
setopt HIST_IGNORE_SPACE         # Do not record an event starting with a space.
setopt HIST_SAVE_NO_DUPS         # Do not write a duplicate event to the history file.
setopt HIST_VERIFY               # Do not execute immediately upon history expansion.
setopt HIST_BEEP                 # Beep when accessing non-existent history.

# == directory
#
setopt AUTO_CD              # Auto changes to a directory without typing cd.
setopt AUTO_PUSHD           # Push the old directory onto the stack on cd.
setopt PUSHD_IGNORE_DUPS    # Do not store duplicates in the stack.
setopt PUSHD_SILENT         # Do not print the directory stack after pushd or popd.
setopt PUSHD_TO_HOME        # Push to home directory when no argument is given.
setopt CDABLE_VARS          # Change directory to a path stored in a variable.
setopt AUTO_NAME_DIRS       # Auto add variable-stored paths to ~ list.
setopt MULTIOS              # Write to multiple descriptors.
setopt EXTENDED_GLOB        # Use extended globbing syntax.
unsetopt CLOBBER            # Do not overwrite existing files with > and >>.
                            # Use >! and >>! to bypass.
alias d='dirs -v'
for index ({1..9}) alias "$index"="cd +${index}"; unset index

# -- autocompletion
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE='fg=8'

#==== Aliases ==================================================================
#
# -- nocorrect common
alias ack='nocorrect ack'
alias cd='nocorrect cd'
alias cp='nocorrect cp'
alias dust='nocorrect dust'
alias fd='nocorrect fd'
alias grep='nocorrect grep'
alias jq='nocorrect jq'
alias ln='nocorrect ln'
alias man='nocorrect man'
alias mkdir='nocorrect mkdir'
alias mv='nocorrect mv'
alias psql='nocorrect psql'
alias rg='nocorrect rg'
alias rm='nocorrect rm'

# alias rm='rm -i'
alias rm="${aliases[rm]:-rm} -i"
# show memory size in megabytes by default
alias free='free -m'
alias diskuse='df --si | tail -n +2 | sort -hk3'

# -- eza
if [[ -x "$(command -v eza)" ]]; then
    # default
    alias l="eza -alg --group-directories-first"
    # as `l` but ordered by modified-time
    alias lh='eza -la --group-directories-first -s modified'
    # as `l` with git status
    alias lg='eza -la --group-directories-first --git'
    # list directory tree from cwd
    alias dt="eza -algbT"
    # as `dt` with git status
    alias dtg="eza -algbT --git --git-ignore -I '.git'"
else
# -- ls
    alias l='ls -tlha'
    alias lr='ls -rtlha'
    alias ll="ls -alh"
fi

if [[ -x "$(command -v bat)" ]]; then
    alias bat='nocorrect bat'
    # if `bat` is present, replace cat(1) with bat's 'plain' mode
    alias cat="nocorrect bat --plain"
fi

# -- python
alias python='python3'
alias p='python3'

# -- pip
# if uv is present, use it to install packages
if [[ -x "$(command -v uv)" ]]; then
    alias pip='uv pip'
    alias piu='uv pip install --upgrade'
    alias pio='uv pip list --outdated'
    alias pu='uv pip uninstall'
else
    alias pip='python -m pip'
    alias piu='python -m pip install --upgrade'
    alias pio='python -m pip list --outdated'
    alias pu='python -m pip uninstall'
fi

# -- java
alias what-javas='/usr/libexec/java_home -V'


# -- node
export NEXT_TELEMETRY_DISABLED=1


# -- rsync
alias rarm='rsync -ah --progress --remove-source-files'
alias rapp='rsync -ah --progress --partial'

# -- nvim
# nvim without ShaDa
alias novim='nvim -i NONE'
