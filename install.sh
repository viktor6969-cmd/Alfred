#!/usr/bin/env bash

set -euo pipefail

APP_NAME="alfred"
SCRIPT_NAME="alfred.sh"
INSTALL_PATH="/usr/local/bin/$APP_NAME"

ENV_FILE=".env"
ENV_TEMPLATE=".env.example"

DEPS_FILE=".dep.list"
DEPS_TEMPLATE=".dep.list.example"

INFO="\e[33m[!]\e[0m"
ERROR="\e[31m[-]\e[0m"
YES_REGEX="^([yY]|yes|YES|Yes|yep)$"

# Utility function to print info messages
print_info() {
    echo -e "$INFO $1"
}

# Utility function to print error messages
print_error() {
    echo -e "$ERROR $1"
}

# Detect system package manager
detect_package_manager() {
    local managers=(apt dnf pacman zypper apk brew)
    for m in "${managers[@]}"; do
        command -v "$m" >/dev/null 2>&1 && echo "$m" && return
    done
    print_error "No supported package manager found."
    return 1
}

# Install package using detected package manager
install_package() {
    local pkg="$1"
    local mgr
    mgr=$(detect_package_manager)

    case "$mgr" in
        apt) sudo apt install -y "$pkg" ;;
        dnf) sudo dnf install -y "$pkg" ;;
        pacman) sudo pacman -Sy --noconfirm "$pkg" ;;
        zypper) sudo zypper install -y "$pkg" ;;
        apk) sudo apk add "$pkg" ;;
        brew) brew install "$pkg" ;;
        *) print_error "Unsupported package manager: $mgr"; exit 1 ;;
    esac
}

# Remove symlink, .env, .dep.list and other related files
remove_alfred() {
    print_info "Removing $APP_NAME..."

    # Remove symlink if it exists and points to this script
    if [[ -L "$INSTALL_PATH" && "$(readlink "$INSTALL_PATH")" == "$(readlink -f "$SCRIPT_NAME")" ]]; then
        sudo rm -f "$INSTALL_PATH"
        print_info "Symlink removed from $INSTALL_PATH"
    else
        print_info "No matching symlink found at $INSTALL_PATH. Skipping."
    fi

    # Remove generated config files
    for f in "$ENV_FILE" "$DEPS_FILE"; do
        [[ -f "$f" ]] && rm -f "$f" && print_info "$f removed."
    done
}

# Create a config file from a template if it doesn't already exist
copy_if_missing() {
    local target="$1"
    local template="$2"

    [[ -f "$target" ]] && print_info "$target already exists. Skipping." && return
    [[ -f "$template" ]] || { print_error "$template not found."; exit 1; }

    cp "$template" "$target"
    print_info "Created $target from template. Please review it."
}

# Prevent double installation if the symlink already exists
check_existing_install() {
    if [[ -f "$INSTALL_PATH" ]]; then
        print_info "$APP_NAME already installed at $INSTALL_PATH"
        read -p "Remove it first? [y/N]: " confirm
        [[ "$confirm" =~ $YES_REGEX ]] && remove_alfred
        exit 0
    fi
}

# Ensure all required files for installation exist
validate_install_files() {
    [[ -f "$SCRIPT_NAME" ]] || { print_error "$SCRIPT_NAME not found."; exit 1; }
    [[ -f "$ENV_TEMPLATE" ]] || { print_error "$ENV_TEMPLATE is missing."; exit 1; }
    [[ -f "$DEPS_TEMPLATE" ]] || { print_error "$DEPS_TEMPLATE is missing."; exit 1; }
}

# Check for and optionally install missing dependencies
check_dependencies() {
    while IFS='=' read -r prog _ || [[ -n "$prog" ]]; do
        # Skip comments and empty lines
        [[ -z "$prog" || "$prog" =~ ^# ]] && continue

        if ! command -v "$prog" >/dev/null 2>&1; then
            print_error "Missing: $prog"
            read -p "Install it now? [y/N]: " choice
            if [[ "$choice" =~ $YES_REGEX ]]; then
                install_package "$prog"
            else
                print_error "Can't continue without $prog"
                exit 1
            fi
        fi
    done < "$DEPS_TEMPLATE"
}

# Main installation function
install_alfred() {
    print_info "Creating symlink to $SCRIPT_NAME at $INSTALL_PATH"
    local script_abs
    script_abs="$(readlink -f "$SCRIPT_NAME")"
    sudo ln -sf "$script_abs" "$INSTALL_PATH"
    sudo chmod +x "$script_abs"

    # Ensure .backups directory exists
    [[ -d "$HOME/.backups" ]] || sudo mkdir -p "$HOME/.backups"
    print_info ".backups folder ready"

    # Generate missing config files from templates
    copy_if_missing "$ENV_FILE" "$ENV_TEMPLATE"
    copy_if_missing "$DEPS_FILE" "$DEPS_TEMPLATE"

    print_info "$APP_NAME installation complete."
}

# === Main execution flow ===
check_existing_install
validate_install_files
check_dependencies
install_alfred

exit 0

install_alfred

exit 0
