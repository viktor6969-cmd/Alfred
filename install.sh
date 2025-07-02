#!/bin/bash

APP_NAME="alfred"
SCRIPT_NAME="alfred.sh"
INSTALL_PATH="/usr/local/bin/$APP_NAME"

ENV_FILE=".env"
ENV_TEMPLATE=".env.example"

CMDS_LIST=".dep.list"
CMDS_LIST_TAMPLATE=".dep.list.example"

INFO="\e[33m[!]\e[0m"
ERROR="\e[31m[-]\e[0m"

# Remove the soft link, and all the .env .log .bkp .list files 
remove_function(){

    echo -e "Removing $APP_NAME..."

    # Remove symlink if it exists and points to this script
    if [[ -L "$INSTALL_PATH" ]]; then
        LINK_TARGET="$(readlink "$INSTALL_PATH")"
        if [[ "$LINK_TARGET" == "$(readlink -f "$SCRIPT_NAME")" ]]; then
            sudo rm -f "$INSTALL_PATH"
            echo -e "$INFO Symlink $INSTALL_PATH removed."
        else
            echo -e "$ERROR $INSTALL_PATH does not point to this script. Not removing."
        fi
    else
        echo -e "$INFO No symlink found at $INSTALL_PATH."
    fi

    # Remove auto-generated .env file
    if [[ -f "$ENV_FILE" ]]; then
        rm -f "$ENV_FILE"
        echo -e "$INFO $ENV_FILE file removed seccessfully"
    fi

    # Remove auto-generated .env file
    if [[ -f "$CMDS_LIST" ]]; then
        rm -f "$CMDS_LIST"
        echo -e "$INFO $CMDS_LIST file removed seccessfully"
    fi
    
    echo -e "$INFO Removal complete."

}

# Cheak if all the files need for instalation are availible 
install_cheack(){
    if [ ! -f "$SCRIPT_NAME" ]; then
    echo -e "$ERROR Could not find $SCRIPT_NAME in current directory."
    exit 1
    fi

    if [ ! -f "$ENV_TAMPLATE" ]; then 
    echo -e "$ERROR $ENV_TEMPLATE file is missing, please copy/download him from the git repository"
    exit 1
    fi

    if [ ! -f "$CMDS_LIST_TAMPLATE" ]; then 
    echo -e "$ERROR $CMDS_LIST_TAMPLATE file is missing, please copy/download him from the git repository"
    exit 1
    fi
}


# Dependencies cheack 
dependencies_cheack(){
    while IFS='=' read -r prog config_path || [[ -n "$prog" ]]; do
    
    [[ -z "$prog" || "$prog" =~ ^# ]] && continue  # skip empty lines and comments

    if ! command -v "$prog" >/dev/null 2>&1; then
        echo -e "$ERROR Missing: $prog"
        read -p "Would you like to install it? [Y/N] " choice
        if [[ "$choice" =~ ^([yY]|yes|YES|Yes|yep)$ ]]; then
            sudo apt install "$prog" -y
        else
            echo -e "$ERROR Missing dependencies, can't proceed!"
            exit 1
        fi
    fi
    done < "$CMDS_LIST_TAMPLATE"
}

# Double instalation cheack
if [[ -f "$INSTALL_PATH" ]]; then
    echo -e "$INFO $APP_NAME already exists at $INSTALL_PATH"
    read -p "Do you want to remove it? [y/N(exit)]: " confirm
    if [[ "$confirm" =~ ^([yY]|yes|YES|Yes|yep)$ ]]; then
        remove_function
    fi
    exit 0
fi

# Create symlink
echo -e "$INFO Creating symlink to $SCRIPT_NAME at $INSTALL_PATH"
SCRIPT_ABS_PATH="$(readlink -f "$SCRIPT_NAME")"
sudo ln -s "$SCRIPT_ABS_PATH" "$INSTALL_PATH"
sudo chmod +x "$SCRIPT_ABS_PATH"

# Create Backup folder 
sudo mkdir -p "$HOME/.backups"

if [[ ! -f "$ENV_FILE" && -f "$ENV_TEMPLATE" ]]; then
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    echo -e "$INFO Created $ENV_FILE from template. Please edit it."
elif [[ ! -f "$ENV_FILE" ]]; then
    echo -e "$ERROR No .env or .env.example found. You may need to create one manually."
else
    echo -e "$INFO .env file already exists. Skipping."
fi
 
echo -e "$INFO Installation complete."
