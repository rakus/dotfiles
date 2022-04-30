# shellcheck shell=bash

_keytool_complete() {

    COMPREPLY=()
    cur="${COMP_WORDS[COMP_CWORD]}"
    prev="${COMP_WORDS[COMP_CWORD-1]}"

    if [ "$COMP_CWORD" = 1 ]; then
        cmd="-help -certreq -changealias -delete -exportcert -genkeypair -genseckey -gencert -importcert -importpass -importkeystore -keypasswd -list -printcert -printcertreq -printcrl -storepasswd"

        COMPREPLY=( $(compgen -W "${cmd}" -- "${cur}") )
        return
    fi

    cmd="${COMP_WORDS[1]}"

    case "$prev" in
        -deststoretype|-srcstoretype|-storetype)
            # typically used store types .. there are others too
            COMPREPLY=( $(compgen -W "JKS JCEKS PKCS12 PKCS11 DKS" -- "${cur}") )
            return
            ;;


        -destkeypass|-deststorepass|-keypass|-new|-providerarg|-srckeypass|-srcstorepass|-storepass)
            return
            ;;
        -alias|-destalias|-destprovidername|-dname|-keyalg|-keysize|-providerpath)
            return
            ;;
        -providerclass|-providername|-sslserver|-sigalg|-srcalias|-srcprovidername|-startdate|-validity|-ext)
            return
            ;;

        -destkeystore|-file|-infile|-jarfile|-outfile|-keystore|-srckeystore)
            COMPREPLY=( $(compgen -f "${cur}") )
            return 0
            ;;

        -noprompt|-protected|-rfc|-srcprotected|-systemlineendings|-trustcacerts|-v)
            :
            ;;
    esac

    case "$cmd" in

        -certreq)
            compl="-alias -sigalg -file -keypass -keystore -dname -storepass -storetype -providername -providerclass -providerarg -providerpath -systemlineendings -protected"
            ;;
        -changealias)
            compl="-alias -destalias -keypass -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -delete)
            compl="-alias -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -exportcert)
            compl="-rfc -alias -file -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -genkeypair)
            compl="-alias -keyalg -keysize -sigalg -destalias -dname -startdate -ext -validity -keypass -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -genseckey)
            compl="-alias -keypass -keyalg -keysize -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -gencert)
            compl="-rfc -infile -outfile -alias -sigalg -dname -startdate -ext -validity -keypass -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -importcert)
            compl="-noprompt -trustcacerts -protected -alias -file -keypass -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath"
            ;;
        -importpass)
            compl="-alias -keypass -keyalg -keysize -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -importkeystore)
            compl="-srckeystore -destkeystore -srcstoretype -deststoretype -srcstorepass -deststorepass -srcprotected -srcprovidername -destprovidername -srcalias -destalias -srckeypass -destkeypass -noprompt -providerclass -providerarg -providerpath"
            ;;
        -keypasswd)
            compl="-alias -keypass -new -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath"
            ;;
        -list)
            compl="-rfc -alias -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath -protected"
            ;;
        -printcert)
            compl="rfc -file -sslserver -jarfile"
            ;;
        -printcertreq|-printcrl)
            compl="-file"
            ;;
        -storepasswd)
            compl="-new -keystore -storepass -storetype -providername -providerclass -providerarg -providerpath"
            ;;

        *)
            return
        esac

        COMPREPLY=($(compgen -W "${compl} -v -help" -- "${cur}") )
}

complete -F _keytool_complete -o filenames keytool

case "$OSTYPE" in
    win*|msys*|cygwin*)
        complete -F _keytool_complete -o filenames keytool.exe
        ;;
esac

# vim:ft=sh
