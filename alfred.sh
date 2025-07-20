#!/usr/bin/env bash

# TO DO:
# Fix pipefail on missing arguments with empty call


set -euo pipefail

SCRIPT_PATH="$(readlink "$0")"
SCRIPT_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"

source "$SCRIPT_DIR/utils.sh"

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

    # Export every variable from the .env file 
    [[ -f "$ENV_FILE" ]] && { set -a; source "$ENV_FILE"; set + a;} || return 1
}

# Extract the dependancyes list, into a hash map name:DEP_MAP
dep_extract(){

    # Make a global hash map of the supported services 
    declare -Ag DEP_MAP

    # Make sure that .dep.list exist in the folder 
    [[ ! -f "$DEPS_FILE" ]] &&  { print_error "The .dep.list file is missing"; return 1;} 

    # Avoid double .dep.list file read 
    [[ ${DEP_MAP["__loaded"]+x} ]] && return 0

    while IFS=':' read -r prog binary path; do
        [[ -z "$prog" || "$prog" =~ ^# ]] && continue
        [[ -z "$binary" ]] && binary="$prog"

        # fallback if path is empty
        [[ -z "$path" ]] && path="/etc/$prog"

        DEP_MAP["$prog"]="$path"
    done < "$DEPS_FILE"

}
#------------------- Installing --------------------#

# Service instalation (if needed)


#---------------Backup functions--------------------#
backup_function() {

    dep_extract

    if (( $# == 0 )); then
        print_error "Missing argument after --save!"
        print_info "Try alfred --help"
        exit 1
    fi

    local TIMESTAMP
    TIMESTAMP="$(date +%Y-%m-%d_%H-%M)"

    if [[ "$1" == "-all" ]]; then 
        [[ ! -f "$DEPS_FILE" ]] && { print_error "$DEPS_FILE not found."; return 1; }
        [[ -d "$BACKUP_FILES" ]] || sudo mkdir -p "$BACKUP_FILES"

        BACKUP_DIR="$BACKUP_FILES/bkp_$TIMESTAMP"
        sudo mkdir -p "$BACKUP_DIR"

        for prog in "${!DEP_MAP[@]}"; do
            [[ "$prog" =~ _ ]] && continue
            local path="${DEP_MAP["${prog}_path"]}"
            local dest_file="$BACKUP_DIR/${prog}.bkp"
            backup_save "$path" "$dest_file" "$prog"
        done

        print_success "All services backed up."
        return 0
    fi

     # Selective backup
    while [[ "$#" -gt 0 ]]; do
        local prog="$1"
        local path="${DEP_MAP["${prog}_path"]}"

        if [[ -n "$path" ]]; then
            local dest_file="$BACKUP_FILES/${prog}_$TIMESTAMP.bkp"
            backup_save "$path" "$dest_file" "$prog"
        else
            print_error "Unknown service: $prog, was skipped"
        fi

        shift
    done

    print_success "Done saving backup files."
    exit 0
}

backup_save() {

    local src_dir="$1"
    local dest_file="$2"
    local service="$3"

    if [[ -d "$src_dir" ]]; then
        sudo tar -czf "${dest_file}.tar.gz" -C /etc "$service"
        print_success "Backed up $service to ${dest_file}.tar.gz"
    else
        print_error "$src_dir doesn't exist. Skipping."
    fi

    return 0
}

list_services(){

    dep_extract

    echo -e "\nSupported programs:"
    for prog in "${!DEP_MAP[@]}"; do
        [[ "$prog" == "__loaded" ]] && continue
        printf "  - %s => %s\n" "$prog" "${DEP_MAP[$prog]}"
    done

    return 0
}


#---------------------- VPN ------------------------#


#-------------------Functionality-------------------#

# Cheack for last argument
last_arg(){
    if [[ -z "${2:-}" ]]; then
        print_error "Missing arguments after $1"
        print_info "Try alfred --help"
        exit 1
    fi
    return 0
}



#-----------------Not working yet------------------#
# Find IP in fail2ban jail
find_ip_jail(){
    if [[ $# -eq 0 ]]; then
        print_error "You must enter the ip too, use the -h option idiot...."  
    fi 

    is_valid_ip "$1"
    FOUND=0
    for jail in $(sudo fail2ban-client status | grep "Jail list" | cut -d ":" -f2 | tr ',' ' '); do
        if sudo fail2ban-client status "$jail" | grep -q "Banned IP list:.*$1"; then
        print_success "Ip:$1 was banned by \"$jail\"";
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

has_sudo || { print_error "You must be root to run this script"; exit 1;}

env_extract

if [[ $# -eq 0 ]]; then
    print_error "No arguments were found, try alfred -h"
fi

while [[ "$#" -gt 0 ]]; do
    case "$1" in
        -h|--help) 
            print_help;;

        -up|--update) 
            sudo apt-get update && sudo apt-get upgrade;;

        --save)
            backup_function "${@:2}";;

        --list)
            list_services;;


#---------------------Working----------------------------#
        -f|--find) find_ip_jail "${@:2}";;
        -s|--show) show_logs "${@:2}";;

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