#
# FILE: .was-completion.bash
#
# ABSTRACT: command line completion for WebSphere AppServer scripts
#
# This file contains command line completion functions for some
# scripts delivered with the WebSphere Application Server (and its
# layered products).
#
# Currently supported are:
#    startServer.sh
#    stopServer.sh
#    serverStatus.sh
#    manageprofiles.sh
#    wsadmin.sh
#
# Notes:
# * Completion for manageprofiles.sh is limited. Depending on used
#   templates new options might be possible. Can't handle them all.
# * Tested with BASH version 4.3.11(1)-release
#
#
# AUTHOR: Ralf Schandl
#

if [ -z "$BASH_VERSION" ]; then
    # Not bash -> nothing to do
    return 0
fi

#
# Comment the following line to enable logging to $HOME/was-completion.log
#
alias _WAS_debug="#"

shopt -s extglob

# Older bash completion doesn't define _get_cword. Add a simplified form.
if ! type _get_cword &> /dev/null ; then
    function _get_cword()
    {
      printf "%s" "${COMP_WORDS[$COMP_CWORD]}"
    }
fi

# if _filedir is not defined, add a simplified form.
if ! type _filedir &> /dev/null ; then
    function _filedir()
    {
        local IFS=$'\t\n' xspec #glob

        #glob=$(set +o|grep noglob) # save glob setting.
        #set -f          # disable pathname expansion (globbing)

        xspec=${1:+"!*.$1"}     # set only if glob passed in as $1
        COMPREPLY=( ${COMPREPLY[@]:-} $( compgen -f -X "$xspec" -- "$cur" ) \
            $( compgen -d -- "$cur" ) )
        #eval "$glob"    # restore glob setting.
    }
fi



# If no completion for java classpath is defined yet, add a own one. If java
# completion is loaded later, this will be overwritten.
if ! type _java_path &> /dev/null ; then
    _java_path()
    {
        cur=${cur##*:}
        _filedir '@(jar|zip)'
    }
fi

if ! alias _WAS_debug >/dev/null 2>/dev/null; then
function _WAS_debug()
{
    echo "$@" >> $HOME/was-completion.log
}
fi

#
# Parameter: the called command
#
# Initialises the following variables:
# WAS_CMD:      basename of the called command
# WAS_CMD_DIR:  absolute directiory name of called command
# WAS_HOME:     Installdir of WAS
# WAS_CELL:     cell name
# WAS_NODE:     node name
# WAS_PROFILE_DIR: Directory of the current profile
#
# If the called command is not from a profile directory, the
# variables WAS_CELL, WAS_NODE and WAS_PROFILE_DIR stay unset.
#
function _WAS_initWasVariables()
{
    local fq
    fq="$1"
    fq=$(which "$fq")
    fq=$(readlink -f "$fq")
    WAS_CMD=$(basename "$fq")
    _WAS_debug "WAS_CMD=$WAS_CMD"
    WAS_CMD_DIR=$(dirname "$fq")
    _WAS_debug "WAS_CMD_DIR=$WAS_CMD_DIR"
    if [ "$WAS_CMD_DIR" = "$HOME/bin" ]; then
        # special handling for my wsadmin.sh in $HOME/bin
        WAS_CMD_DIR=$(grep "^DMGR_DIR=" "$fq" | cut -d= -f2)
    fi
    [[ ! -e "$WAS_CMD_DIR/setupCmdLine.sh" ]] && return 1
    eval "$(grep -E "^(WAS_HOME|WAS_CELL|WAS_NODE)" "$WAS_CMD_DIR"/setupCmdLine.sh)"
    if [[ -z "$WAS_HOME" ]]; then
        WAS_HOME=$(dirname "$WAS_CMD_DIR")
    else
        WAS_PROFILE_DIR=$(dirname "$WAS_CMD_DIR")
    fi
    _WAS_debug "WAS_HOME=$WAS_HOME"
    _WAS_debug "WAS_CELL=$WAS_CELL"
    _WAS_debug "WAS_NODE=$WAS_NODE"
    _WAS_debug "WAS_PROFILE_DIR=$WAS_PROFILE_DIR"
    return 0
}

#
# List the names of all profiles.
#
function _WAS_listProfileNames()
{
    # xpath -q -e "/profiles/profile/@name" "$WAS_HOME"/profileRegistry.xml | sed 's/^.*name="//;s/".*$//'
    grep "<profile " "$WAS_HOME"/properties/profileRegistry.xml | sed 's/^.* name="//;s/".*$//'
}

#
# Get the name of the default profile
#
function _WAS_getDefaultProfile()
{
    # xpath -q -e "//profile[@isDefault='true']/@name" "$WAS_HOME"/profileRegistry.xml | sed 's/^.*name="//;s/".*$//'
    grep '<profile .*isDefault="true"' "$WAS_HOME"/properties/profileRegistry.xml | sed 's/^.* name="//;s/".*$//'
}

#
# Parameter: profile name
# Returns the path of the given profile.
#
function _WAS_getProfileDir()
{
    #xpath -q -e "//profile[@name='Dmgr01']/@path" "$WAS_HOME"/profileRegistry.xml | sed 's/^.*path="//;s/".*$//'
    grep "<profile .*name=\"$1\"" "$WAS_HOME"/properties/profileRegistry.xml | sed 's/^.*path="//;s/".*$//'
}

#
# Parameter: profile name
# Initializes profile-specific vars:
# WAS_HOME:     Installdir of WAS
# WAS_CELL:     cell name
# WAS_NODE:     node name
# WAS_PROFILE_DIR: Directory of the current profile
function _WAS_initProfileVars()
{
    WAS_PROFILE_DIR=$(_WAS_getProfileDir "$1")
    eval "$(grep -E "^(WAS_HOME|WAS_CELL|WAS_NODE)" "$WAS_PROFILE_DIR"/bin/setupCmdLine.sh)"
    #echo >&2 ""
    #echo >&2 "WAS_HOME: $WAS_HOME"
    #echo >&2 "WAS_CELL: $WAS_CELL"
    #echo >&2 "WAS_NODE: $WAS_NODE"
    #echo >&2 "WAS_PROFILE_DIR: $WAS_PROFILE_DIR"
}

#
# Completes "cur" to profile name
#
function _WAS_completeProfileNames()
{
    COMPREPLY=($(compgen -W "$(_WAS_listProfileNames)" -- "$cur" ))
}

#
# Completes "cur" to server name.
#
# If a profile name was given with -profileName, initialize from that profile.
# If no WAS_PROFILE_DIR is set, initialize from the default profile.
#
function _WAS_completeServer()
{
    for (( i=1; i < COMP_CWORD; i++ )); do
        if [[ "${COMP_WORDS[i]}" == "-profileName" ]]; then
            _WAS_initProfileVars "${COMP_WORDS[i+1]}"
            break
        fi
    done
    if [[ -z "$WAS_PROFILE_DIR" ]]; then
        _WAS_initProfileVars "$(_WAS_getDefaultProfile)"
    fi

    COMPREPLY=($(compgen -W "$(ls "$WAS_PROFILE_DIR/config/cells/$WAS_CELL/nodes/$WAS_NODE/servers" | grep -v /)" -- "$cur" ))
}

#
# Complete values for an option.
# Option and values are given in the array VAL_COMPL.
#
# Example:
#     VAL_COMPL=( "-type:HTML XML" "-lang:jython jacl" )
# The option -type needs a additional argument with a value of either
# "HTML" or "XML"
# The option -lang needs a additional argument with a value of either
# "jython" or "jacl"
function _WAS_valueComplete()
{
    local values= i=
    for (( i=0; i < ${#VAL_COMPL[@]}; i++ )); do
        if [[ ${VAL_COMPL[$i]} =~ ^${prev}:.* ]]; then
            values=${VAL_COMPL[$i]}
            values=${values/${prev}:/}
            COMPREPLY=($(compgen -W "$values" -- "$cur" ))
            return
        fi
    done
}

function _WAS_buildValComplPattern()
{
    local values= i= opt=
    for (( i=0; i < ${#VAL_COMPL[@]}; i++ )); do
        if [[ ${VAL_COMPL[$i]} =~ ^${prev}:.* ]]; then
            opt=${VAL_COMPL[$i]}
            opt=${opt/:*/}
            echo ${opt}
        fi
    done
}


#
# Generic completion function
# This function works with the following variables:
# OPTS_COMPL:
#    Options that can only be used once on the command line. (separator ' ')
# OPTS_COMPL_MULT:
#    Options that can be used multiple times (separator ' ')
# PROFILE_COMPL:
#    Options that needs profile name as argument (separator '|')
# FILE_COMPL:
#    Options that needs a file as argument (separator '|')
# DIR_COMPL:
#    Options that needs a directory as argument (separator '|')
# CP_COMPL:
#    Options that needs a java classpath as argument (separator '|')
# NO_COMPL:
#    Options that needs an argument, but we can't help completing
#    (separator '|')
# VAL_COMPL:
#    Array of strings. This is for options that support a limited set of
#    argument values (like -debug <true|false>). see _WAS_valueComplete for
#    details.
# F_COMPL:
#    Final completion What to complete if no option or option argument.
#    Suported modes: "file", "dir", "server"
#
function _WAS_genericComplete()
{
    local myopt= cur= prev= i=

    COMPREPLY=()
    cur=$(_get_cword)
    prev=${COMP_WORDS[COMP_CWORD-1]}
    myopt=" $OPTS_COMPL "

    if [[ -n "$VAL_COMPL" ]]; then
        val_compl_options=$(_WAS_buildValComplPattern)
    fi
    if [[ "$cur" == -* ]]; then
        # remove already used options
        for (( i=1; i < COMP_CWORD; i++ )); do
            if [[ ${COMP_WORDS[i]} =~ -.* ]]; then
                myopt=${myopt/ ${COMP_WORDS[i]} / /}
            fi
        done
        COMPREPLY=( $( compgen -W "$myopt $OPTS_COMPL_MULT" -- "$cur" ) )
    elif [[ "$prev" == @($PROFILE_COMPL) ]]; then
        _WAS_completeProfileNames "$cur"
    elif [[ "$prev" == @($FILE_COMPL) ]]; then
        # hack to make _filedir work correct
        compgen -f /non-existing-dir/ >/dev/null
        _filedir
        #COMPREPLY=($(compgen -o filenames -- "$cur" ))
    elif [[ "$prev" == @($DIR_COMPL) ]]; then
        # hack to make _filedir work correct
        compgen -f /non-existing-dir/ >/dev/null
        _filedir -d
        #COMPREPLY=($(compgen -d -- "$cur" ))
    elif [[ "$prev" == @($CP_COMPL) ]]; then
        # hack to make _javapath work correct
        compgen -f /non-existing-dir/ >/dev/null
        _java_path
    elif [[ "$prev" == @($NO_COMPL) ]]; then
        COMPREPLY=()
    elif [[ "$prev" == @($val_compl_options) ]]; then
        _WAS_valueComplete "$cur"
    else
        if [[ "$F_COMPL" == "server" ]]; then
            _WAS_completeServer "$cur"
        elif [[ "$F_COMPL" == "file" ]]; then
            compgen -f /non-existing-dir/ >/dev/null
            _filedir
        elif [[ "$F_COMPL" == "dir" ]]; then
            compgen -f /non-existing-dir/ >/dev/null
            _filedir -d
        else
            return 1
        fi
    fi

}

function _WAS_Complete()
{
    local WAS_CMD= WAS_CMD_DIR= WAS_HOME= WAS_CELL= WAS_NODE= WAS_PROFILE_DIR=
    local OPTS_COMPL= OPTS_COMPL_MULT= PROFILE_COMPL= FILE_COMPL= DIR_COMPL= NO_COMPL= VAL_COMPL= F_COMPL=
    _WAS_debug "--------------------------------------------------"
    _WAS_initWasVariables "$1"
    [[ $? != 0 ]] && return 0

    if [[ "$WAS_CMD" == "startServer.sh" ]]; then
        OPTS_COMPL='-nowait -quiet -logfile -replacelog -trace -script -background -timeout -statusport -profileName -recovery -help'
        OPTS_COMPL_MULT=''
        PROFILE_COMPL='-profileName'
        FILE_COMPL='-script|-logfile'
        NO_COMPL='-statusport|-timeout'
        VAL_COMPL=()
        F_COMPL='server'
    elif [[ "$WAS_CMD" == "stopServer.sh" ]]; then
        OPTS_COMPL='-nowait -quiet -logfile -replacelog -trace -timeout -statusport -profileName -username -password -port -conntype -help '
        OPTS_COMPL_MULT=''
        PROFILE_COMPL='-profileName'
        FILE_COMPL='-script|-logfile'
        NO_COMPL='-password|-port|-statusport|-timeout|-username'
        VAL_COMPL=( "-conntype:SOAP RMI" )
        F_COMPL='server'
    elif [[ "$WAS_CMD" == "serverStatus.sh" ]]; then
        OPTS_COMPL='-nowait -quiet -logfile -replacelog -trace -timeout -statusport -profileName -username -password -port -conntype -help '
        OPTS_COMPL_MULT=''
        PROFILE_COMPL='-profileName'
        FILE_COMPL='-script|-logfile'
        NO_COMPL='-password|-port|-statusport|-timeout|-username'
        VAL_COMPL=( "-conntype:SOAP RMI" )
        F_COMPL='server'
    elif [[ "$WAS_CMD" == "restartServer.sh" ]]; then
        OPTS_COMPL='-nowait -quiet -logfile -replacelog -trace -script -background -timeout -statusport -profileName -username -password -port -conntype -recovery -help '
        OPTS_COMPL_MULT=''
        PROFILE_COMPL='-profileName'
        FILE_COMPL='-script|-logfile'
        NO_COMPL='-statusport|-timeout|-password|-port|-username'
        VAL_COMPL=( "-conntype:SOAP RMI" )
        F_COMPL='server'
    else
        COMPREPLY=()
        return
    fi

    _WAS_genericComplete
}

function _WAS_manageprofilesComplete()
{
    local WAS_CMD= WAS_CMD_DIR= WAS_HOME= WAS_CELL= WAS_NODE= WAS_PROFILE_DIR=
    local OPTS_COMPL= OPTS_COMPL_MULT= PROFILE_COMPL= FILE_COMPL= DIR_COMPL= NO_COMPL= VAL_COMPL= F_COMPL=
    local MODE_LIST= mode=
    _WAS_initWasVariables "$1"
    [[ $? != 0 ]] && return 0
    MODE_LIST='-create -augment -delete -unaugment -unaugmentAll -deleteAll -listProfiles -listAugments -backupProfile -restoreProfile -getName -getPath -validateRegistry -validateAndUpdateRegistry -getDefaultName -setDefaultName -response'

    if [[ $COMP_CWORD -eq 1 ]]; then
        OPTS_COMPL='$MODE_LIST -help'
        _WAS_genericComplete
    else
        mode=${COMP_WORDS[1]}
        case "$mode" in
            -create)
                OPTS_COMPL='-templatePath -profileName -profilePath -isDefault -omitAction'
                DIR_COMPL='-templatePath|-profilePath'
                NO_COMPL='-profileName|-isDefault-omitAction'
                ;;
            -augment)
                OPTS_COMPL='-templatePath -profileName'
                DIR_COMPL='-templatePath'
                PROFILE_COMPL='-profileName'
                ;;
            -delete)
                OPTS_COMPL='-profileName'
                PROFILE_COMPL='-profileName'
                ;;
            -unaugment)
                OPTS_COMPL='-templatePath -profileName -ignoreStack'
                DIR_COMPL='-templatePath'
                PROFILE_COMPL='-profileName'
                NO_COMPL='-ignoreStack'
                ;;
            -unaugmentAll)
                OPTS_COMPL='-templatePath -unaugmentDependents'
                DIR_COMPL='-templatePath'
                NO_COMPL='-unaugmentDependents'
                ;;
            -deleteAll)
                # no opts
                ;;
            -listProfiles)
                # no opts
                ;;
            -listAugments)
                OPTS_COMPL='-profileName'
                PROFILE_COMPL='-profileName'
                ;;
            -backupProfile)
                OPTS_COMPL='-profileName -backupFile'
                PROFILE_COMPL='-profileName'
                FILE_COMPL='-backupFile'
                ;;
            -restoreProfile)
                OPTS_COMPL='-backupFile'
                FILE_COMPL='-backupFile'
                ;;
            -getName)
                OPTS_COMPL='-profilePath'
                DIR_COMPL='-profilePath'
                ;;
            -getPath)
                OPTS_COMPL='-profileName'
                PROFILE_COMPL='-profileName'
                ;;
            -validateRegistry)
                # no opts
                ;;
            -validateAndUpdateRegistry)
                # no opts
                ;;
            -getDefaultName)
                # no opts
                ;;
            -setDefaultName)
                OPTS_COMPL='-profileName'
                PROFILE_COMPL='-profileName'
                ;;
            -response)
                F_COMPL="file"
                ;;
            -help)
                OPTS_COMPL="$MODE_LIST -templatePath"
                DIR_COMPL='-templatePath'
                ;;
            *)
                return 1
                ;;
        esac
        _WAS_genericComplete
    fi
}


function _WAS_wsadminComplete()
{
    local WAS_CMD= WAS_CMD_DIR= WAS_HOME= WAS_CELL= WAS_NODE= WAS_PROFILE_DIR=
    local OPTS_COMPL= OPTS_COMPL_MULT= PROFILE_COMPL= FILE_COMPL= DIR_COMPL= NO_COMPL= VAL_COMPL= F_COMPL=
    local connTypeAddOn= i=
    _WAS_initWasVariables "$1"
    [[ $? != 0 ]] && return 0

    OPTS_COMPL='-h -help -p -profile -f -javaoption -lang -wsadmin_classpath -profileName -conntype -jobid -tracefile -appendtrace'
    connTypeAddOn='-host -port -user -password'
    FILE_COMPL='-p|-profile|-f|-tracefile'
    PROFILE_COMPL='-profileName'
    CP_COMPL='-wsadmin_classpath'
    NO_COMPL='-c|-javaoption|-jobid|-host|-port|-user|-password'
    VAL_COMPL=( '-conntype:SOAP RMI NONE' '-lang:jacl jython' '-appendtrace:true false' )

    # if conntype RMI or SOAP is set allow additional parameter
    for (( i=1; i < COMP_CWORD; i++ )); do
        if [[ "${COMP_WORDS[i]}" == "-conntype" ]]; then
            case "${COMP_WORDS[i+1]}" in
                RMI|SOAP)
                    OPTS_COMPL="$OPTS_COMPL $connTypeAddOn"
                    break
                    ;;
            esac
        fi
    done

    _WAS_genericComplete

}



# restartServer.sh is a simple script to stop and start the server
complete -F _WAS_Complete  restartServer.sh

complete -F _WAS_Complete  startServer.sh
complete -F _WAS_Complete  stopServer.sh
complete -F _WAS_Complete  serverStatus.sh
complete -F _WAS_manageprofilesComplete  manageprofiles.sh
complete -F _WAS_wsadminComplete wsadmin.sh

if alias _WAS_debug >/dev/null 2>/dev/null; then
    unalias _WAS_debug
fi

# vim:ft=sh
