#!/bin/bash

#----------------------Functions-------------------------#
print_help(){

    if [[ -n "$1" ]]; then 
        echo "DFuck is $1?"
    fi
    echo -e "Are you dumb? You created me, how can you forget the flags? Idiot.....\nUsage: $0 [options] \nOptions:
        -h/--help      : Help
        -al/--logs     : Show Apache logs
        -aS/--stat     : Show Apache status
        -p/--port      : Listener (port 4445)
        -lA/--listALL  : List all the blocked users 
        -ll/--listLast : List tail of al blocked users
        --BLOCK        : Block the server entirly
        -u/--update    : Update && upgrade"
    exit 1
}

last_arg(){

    if [[ -n $1 ]]; then
        print_help "$1"
    fi

}

apache(){
    case "$1" in
        -l|--logs)
            echo "Apache logs";;

        --status)
            sudo fail2ban-client status sshd;;
        *) 
            print_help "$1";;
    esac
    exit 0
}

#Extracting variables from .env
env_extract(){
    if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
    else
        echo ".env file not found!"
        exit 1
    fi
}

#--------------------Main code-------------------#

env_extract

if [[ $# -eq 0 ]]; then
    echo "Defoult mode" 
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -git)
            shift
            if [[ "$1" = "conn" ]]; then
                eval "$(ssh-agent -s)"
                ssh-add ~/.ssh/ssh_key_private
                exit 0
            fi
            if [[ "$1" = "dis" ]]; then 
                ssh-agent -k
                exit 0
            fi
            print_help "$@";;
        -u|--update)
            sudo apt-get update && sudo apt-get upgrade;;
        -h|--help)
            print_help;;
        -p|--port)
            last_arg
            /bin/tail -f $PORT_LOG_PATH;;
        -c|--connections)
            sudo ss -tunap | grep ESTAB
            shift;;
        -a|--apache)
            shift
            apache "$@";;
        -as|--stat)
            sudo fail2ban-client status sshd;;
        -lA|--listALL)
            last_arg
            /bin/cat $BANNED_LOG_PATH;;
        -ll|--listLst)
            last_arg
            sudo /bin/tail -f $BANNED_LOG_PATH;;
        --BLOCK)
            last_arg
            echo "Server is DOWN";;
        *)
            print_help "$@";;
    esac
    shift
done
exit 0

        