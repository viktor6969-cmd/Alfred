#!/bin/bash

#----------------------Functions-------------------------#
print_help(){

    if [[ -n "$1" ]]; then 
        echo "DFuck is $1?"
    fi
    echo -e "Are you dumb? You created me, how can you forget the flags? Idiot.....\nUsage: $0 [options] \nOptions:
        -h/--help      : Help
        -al/--logs     : Show Apache logs
        -u/--update    : Update && upgrade
        -aS/--stat     : Show Apache status
        -p/--port      : Listener (port 4445)
        --BLOCK        : Block the server entirly
        -lA/--listALL  : List all the blocked users 
        -ll/--listLast : List tail of al blocked users
        --git --con    : Connect to git via new ssh agent
        --git --dis    : Kill all the ssh agents (exept the curent one)
        -c/--connect   : Shows the curent established connections (ESTAB)"
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

git(){
    case "$1" in
        --con)

            if [ -f ~/.ssh/agent.env ]; then
                source ~/.ssh/agent.env > /dev/null
            fi

            if ! ssh-add -l >/dev/null 2>&1; then
                eval "$(ssh-agent -s)" > ~/.ssh/agent.env
                echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" >> ~/.ssh/agent.env
                echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> ~/.ssh/agent.env
                ssh-add ~/.ssh/id_rsa
            else
                echo "[ ]Reusing existing ssh-agent."
            fi
            GIT_OUTPUT=$(ssh -T git@github.com 2>&1)
            USERNAME=$( echo "$GIT_OUTPUT" | grep -oP '(?<=Hi ).*?(?=!)')
            if [[ -n $USERNAME ]]; then
                echo -e "[+] Connected to git as: $USERNAME"
                exit 0
            fi
            echo -e "[-] Couldn't connect to git:\n$GIT_OUTPUT"

            exit 0;;
        --dis)
            pkill ssh-agent -q 
            echo -e "All the ssh connected has been kiled";;
        *)
        print_help $@;;
    esac

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
        --git)
            shift
            git $@;;
        -u|--update)
            sudo apt-get update && sudo apt-get upgrade;;
        -h|--help)
            print_help;;
        -p|--port)
            last_arg
            /bin/tail -f $PORT_LOG_PATH;;
        -c|--connect)
            sudo ss -tunap | grep ESTAB
            shift;;
        -a|--apache)
            shift
            apache "$@";;
        -as|--stat)
            sudo fail2ban-client status sshd;;
        -lA|--listALL)
            last_arg
            sudo /bin/cat $BANNED_LOG_PATH;;
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

        