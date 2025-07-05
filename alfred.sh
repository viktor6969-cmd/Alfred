#!/usr/bin/env bash

#============================  Functions  =================================#



#------------------- Security ----------------------#

# Sudo user verification
has_sudo() {
    sudo -n true 2>/dev/null
}

#------------------ File reading -------------------#

# Extracting variables from .env
env_extract(){

    SCRIPT_DIR="$(dirname "$(readlink -f "$0")")"
    ENV_FILE="$SCRIPT_DIR/.env"

    if [[ -f "$ENV_FILE" ]]; then
    set -a
    source "$ENV_FILE"
        set +a
    else
        print_error ".env file is missing at $ENV_FILE" >&2
        exit 1
    fi
}


#------------------- Installing --------------------#

# Service instalation (if needed)
install_service (){
    [[ command -v curl 
}

#---------------------- VPN ------------------------#








# Cheack for last argument
last_arg(){
    if [[ "$1" != "${!#}" ]]; then
        print_help "$1"
    fi
}

# Backup function
backup_function() {
    if [[ -z "$1" ]]; then 
        echo -e "$ERROR_MESSAGE Missing argument after --save !"
        print_help
    fi

    TIMESTAMP=$(date +%Y-%m-%d_%H-%M)

    if [[ "$1" == "-all" ]]; then 
        for SERVICE in "${SERVICES_INCLUDED[@]}"; do
            SRC_DIR="/etc/$SERVICE"
            DEST_FILE="$BACKUP_FILES_PATH/${SERVICE}_$TIMESTAMP.bkp"
            backup_save "$SRC_DIR" "$DEST_FILE" "$SERVICE"
        done
        exit 0
    else 
        while [[ "$#" -gt 0 ]]; do
            found=0
            for svc in "${SERVICES_INCLUDED[@]}"; do
                if [[ "$svc" == "$1" ]]; then
                    SRC_DIR="/etc/$svc"
                    DEST_FILE="$BACKUP_FILES_PATH/${svc}_$TIMESTAMP.bkp"
                    backup_save "$SRC_DIR" "$DEST_FILE" "$svc"
                    found=1
                    break
                fi
            done
            if [[ $found -eq 0 ]]; then
                echo -e "$ERROR_MESSAGE Unknown service: $1"
            fi
            shift
        done
    fi
}

backup_save() {
    SRC_DIR="$1"
    DEST_FILE="$2"
    SERVICE="$3"

    if [[ -d "$SRC_DIR" ]]; then
        sudo tar -czf "$DEST_FILE.tar.gz" -C /etc "$SERVICE"
        echo -e "$SUCSESS_MASSAGE Backed up $SERVICE to $DEST_FILE.tar.gz"
    else
        echo -e "$ERROR_MESSAGE: $SRC_DIR doesn't exist. Skipping."
    fi
}




# Find IP in fail2ban jail
find_ip_jail(){
    if [[ $# -eq 0 ]]; then
        echo -e "$ERROR_MESSAGE:You must enter the ip too, use the -h option idiot...."  
    fi 

    is_valid_ip "$1"
    FOUND=0
    for jail in $(sudo fail2ban-client status | grep "Jail list" | cut -d ":" -f2 | tr ',' ' '); do
        if sudo fail2ban-client status "$jail" | grep -q "Banned IP list:.*$1"; then
        echo -e "$SUCSESS_MASSAGE:The ip:$1 was banned by \"$jail\"";
        FOUND=1
        fi
    done

    if [ "$FOUND" -eq 0 ]; then
        echo "$SUCSESS_MASSAGE:IP $1 is not blocked in any jail."
    fi 
    exit 0
}

# Shows blocked ip logs
show_logs(){
    if [[ "$#" -eq 0 ]]; then
        sudo /bin/tail -f $REAL_TIME_LOGS_PATH
        exit 0
    fi

    case "$1" in
        -l|--list)
            sudo /bin/cat $BLOCKED_IP_LIST_PATH;;
        -i|--info)
            shift 
            is_valid_ip "$1"
            sudo /bin/cat $BLOCKED_IP_INFO_PATH | grep "$1" || echo "$SUCSESS_MASSAGE:$1 wasnn't found in the blocked ip logs";;
        *)
        print_help "$@";;
    esac
    exit 0
}

# Open port
open_port() {
    PORT=$1
    CLEANED_UP=0

    cleanup() {
        if [[ $CLEANED_UP -eq 0 ]]; then
            echo -e "\n$INFO_MASSAGE Closing port $PORT..."
            sudo ufw delete allow $PORT > /dev/null
            CLEANED_UP=1
            exit 0
        fi
    }

    trap cleanup SIGINT SIGTERM

    echo -e "$INFO_MASSAGE Temporarily opening port $PORT..."
    sudo ufw allow $PORT > /dev/null

    echo -e "$INFO_MASSAGE Starting listener on port $PORT. Press Ctrl+C to stop...\e[0m"
    nc -lvnp $PORT

    cleanup  # Will only run if not already cleaned
}



#--------------------Main code-------------------#

has_sudo || { print_error "This script requires sudo access."; exit 1; }

env_extract

if [[ $# -eq 0 ]]; then
    print_help 
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help) print_help;;
        -up|--update) sudo apt-get update && sudo apt-get upgrade;;
        -f|--find) find_ip_jail "{$@:2}";;
        -s|--show) show_logs "{$@:2}";;

        -b|--ban)
            shift
            if [[ $# -eq 2 ]]; then
                sudo fail2ban-client set $1 ban $2 
            fi;;

        -aS|--apacheStat)
            
            sudo systemctl status  apache2;;

        -jS|--jailStat)
            shift 
            if [[ $# -eq 0 ]]; then
                print_info " If you want to see the status of a specific jail, add the jail name at the end [!]" 
            fi
            sudo fail2ban-client status $1;;

        -l|--listen)
            shift
            if [[ $# -eq 0 ]]; then
                print_error " You must enter the port number!\nUse -h! for fuck say...." 
                exit 1
            fi
            last_arg "$@"
            open_port "$1";;

        -c|--connect)
            shift
            last_arg "$@"
            sudo ss -tunap | grep ESTAB;;

        
    ##------not working-------#
        --git)
            shift
            git $@;;
        
        --BLOCK)
            last_arg
            echo "Server is DOWN";;
        *)
            print_help "$@";;
    esac
    shift
done
exit 0




# Git updates via ssh key
# git(){
#     case "$1" in
#     --con)
#         if [ -f ~/.ssh/agent.env ]; then
#             source ~/.ssh/agent.env > /dev/null 
#         fi

#         if ! ssh-add -l >/dev/null 2>&1; then
#             echo "[ ] No valid ssh-agent found, starting a new one..."
#             eval "$(ssh-agent -s)" > /dev/null
#             echo "export SSH_AUTH_SOCK=$SSH_AUTH_SOCK" > ~/.ssh/agent.env
#             echo "export SSH_AGENT_PID=$SSH_AGENT_PID" >> ~/.ssh/agent.env
#             ssh-add ~/.ssh/ssh_key_private > /dev/null 2>&1
#         else
#             echo "[ ] Reusing existing ssh-agent."
#         fi

#         GIT_OUTPUT=$(ssh -T git@github.com 2>&1)
#         USERNAME=$(echo "$GIT_OUTPUT" | grep -oP '(?<=Hi ).*?(?=!)')

#         if [[ -n $USERNAME ]]; then
#             echo -e "[+] Connected to GitHub as: $USERNAME"
#         else
#             echo -e "[-] Couldn't connect to GitHub:\n$GIT_OUTPUT"
#         fi
#         exit 0;;

#     --dis)
#         pkill ssh-agent > /dev/null 2>&1
#         echo "[+] All ssh-agent processes have been killed."
#         exit 0;;

#     *)
#         print_help "$@";;
#     esac


# }