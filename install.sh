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
    echo "$ERROR Could not find $SCRIPT_NAME in current directory."
    exit 1
fi

# Dependencies cheack 
echo "$INFO Checking dependencies..."
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "$ERROR Missing : $cmd"
        MISSING=1
    fi
done

if [[ $MISSING -eq 1 ]]; then
    echo "$ERROR Please install the missing dependencies and try again."
    exit 1
fi

if [[ -f "$INSTALL_PATH" ]]; then
    echo "$INFO $APP_NAME already exists at $INSTALL_PATH"
    read -p "Do you want to overwrite it? [y/N]: " confirm
    if [[ "$confirm" != [yY] ]]; then
        echo "$INFO Installation cancelled."
        exit 0
    fi
fi

echo "$INFO Installing $APP_NAME..."
sudo cp "$SCRIPT_NAME" "$INSTALL_PATH"
sudo chmod +x "$INSTALL_PATH"

if [[ ! -f "$ENV_FILE" && -f "$ENV_TEMPLATE" ]]; then
    cp "$ENV_TEMPLATE" "$ENV_FILE"
    echo "$INFO Created $ENV_FILE from template. Please edit it."
elif [[ ! -f "$ENV_FILE" ]]; then
    echo "$ERROR No .env or .env.example found. You may need to create one manually."
else
    echo "$INFO .env file already exists. Skipping."
fi

echo "$INFO Installation complete."
