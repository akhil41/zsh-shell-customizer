#!/bin/bash

# Terminal Setup Script
# Standardizes terminal configuration across environments

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Global variables
LOG_FILE="$HOME/terminal-setup.log"
BACKUP_DIR="$HOME/.terminal-setup-backups/$(date +%Y%m%d_%H%M%S)"
OS_TYPE=""
PACKAGE_MANAGER=""

# Logging function
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $1" >> "$LOG_FILE"
    echo -e "$1"
}

# Error handling
error_exit() {
    log "${RED}ERROR: $1${NC}"
    exit 1
}

# Success message
success() {
    log "${GREEN}✓ $1${NC}"
}

# Warning message
warning() {
    log "${YELLOW}⚠ $1${NC}"
}

# Info message
info() {
    log "${BLUE}ℹ $1${NC}"
}


# User confirmation
confirm() {
    local message="$1"
    local default="${2:-n}"
    local prompt="[y/N]"

    if [[ "$default" == "y" ]]; then
        prompt="[Y/n]"
    fi

    while true; do
        read -p "$message $prompt: " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            return 0
        elif [[ $REPLY =~ ^[Nn]$ ]] || [[ -z $REPLY ]]; then
            if [[ "$default" == "y" && -z $REPLY ]]; then
                return 0
            else
                return 1
            fi
        else
            echo "Please answer yes or no."
        fi
    done
}

# Detect operating system
detect_os() {
    info "Detecting operating system..."

    if [[ "$OSTYPE" == "darwin"* ]]; then
        OS_TYPE="macos"
        if command -v brew >/dev/null 2>&1; then
            PACKAGE_MANAGER="brew"
        else
            error_exit "Homebrew is required on macOS. Please install it first: https://brew.sh"
        fi
    elif [[ "$OSTYPE" == "linux-gnu"* ]]; then
        OS_TYPE="linux"
        if command -v apt >/dev/null 2>&1; then
            PACKAGE_MANAGER="apt"
        elif command -v yum >/dev/null 2>&1; then
            PACKAGE_MANAGER="yum"
        elif command -v dnf >/dev/null 2>&1; then
            PACKAGE_MANAGER="dnf"
        elif command -v pacman >/dev/null 2>&1; then
            PACKAGE_MANAGER="pacman"
        else
            error_exit "Unsupported package manager. Please install zsh manually."
        fi
    else
        error_exit "Unsupported operating system: $OSTYPE"
    fi

    success "Detected $OS_TYPE with $PACKAGE_MANAGER package manager"
}

# Create backup directory
create_backup_dir() {
    if [[ ! -d "$BACKUP_DIR" ]]; then
        mkdir -p "$BACKUP_DIR"
        success "Created backup directory: $BACKUP_DIR"
    fi
}

# Backup file
backup_file() {
    local file="$1"
    if [[ -f "$file" ]]; then
        cp "$file" "$BACKUP_DIR/$(basename "$file").backup"
        success "Backed up $file"
    fi
}

# Install package
install_package() {
    local package="$1"
    local install_cmd=""

    case $PACKAGE_MANAGER in
        "brew")
            install_cmd="brew install $package"
            ;;
        "apt")
            install_cmd="sudo apt update && sudo apt install -y $package"
            ;;
        "yum")
            install_cmd="sudo yum install -y $package"
            ;;
        "dnf")
            install_cmd="sudo dnf install -y $package"
            ;;
        "pacman")
            install_cmd="sudo pacman -S --noconfirm $package"
            ;;
    esac

    info "Installing $package..."
    if eval "$install_cmd" >> "$LOG_FILE" 2>&1; then
        success "Installed $package"
        return 0
    else
        error_exit "Failed to install $package"
    fi
}

# Check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Install Zsh
install_zsh() {
    info "Checking Zsh installation..."

    if command_exists zsh; then
        success "Zsh is already installed"
        return 0
    fi

    info "Zsh is not installed on this system"

    if confirm "Would you like to install Zsh?" "y"; then
        # Check if sudo is needed for package installation
        if [[ "$PACKAGE_MANAGER" != "brew" ]]; then
            info "Zsh installation requires sudo privileges"
            if ! confirm "Continue with sudo installation?" "y"; then
                warning "Skipping Zsh installation - sudo access declined"
                return 1
            fi

            # Test sudo access
            if ! sudo -n true 2>/dev/null; then
                info "Please enter your password for sudo access:"
                if ! sudo -v; then
                    error_exit "Sudo authentication failed. Cannot install Zsh."
                fi
            fi
        fi

        install_package "zsh"

        # Set zsh as default shell
        if confirm "Would you like to set Zsh as your default shell?" "y"; then
            local zsh_path=$(which zsh)
            if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                info "Adding Zsh to /etc/shells (requires sudo)"
                if echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null; then
                    success "Added Zsh to /etc/shells"
                else
                    warning "Failed to add Zsh to /etc/shells"
                fi
            fi

            if chsh -s "$zsh_path" 2>/dev/null; then
                success "Set Zsh as default shell"
            else
                warning "Failed to set Zsh as default shell. You can run 'chsh -s $zsh_path' manually later."
            fi
        fi

        return 0
    else
        warning "Skipping Zsh installation - user declined"
        return 1
    fi
}

# Install Gruvbox theme for macOS Terminal
install_gruvbox_theme() {
    if [[ "$OS_TYPE" != "macos" ]]; then
        return 0
    fi

    if confirm "Would you like to install the Gruvbox Dark theme for Terminal.app?"; then
        info "Downloading Gruvbox theme..."

        local theme_url="https://raw.githubusercontent.com/mbadolato/iTerm2-Color-Schemes/master/terminal/Gruvbox%20Dark.terminal"
        local theme_file="$HOME/Downloads/Gruvbox-Dark.terminal"

        if curl -L "$theme_url" -o "$theme_file" >> "$LOG_FILE" 2>&1; then
            open "$theme_file"
            success "Downloaded Gruvbox theme. Please import it manually in Terminal preferences."
            info "The theme file has been opened in Terminal.app"
        else
            warning "Failed to download Gruvbox theme"
        fi
    else
        warning "Skipping Gruvbox theme installation"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    info "Checking Oh My Zsh installation..."

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My Zsh already installed, skipping installation"
        return 0
    fi

    if confirm "Would you like to install Oh My Zsh?" "y"; then
        info "Installing Oh My Zsh..."
        backup_file "$HOME/.zshrc"

        # Download and install Oh My Zsh
        if sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1; then
            success "Oh My Zsh installed successfully"
            return 0
        else
            warning "Oh My Zsh installation failed"
            return 1
        fi
    else
        warning "Skipping Oh My Zsh installation"
        return 1
    fi
}

# Install Hack Nerd Font
install_hack_nerd_font() {
    if confirm "Would you like to install Hack Nerd Font?"; then
        info "Installing Hack Nerd Font..."

        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
        local temp_dir=$(mktemp -d)
        local font_zip="$temp_dir/Hack.zip"

        # Download font
        if curl -L "$font_url" -o "$font_zip" >> "$LOG_FILE" 2>&1; then
            cd "$temp_dir"
            if unzip -q "$font_zip" >> "$LOG_FILE" 2>&1; then
                if [[ "$OS_TYPE" == "macos" ]]; then
                    local font_dir="$HOME/Library/Fonts"
                    mkdir -p "$font_dir"
                    if cp *.ttf "$font_dir/" 2>/dev/null; then
                        success "Installed Hack Nerd Font"
                    else
                        warning "Failed to copy font files"
                    fi
                else
                    local font_dir="$HOME/.local/share/fonts"
                    mkdir -p "$font_dir"
                    if cp *.ttf "$font_dir/" 2>/dev/null; then
                        fc-cache -fv >> "$LOG_FILE" 2>&1
                        success "Installed Hack Nerd Font"
                    else
                        warning "Failed to copy font files"
                    fi
                fi
            else
                warning "Failed to extract font archive"
            fi
            rm -rf "$temp_dir"
        else
            warning "Failed to download Hack Nerd Font"
        fi
    else
        warning "Skipping Hack Nerd Font installation"
    fi
}

# Install Powerlevel10k
install_powerlevel10k() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        warning "Oh My Zsh not found. Skipping Powerlevel10k installation."
        return 1
    fi

    if confirm "Would you like to install Powerlevel10k theme?"; then
        info "Installing Powerlevel10k..."

        local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"

        if [[ ! -d "$p10k_dir" ]]; then
            git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$p10k_dir" >> "$LOG_FILE" 2>&1
        fi

        # Update .zshrc to use powerlevel10k
        backup_file "$HOME/.zshrc"
        sed -i.bak 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"

        success "Installed Powerlevel10k theme"

        if confirm "Would you like to run the Powerlevel10k configuration wizard now?"; then
            info "You can run 'p10k configure' after restarting your terminal to configure Powerlevel10k"
        fi
    else
        warning "Skipping Powerlevel10k installation"
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        warning "Oh My Zsh not found. Skipping plugin installation."
        return 1
    fi

    if confirm "Would you like to install zsh-syntax-highlighting and zsh-autosuggestions plugins?"; then
        info "Installing Zsh plugins..."

        local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

        # Install zsh-syntax-highlighting
        if [[ ! -d "$custom_dir/plugins/zsh-syntax-highlighting" ]]; then
            git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$custom_dir/plugins/zsh-syntax-highlighting" >> "$LOG_FILE" 2>&1
        fi

        # Install zsh-autosuggestions
        if [[ ! -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
            git clone https://github.com/zsh-users/zsh-autosuggestions "$custom_dir/plugins/zsh-autosuggestions" >> "$LOG_FILE" 2>&1
        fi

        # Update .zshrc plugins
        backup_file "$HOME/.zshrc"
        if grep -q "plugins=(" "$HOME/.zshrc"; then
            # Create a temporary file for safer sed operations
            local temp_file=$(mktemp)
            cp "$HOME/.zshrc" "$temp_file"

            # Add plugins if not already present
            if ! grep -q "zsh-syntax-highlighting" "$temp_file"; then
                sed 's/plugins=(\([^)]*\))/plugins=(\1 zsh-syntax-highlighting)/' "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
            fi
            if ! grep -q "zsh-autosuggestions" "$temp_file"; then
                sed 's/plugins=(\([^)]*\))/plugins=(\1 zsh-autosuggestions)/' "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"
            fi

            # Clean up extra spaces
            sed 's/plugins=( /plugins=(/' "$temp_file" > "$temp_file.tmp" && mv "$temp_file.tmp" "$temp_file"

            cp "$temp_file" "$HOME/.zshrc"
            rm -f "$temp_file"
        fi

        success "Installed Zsh plugins"
    else
        warning "Skipping Zsh plugins installation"
    fi
}

# Install Ruby and rbenv if needed
install_ruby_environment() {
    info "Checking Ruby environment..."

    if command_exists ruby; then
        success "Ruby is already installed"
        return 0
    fi

    if confirm "Ruby is not installed. Would you like to install rbenv and Ruby?"; then
        info "Installing rbenv..."

        if [[ "$OS_TYPE" == "macos" ]]; then
            install_package "rbenv"
        else
            # Install rbenv from GitHub
            if [[ ! -d "$HOME/.rbenv" ]]; then
                git clone https://github.com/rbenv/rbenv.git "$HOME/.rbenv" >> "$LOG_FILE" 2>&1
                git clone https://github.com/rbenv/ruby-build.git "$HOME/.rbenv/plugins/ruby-build" >> "$LOG_FILE" 2>&1
            fi

            # Add rbenv to PATH
            if ! grep -q 'rbenv' "$HOME/.zshrc"; then
                echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> "$HOME/.zshrc"
                echo 'eval "$(rbenv init -)"' >> "$HOME/.zshrc"
            fi

            export PATH="$HOME/.rbenv/bin:$PATH"
            eval "$(rbenv init -)"
        fi

        # Install latest stable Ruby
        info "Installing latest stable Ruby (this may take a while)..."
        local ruby_version=$(rbenv install -l | grep -E "^[[:space:]]*[0-9]+\.[0-9]+\.[0-9]+$" | tail -1 | tr -d ' ')
        if [[ -n "$ruby_version" ]]; then
            rbenv install "$ruby_version" >> "$LOG_FILE" 2>&1
            rbenv global "$ruby_version"
            success "Installed Ruby $ruby_version"
        else
            error_exit "Could not determine latest Ruby version"
        fi
    else
        warning "Skipping Ruby installation"
        return 1
    fi
}

# Install colorls
install_colorls() {
    if ! command_exists ruby; then
        warning "Ruby not found. Skipping colorls installation."
        return 1
    fi

    if confirm "Would you like to install colorls gem and set up ls alias?"; then
        info "Installing colorls gem..."

        if gem install colorls >> "$LOG_FILE" 2>&1; then
            success "Installed colorls gem"

            # Add alias to .zshrc
            backup_file "$HOME/.zshrc"
            if ! grep -q "alias ls='colorls'" "$HOME/.zshrc"; then
                echo "" >> "$HOME/.zshrc"
                echo "# Colorls alias" >> "$HOME/.zshrc"
                echo "alias ls='colorls'" >> "$HOME/.zshrc"
                echo "alias ll='colorls -l'" >> "$HOME/.zshrc"
                echo "alias la='colorls -la'" >> "$HOME/.zshrc"
            fi

            success "Added colorls aliases to .zshrc"
        else
            warning "Failed to install colorls gem"
        fi
    else
        warning "Skipping colorls installation"
    fi
}

# Main installation summary
show_summary() {
    echo ""
    info "=== Installation Summary ==="
    echo ""

    local installed_components=()
    local skipped_components=()

    # Check what was installed
    command_exists zsh && installed_components+=("Zsh") || skipped_components+=("Zsh")
    [[ -d "$HOME/.oh-my-zsh" ]] && installed_components+=("Oh My Zsh") || skipped_components+=("Oh My Zsh")
    [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]] && installed_components+=("Powerlevel10k") || skipped_components+=("Powerlevel10k")
    [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" ]] && installed_components+=("Zsh Plugins") || skipped_components+=("Zsh Plugins")
    command_exists ruby && installed_components+=("Ruby") || skipped_components+=("Ruby")
    (command_exists gem && gem list | grep -q colorls 2>/dev/null) && installed_components+=("Colorls") || skipped_components+=("Colorls")

    if [[ ${#installed_components[@]} -gt 0 ]]; then
        success "Installed components:"
        for component in "${installed_components[@]}"; do
            echo "  ✓ $component"
        done
    fi

    if [[ ${#skipped_components[@]} -gt 0 ]]; then
        warning "Skipped components:"
        for component in "${skipped_components[@]}"; do
            echo "  - $component"
        done
    fi

    echo ""
    info "Configuration files backed up to: $BACKUP_DIR"
    info "Installation log saved to: $LOG_FILE"
    echo ""

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Next steps:"
        echo "1. Restart your terminal or run: source ~/.zshrc"
        if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
            echo "2. Run 'p10k configure' to configure Powerlevel10k"
        fi
        if command_exists colorls; then
            echo "3. Try 'ls' to see colorls in action"
        fi
    fi
}

# Main function
main() {
    echo ""
    info "=== Terminal Setup Script ==="
    info "This script will help you set up a standardized terminal environment"
    echo ""

    # Initialize
    create_backup_dir
    detect_os

    # Install components
    install_zsh || exit 1
    install_gruvbox_theme
    install_oh_my_zsh
    install_hack_nerd_font
    install_powerlevel10k
    install_zsh_plugins
    install_ruby_environment
    install_colorls

    # Show summary
    show_summary

    success "Terminal setup completed!"
}

# Handle script interruption
trap 'echo ""; warning "Script interrupted by user"; exit 1' INT

# Run main function
main "$@"
