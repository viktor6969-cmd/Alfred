#!/bin/bash

print_help(){

    if [[ -n "$1" ]]; then 
        echo "DFuck is $1?"
    fi
    echo -e "Are you dumb? You created me, how can you forget the flags? Idiot.....\nUsage: $0 [options] \nOptions:
            -h/--help\t\t\t    : Help
            -s/--show -a/--apache -l/--logs : Show Apache logs
            \t\t\t     --stat : Show Apache status
            -s/--show -p/--port  \t    : Listener (port 4445)
            -b/--block \t\t\t    : Block the server entirly
            -u/--update \t\t    : Update && upgrade"
    exit 1
}

apache(){
    case "$1" in
        -l|--logs)
            echo "Apache logs";;

        --status)
            echo "Apache status";;
        *) 

            print_help "$1";;
    esac
    exit 0
}

if [[ $# -eq 0 ]]; then
    echo "Defoult mode" 
fi



while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -u|--update)
            echo "sudo apt-get update && sudo apt-get upgrade";;
        -h|--help)
            print_help;;
        -s|--show)
            shift 
            case "$1" in
                -p|--port)
                    echo "Printing  logs for port 4445"
                    shift;;
                -c|--connections)
                    echo "Printing active connections"
                    shift;;
                -a|--apache)
                    shift
                    apache "$@";;
                *)
                    print_help "$1";;
            esac;;
        *)
            print_help "$@";;
    esac
    shift
done

        