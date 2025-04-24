#!/bin/bash

#----------------------Functions-------------------------#
print_help(){

    if [[ -n "$1" ]]; then 
        echo "DFuck is $1?"
    fi
    echo -e "Are you dumb? You created me, how can you forget the flags? Idiot.....\nUsage: $0 [options] \nOptions:
            -h/--help\t\t\t    : Help
            -s/--show -a/--apache -l/--logs : Show Apache logs
            \t\t\t     --stat : Show Apache status
        \t\t-p/--port  \t    : Listener (port 4445)
        \t\t-bL  \t\t    : List all the blocked users 
        \t\t-bS  \t\t    : List tail of al lblocked users
            --block\t\t\t    : Block the server entirly
            -u/--update \t\t    : Update && upgrade"
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
        -u|--update)
            sudo apt-get update && sudo apt-get upgrade;;
        -h|--help)
            print_help;;
        -s|--show)
            shift 
            case "$1" in
                -p|--port)
                #Print the port logs 
                    last_arg
                    /bin/tail -f $PORT_LOG_PATH;;
                -c|--connections)
                    echo "Printing active connections"
                    shift;;
                -a|--apache)
                    shift
                    apache "$@";;
                -bL)
                    last_arg
                    /bin/cat $BANNED_LOG_PATH;;
                -bS)
                    last_arg
                    /bin/tail -f $BANNED_LOG_PATH;;
                *)
                    print_help "$1";;
            esac;;
        *)
            print_help "$@";;
    esac
    shift
done
exit 0

        