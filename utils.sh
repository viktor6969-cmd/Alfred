#!/usr/bin/env bash

#=============== Global Vars ======================#

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

APP_NAME="alfred"
SCRIPT_NAME="$SCRIPT_DIR/alfred.sh"
INSTALL_PATH="/usr/local/bin/$APP_NAME"


ENV_FILE="$SCRIPT_DIR/.env"
ENV_TEMPLATE="$SCRIPT_DIR/.env.example"

DEPS_FILE="$SCRIPT_DIR/.dep.list"
DEPS_TEMPLATE="$SCRIPT_DIR/.dep.list.example"

INFO="\e[33m[!]\e[0m "
ERROR="\e[31m[-]\e[0m "
SUCSESS="\e[32m[+]\e[0m "
YES_REGEX="^([yY]|yes|YES|Yes|yep)$"


#--------------------- Printing --------------------#

# Utility function to print info messages
print_info() {
    echo -e "$INFO$1 "
}

# Utility function to print error messages
print_error() {
    echo -e "$ERROR$1 "
}

# Utility function to print error messages
print_success() {
    echo -e "$SUCSESS$1 "
}

# Print help
print_help(){

    if [[ -n "$1" ]]; then 
        print_error "DAFuck is $1?"
    fi
    echo -e "\e[33m[!] Are you dumb? You created me, how can you forget the flags? Idiot.....\n\e[0mUsage: $0 [options] \nOptions:
        -h/--help                   : Help
        -s/--show                   : Show real time ufw logs
             -l/--List              : Show blocked ips
             -i/--Info <ip>         : Show info about blocked ip (request log)
        -f/--find <ip>              : Find the Jail that blocked the ip
        -b/--ban <jail name> <ip>   : Block ip
        -u/--unban <ip>             : Unblock ip
        -c/--connect                : Shows the curent established connections (ESTAB)
        -up/--update                : Update && upgrade
        -aS/--apacheStat            : Show Apache status
        -jS/--jailStat              : Fail2ban jails status
        -pl/--portListen <port>     : Open a Netcat listener on specefied port


        */ Still not working /*
        --BLOCK        : Block the server entirly
        --git --con    : Connect to git via new ssh agent
        --git --dis    : Kill all the ssh agents (exept the curent one)"
        
    exit 1
}

#------------------ Security ----------------------#

# Veryfy sudo user 
has_sudo() {
    sudo -n true 2>/dev/null || { print_error "This script requires sudo access."; exit 1; }
}

#----------------- Input validation ----------------#

# IP validation
is_valid_ip() {
    if [[ -n $1 ]]; then
        print_error "You must enter the ip, use the -h option"
    fi

    local ip="$1"
    if [[ ! "$ip" =~ ^([0-9]{1,3}\.){3}[0-9]{1,3}$ ]]; then
        print_error "$ip is not a valid IP address (invalid format)"
        exit 1
    fi

    # Check each octet is 0–255
    IFS='.' read -r -a octets <<< "$ip"
    for octet in "${octets[@]}"; do
        if ((octet < 0 || octet > 255)); then
            print_error "$ip is not a valid IP address (octet out of range)"
            exit 1
        fi
    done
}