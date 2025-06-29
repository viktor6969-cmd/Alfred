#!/bin/bash

APP_NAME="alfred"
SCRIPT_NAME="alfred.sh"
INSTALL_PATH="/usr/local/bin/$APP_NAME"
ENV_FILE=".env"
ENV_TEMPLATE=".env.example"
REQUIRED_CMDS=("bash" "nc" "ufw" "fail2ban")
INFO="\e[33m[!]\e[0m"
ERROR="\e[31m[-]\e[0m"
# Directory cheack 
if [ ! -f "$SCRIPT_NAME" ]; then
    echo -e "$ERROR Could not find $SCRIPT_NAME in current directory."
    exit 1
fi

# Dependencies cheack 
echo "$INFO Checking dependencies..."
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo -e "$ERROR Missing : $cmd"
        read -p "Would you like to install it? [Y/N]?" choice
        if [[ "$choice" == [[yY]] ]]; then
            sudo apt install $cmd -y
        else
            echo -e "$ERROR Missing dependencies, can't proceed with the installation!"
            exit 1
        fi
    fi
done

# Double instalation cheack
if [[ -f "$INSTALL_PATH" ]]; then
    echo -e "$INFO $APP_NAME already exists at $INSTALL_PATH"
    read -p "Do you want to overwrite it? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo -e "$INFO Installation cancelled."
        exit 0
    fi
fi

echo -e "$INFO Installing $APP_NAME..."
sudo cp "$SCRIPT_NAME" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

if [[ ! -f "$ENV_FILE" && -f "$ENV_TEMPLATE" ]]; then
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    echo -e "$INFO Created $ENV_FILE from template. Please edit it."
elif [[ ! -f "$ENV_FILE" ]]; then
    echo -e "$ERROR No .env or .env.example found. You may need to create one manually."
else
    echo -e "$INFO .env file already exists. Skipping."
fi
 
echo -e "$INFO Installation complete."
