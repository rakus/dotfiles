################################################################################
#
#  Aliases
#
#  Ralf Schandl
#
################################################################################
#
# shellcheck shell=bash

[ -n "$BASH_DEBUG" ] &&       echo Start sourcing .aliases
[ "$BASH_DEBUG" = "FULL" ] && set -x


alias wlanreset="sudo killall wpa_supplicant"

alias isodate='date +%Y-%m-%dT%H:%M:%S.%03N%:z'

# list my local git repos
function gitrepos
{
    (
    cd "$HOME/Documents/Privat/diskstation/gitolite-admin" || return 1
    remote=$(git remote -v | head -1 | cut -d $'\t' -f2 | cut -d: -f1)
    grep repo < conf/gitolite.conf | sed "s/^.* /${remote}:/"
    )
}


function addToPath
{
    local dir
    dir=$(readlink -f "$1")
    if [ -d "$dir" ] && [[ ":$PATH:" != *":$dir:"* ]]; then
        PATH="$PATH:$dir"
    fi
}

# Quick calculation like 'calc 3+2'
# Note: 'calc 2x3' is interpreted as 'calc 2*3'
function calc
{
    echo "scale=2; $*" | sed "s/x/*/g" | bc
}

# reads file/dir names from stdin and only print to stdout if they exist
function exist_filter
{
    local d
    while read -r d; do
        [[ -e $d ]] && echo "$d"
    done
}

# reads names from stdin and only print to stdout if name is a existing
# directory
function dir_filter
{
    local d
    while read -r d; do
        [[ -d "$d" ]] && echo "$d"
    done
}

# reads names from stdin and only print to stdout if name is a existing
# regular file
function file_filter
{
    local f
    while read -r f; do
        [[ -f "$f" ]] && echo "$f"
    done
}

function exe_filter
{
    local f
    while read -r f; do
        [[ -f "$f" ]] && [[ -x "$f" ]] && echo "$f"
    done
}

# read text from stdin and prefix it with the current timestamp
# Only available with gawk (but without milliseconds):
# alias ts_prefix="awk '{print strftime(\"%Y-%m-%dT%H:%M:%S\"), \$0;}'"
function ts_prefix
{
    local l
    while read -r l; do
        echo "$(date "+%Y-%m-%dT%H:%M:%S.%03N"): $l"
    done
}

# filters out ANSI escape sequences
esc_filter()
{
    local l
    while read -r l; do
        # shellcheck disable=SC2001
        echo "$l" | sed "s/\x1B\[[^A-Za-z]*[A-Za-z]//g"
    done
}

# filters out color codes
color_filter()
{
    local l
    while read -r l; do
        echo "$l" |  sed -r "s/\x1B\[([0-9]{1,3}(;[0-9]{1,3})?)?[m|K]//g"
    done
}

numbered()
{
    local i=1
    while read -r l; do
        printf "%6d\t%s\n" $i "$l"
        (( i+=1 ))
    done
}

#
# Prints the scp-path of the given filename
# scp-path is: <user>@<host>:<full qualified filename>
# Print a warning if is not readable.
#
function scppath
{
    local fqFile
    if [[ $1 =~ ^/ ]]; then
        # absolut path
        fqFile=$1
    else
        fqFile=$(readlink -f "$PWD/$1")
    fi

    if [ ! -e "$fqFile" ]; then
        echo >&2 "WARNING: File does not exist: $fqFile"
    else
        if [ ! -r "$fqFile" ]; then
            echo >&2 "WARNING: File not readable: $fqFile"
        fi
        if [ ! -w "$fqFile" ]; then
            echo >&2 "WARNING: File not writable: $fqFile"
        fi
    fi

    echo "$USER@$(hostname):$fqFile"
}

#
# Midnight commander function.
# On Exit change to the directory MC showed.
#
function mc
{
    MC_USER=$(id | sed 's/[^(]*(//;s/).*//')
    MC_PWD_FILE="${TMPDIR-/tmp}/mc-$MC_USER/mc.pwd.$$"
    /usr/bin/mc -P "$MC_PWD_FILE" "$@"

    if test -r "$MC_PWD_FILE"; then
        MC_PWD="$(cat "$MC_PWD_FILE")"
        if test -n "$MC_PWD" && test -d "$MC_PWD"; then
            # shellcheck disable=SC2164
            cd "$MC_PWD"
        fi
        unset MC_PWD
    fi

    rm -f "$MC_PWD_FILE"
    unset MC_PWD_FILE
}

# grep history
function gh
{
    HISTTIMEFORMAT='' history | grep "$@" | grep -v "^ *[0-9][0-9]*  ght\\? "| uniq -f1
}

function ght
{
    history | grep "$@" | grep -v "^ *[0-9][0-9]*  2[^ ]* ght\\? "
}

#---------[ Directory Handling ]-----------------------------------------------

#
# cd with multiple arguments
#
# 'cd sr ma ja' does 'cd sr*/ma*/ja*'
# If multiple matches uses select.
#
alias cd=cd_wc
function cd_wc
{
    typeset OPTIND OPTARG dir o EL PE E AT

    while getopts "LPe@" o "$@"; do
        case $o in
            L) EL=true
                ;;
            P) PE=true
                ;;
            e) E=true
                ;;
            @) AT=true
                ;;
            *)
                echo 'cd: usage: cd [-L|[-P [-e]] [-@]] [dir]'
                return 1
                ;;
        esac
    done
    shift $((OPTIND - 1))

    if [ $# -eq 0 ]; then
        dir="$HOME"
    elif [ $# -eq 1 ]; then
        dir="$1"
    else
        # shellcheck disable=SC2155
        typeset dirPattern=$(printf "%q*/" "$@" | sed 's%\\\*%*%g;s%/\*/%/%g;s%///*%/%g')
        # shellcheck disable=SC2086 # dirpattern unquoted due to wildcards
        mapfile -d$'\n' -t dirs < <(ls -d ${dirPattern} 2>/dev/null)
        if [ ${#dirs[@]} -eq 0 ]; then
            echo >&2 "cd: $dirPattern: No such directory"
            return 1
        elif [ ${#dirs[@]} -eq 1 ]; then
            dir=${dirs[0]}
        else
            typeset sel
            dir=$(select sel in "${dirs[@]}"; do echo "$sel"; return 0; done)
            if [ -z "$dir" ]; then
                return 1
            fi
        fi
    fi

    # shellcheck disable=SC2164
    builtin cd ${EL+-L} ${PE+-P} ${E+-e} ${AT+-@} "$dir"
}

#
# Change directory upwarts
#
#     up             - Up one level
#     up <number>    - Up <number> levels
#     up <string>    - Up to dir starting with <string>
#     up /<number>   - Up to dir starting with <number>
#
function up
{
    typeset arg cdstr
    if [ $# -gt 1 ]; then
        echo >&2 "To many arguments."
        return 1
    fi
    arg=${1:-1}
    if [ -z "${arg//[0-9]/}" ]; then
        cdstr=$(printf '%0.s../' $(seq 1 "$arg"))
    else
        arg="${arg#/}"
        if [[ "$arg" = */ ]]; then
            arg="${arg%/}"
        else
            arg="${arg}[^/]*"
        fi
        cdstr=$(pwd | grep -o "^.*/${arg}/")
        if [ -z "$cdstr" ]; then
            echo >&2 "No parent dir matching '${arg//\[*/*}' found."
            return 1
        fi
    fi

    # shellcheck disable=SC2164
    builtin cd "$cdstr"
}

function _up_complete
{
    local cur opts dir
    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    cur=$(eval "echo ${cur}")
    dir="${PWD##/}"
    opts="${dir//\//\/$'\n'}"
    mapfile -d$'\n' -t COMPREPLY < <(compgen -W "${opts}" -- "${cur}")
    # Do escaping
    for ((i=0; i < ${#COMPREPLY[@]}; i++)); do
        COMPREPLY[i]=$(printf "%q" "${COMPREPLY[$i]}")
    done
    return 0
}
complete -F _up_complete up
complete -F _up_complete -

# changing directory
alias ..='up'
alias cd..='up 1'
alias -- -='up'
alias -- --='up 2'
alias -- ---='up 3'
alias -- ----='up 4'
alias -- -----='up 5'
alias -- ------='up 6'

function mkcd {
    [ -d "$1" ] && echo >&2 "WARNING: Directory '$1' already exists"
    # shellcheck disable=SC2164
    mkdir -p "$1" && 'cd' "$1"
}

#---------[ ALIASES ]----------------------------------------------------------

# delete vim backup files
#alias   rmbak='rm *~ .[A-Za-z]*~'
rmbak()
{
    typeset opt OPTIND OPTARG depth="-maxdepth 1" action="-delete"
    while getopts ":rn" opt; do
        case "$opt" in
            r) depth='' ;;
            n) action='' ;;
            "?")
                echo >&2 "Invalid option: -$OPTARG"
                echo >&2 "USAGE: rmbak [-rn]"
                echo >&2 "  -r recursive"
                echo >&2 "  -n dry-run - print files but don't delete"
                return 1
                ;;
        esac
    done
    # shellcheck disable=SC2086
    find . $depth -name \*~ -type f -print $action
}


# delete core and java core files
alias   rmcore='rm core core.*.dmp Snap.*.trc javacore.*.txt heapdump.*.phd'

# locate using local locatedb
alias   llocate='locate -d "$HOME/.locatedb"'
alias   olocate='locate -d "$HOME/OLD-PC/rks/.locatedb"'

#alias fq="readlink -f"
function fq
{
    local arg
    for arg in "${@:-.}"; do
        if [ -d "$arg" ]; then
            (cd "$arg" && pwd) || return 1
        else
            (fq "$(dirname "$arg")" | tr -d '\n'  && echo "/$(basename "$arg")") || return 1
        fi
    done
    return 0
}

function fqc
{
    #fq "$@" | xclip -f -selection clipboard
    local f
    f="$(fq "$@")"
    printf "%s" "$f" | xclip -selection clipboard
    echo "$f"
}

#alias clipboard="xclip -selection clipboard"

function clipboard
{
    if [ $# -gt 0 ]; then
        echo -n "$@" | xclip -f -selection clipboard
        echo
    else
        xclip -f -selection clipboard
    fi
}


# this and that
# alias   fixtty='printf "\e[?2004l";stty sane'
alias   fixtty='reset; stty sane; tput rs1; clear; echo -e "\033c"'
alias   cls='tput clear'
alias   qenv='set|grep -i -E'
alias   cp='cp -i'
alias   md='mkdir'

if command -v xdg-open &>/dev/null; then
    #alias uff=xdg-open
    UFF_CMD=xdg-open
elif command -v gnome-open &>/dev/null; then
    #alias uff=gnome-open
    UFF_CMD=gnome-open
elif command -v open &>/dev/null; then
    #alias uff=open
    UFF_CMD=open
elif command -v mimeopen &>/dev/null; then
    #function uff
    #{
    #    mimeopen "$@" &
    #}
    UFF_CMD=mimeopen
fi

if [ -n "$UFF_CMD" ]; then
# Shortcut to open files/directories
#  -- bin halt en Roihess
function uff
{
    case $# in
        0) echo >&2 "Usage: uff file [file...]"
            return 1
            ;;
        1)
            "$UFF_CMD" "$1"
            ;;
        *)
            for f in "$@"; do
                uff "$f"
            done
            ;;
    esac
}
else
    function uff
    {
        echo >&2 ""
        echo >&2 "  No tool for opening files found -- sorry"
        echo >&2 ""
        return 1
    }
fi


alias gop='gnome-open'

# user
alias   all="who | cut -d' ' -f1"
alias   who="who -uH"

# processes
alias   p='ps -ef|grep -v grep|grep '
alias   j='jobs -l'

# listing files
if [ -n "$LS_COLORS" ]; then
    alias ls='ls --color=auto'
fi
alias   l.='ls -dF .[!.]*'   # list hidden files only
alias   ls.='ls -dF .[!.]*'  # list hidden files only
alias   ll.='ls -dlF .[!.]*' # list hidden files only
alias   ll='ls -lF'          # list in long format
alias   dir='ls -lF'         # list in long format
alias   ltr='ls -ltr'
alias   lsr='ls -lSr'

#
# ff - find file
# Short for `find . -iname <filepattern>`
# Usage: ff [search-dir...] filepattern
#
ff()
{
    if [ $# -lt 1 ]; then
        echo "Usage: ff [search-dir...] <filepattern>"
        return 1
    fi
    local length=$(($#-1))
    local searchDirs=( "${@:1:$length}" )
    local name="${!#}"

    if [ ${#searchDirs[@]} -eq 0 ]; then
        find . -iname "$name"
   else
        find "${searchDirs[@]}" -iname "$name"
   fi
}
#alias   ff='find . -iname'

#ffg -i hallo *.vim
ffg()
{
    if [ $# -lt 2 ]; then
        echo "Usage: ffg <grep-parammeter> <filepattern>"
        return 1
    fi
    local length=$(($#-1))
    local grepargs=( "${@:1:$length}" )
    local fn="${!#}"

    find . -iname "$fn" -exec grep "${grepargs[@]}" {} /dev/null \;
}

# size of subdirs, sorted by size.
function dud {
    local fmt=( '--format=%9f' )
    if [[ "$1" == "-h" ]]; then
        shift
        fmt=( '--to=iec' '--format=%7.1f' )
    fi
    du -b --max-depth=1 "${@:-.}" | numfmt "${fmt[@]}" | sort -h
}


# lists the 25 biggest files recursively (doesn't change device)
function lsmax {
    local fmt=( '--format=%9f' )
    if [[ "$1" == "-h" ]]; then
        shift
        fmt=( '--to=iec' '--format=%7.1f' )
    fi

    find "${@:-.}" -xdev -type f -printf "%s %p\n" | numfmt "${fmt[@]}" | sort -h | tail -25
}

# list directories
alias lsd='ls -F | grep --color=never "/$" | column -xc$(tput cols)'
alias lld='ls -lAF | grep --color=never "/$"'
# list executables
alias lsx='ls -F | grep --color=never "\\*$" | column -xc$(tput cols)'
alias llx='ls -laF | grep --color=never "\\*"'


#---- Functions ----------------------------------------------------------------

if command -v vimpager >/dev/null 2>&1; then
    export PAGER=vimpager
else
    function man
    {
        vim -c "runtime! ftplugin/man.vim"  -c "Man $*" -c only
        #_MAN_TMP=/tmp/man.tmp.$$
        #/usr/bin/man $* | sed "s/.//g" > $_MAN_TMP
        #[ -s $_MAN_TMP ] && vim -v $_MAN_TMP
        #rm -f $_MAN_TMP

    }
fi


[ "$BASH_DEBUG" = "FULL" ] && set +x
[ -n "$BASH_DEBUG" ]       && echo End sourcing .aliases
true   # i want rc==0 even if BASH_DEBUG is not set!

# vim: ft=sh:
