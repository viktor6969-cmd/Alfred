#!/usr/bin/env bash

# To do: no bugs 
# + Fix the fail2ban chack in instalation
# + Fix the confarmetion massage on removeal 
# + Ask if there a need to remove beckup files 

set -euo pipefail
source "$(dirname "$0")/utils.sh"


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
        print_info "No matching symlink found at $INSTALL_PATH - Skipping."
    fi

    # See if there any backups, and ask the user if he wis to remove them
    if [[ -d ".backups" ]]; then 
        read -p "Do you wish to remove all the backup files from the system? (.backups folder)? [y/n]: " confirm
        [[ "$confirm" =~ $YES_REGEX ]] && { sudo rm -r .backups; print_info "All the backups has been removed"; }
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
        read -p "Do you wish to remove curent instalation? (including .env .dep.list etc) [y/n]: " confirm
        [[ "$confirm" =~ $YES_REGEX ]] && remove_alfred
        exit 0
    fi
    return 0
}

# Ensure all required files for installation exist
validate_install_files() {
    [[ -f "$SCRIPT_NAME" ]] || { print_error "$SCRIPT_NAME not found."; exit 1; }
    [[ -f "$ENV_TEMPLATE" ]] || { print_error "$ENV_TEMPLATE is missing."; exit 1; }
    [[ -f "$DEPS_TEMPLATE" ]] || { print_error "$DEPS_TEMPLATE is missing."; exit 1; }
}

# Check for and optionally install missing dependencies
check_dependencies() {
    missing=()
    sed -i 's/\r$//' "$DEPS_TEMPLATE"
    while IFS=':' read -r prog binary conf; do
        [[ -z "$prog" || "$prog" =~ ^# ]] && continue
        [[ -z "$binary" ]] && binary="$prog"

        if ! command -v "$binary" &>/dev/null; then
            echo "[-] Missing: $prog ($binary)"
            missing+=("$prog")
        fi

        if [[ -n "$conf" && ! -e "$conf" ]]; then
            echo "[-] Config missing for $prog: $conf"
        fi
    done < "$DEPS_TEMPLATE"

    if (( ${#missing[@]} )); then
        print_error "Missing dependencies: ${missing[*]}"
        read -p "Install them all now? [y/N]: " confirm < /dev/tty
        [[ "$confirm" =~ $YES_REGEX ]] || { print_error "Cannot continue."; exit 1; }

        for pkg in "${missing[@]}"; do
            install_package "$pkg"
        done
    fi
}


# Main installation function
install_alfred() {
    print_success "Creating symlink to $SCRIPT_NAME at $INSTALL_PATH"
    local script_abs
    script_abs="$(readlink -f "$SCRIPT_NAME")"
    sudo ln -sf "$script_abs" "$INSTALL_PATH"
    sudo chmod +x "$script_abs"

    # Ensure .backups directory exists
    [[ -d "$SCRIPT_DIR/.backups" ]] || sudo mkdir -p "$SCRIPT_DIR/.backups"
    print_success ".backups folder ready"

    # Generate missing config files from templates
    copy_if_missing "$ENV_FILE" "$ENV_TEMPLATE"
    copy_if_missing "$DEPS_FILE" "$DEPS_TEMPLATE"

    print_success "$APP_NAME installation complete."
}

# === Main execution flow ===
has_sudo || { print_error "This script requires sudo access."; exit 1; }
check_existing_install
validate_install_files
check_dependencies
install_alfred

exit 0
