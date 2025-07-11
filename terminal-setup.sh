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
AUTO_CONFIRM=false

# Parse command line arguments
parse_arguments() {
    while [[ $# -gt 0 ]]; do
        case $1 in
            -y|--yes)
                AUTO_CONFIRM=true
                shift
                ;;
            -h|--help)
                show_help
                exit 0
                ;;
            *)
                warning "Unknown option: $1"
                show_help
                exit 1
                ;;
        esac
    done
}

# Show help message
show_help() {
    echo "Terminal Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -y, --yes    Auto-confirm all installation prompts"
    echo "  -h, --help   Show this help message"
    echo ""
    echo "Examples:"
    echo "  $0           # Interactive mode with confirmation prompts"
    echo "  $0 --yes     # Auto-confirm all installations"
}

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

    # Auto-confirm if flag is set
    if [[ "$AUTO_CONFIRM" == "true" ]]; then
        info "$message [AUTO-CONFIRMED]"
        return 0
    fi

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

# Verification functions
verify_zsh_installation() {
    if command_exists zsh && [[ "$SHELL" == *"zsh"* ]]; then
        success "Zsh installation verified"
        return 0
    else
        warning "Zsh installation verification failed"
        return 1
    fi
}

verify_oh_my_zsh_installation() {
    if [[ -d "$HOME/.oh-my-zsh" ]] && [[ -f "$HOME/.zshrc" ]]; then
        success "Oh My Zsh installation verified"
        return 0
    else
        warning "Oh My Zsh installation verification failed"
        return 1
    fi
}

verify_powerlevel10k_installation() {
    local p10k_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
    if [[ -d "$p10k_dir" ]] && grep -q "powerlevel10k" "$HOME/.zshrc" 2>/dev/null; then
        success "Powerlevel10k installation verified"
        return 0
    else
        warning "Powerlevel10k installation verification failed"
        return 1
    fi
}

verify_plugins_installation() {
    local custom_dir="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
    if [[ -d "$custom_dir/plugins/zsh-syntax-highlighting" ]] && [[ -d "$custom_dir/plugins/zsh-autosuggestions" ]]; then
        success "Zsh plugins installation verified"
        return 0
    else
        warning "Zsh plugins installation verification failed"
        return 1
    fi
}

# Rollback function
rollback_installation() {
    local component="$1"
    warning "Rolling back $component installation..."

    case "$component" in
        "zsh")
            if [[ -f "$BACKUP_DIR/zshrc.backup" ]]; then
                cp "$BACKUP_DIR/zshrc.backup" "$HOME/.zshrc"
                info "Restored .zshrc from backup"
            fi
            ;;
        "oh-my-zsh")
            if [[ -d "$HOME/.oh-my-zsh" ]]; then
                rm -rf "$HOME/.oh-my-zsh"
                info "Removed Oh My Zsh directory"
            fi
            if [[ -f "$BACKUP_DIR/zshrc.backup" ]]; then
                cp "$BACKUP_DIR/zshrc.backup" "$HOME/.zshrc"
                info "Restored .zshrc from backup"
            fi
            ;;
    esac
}

# Check sudo requirements upfront
check_sudo_requirements() {
    info "Checking system requirements..."

    local needs_sudo=false

    if [[ "$PACKAGE_MANAGER" != "brew" ]]; then
        needs_sudo=true
    fi

    if [[ "$needs_sudo" == "true" ]]; then
        info "This script requires sudo privileges for:"
        echo "  • Installing system packages (zsh, unzip)"
        echo "  • Modifying /etc/shells"
        echo "  • Changing default shell"
        echo ""

        if ! confirm "Do you want to proceed with sudo requirements?" "y"; then
            error_exit "Script cancelled - sudo privileges required"
        fi

        # Test sudo access early
        if ! sudo -n true 2>/dev/null; then
            info "Please enter your password for sudo access:"
            if ! sudo -v; then
                error_exit "Sudo authentication failed"
            fi
        fi

        success "Sudo access confirmed"
    fi
}

# Install Zsh
install_zsh() {
    info "Checking Zsh installation..."

    if command_exists zsh; then
        success "Zsh is already installed"
        return 0
    fi

    info "Zsh is not installed on this system"
    info "Zsh will be installed as your default shell with Oh My Zsh framework support"

    if confirm "Would you like to install Zsh?"; then
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
        if confirm "Would you like to set Zsh as your default shell?"; then
            local zsh_path=$(which zsh)
            info "Setting up Zsh as default shell..."

            if ! grep -q "$zsh_path" /etc/shells 2>/dev/null; then
                info "Adding Zsh to /etc/shells (requires sudo)"
                if echo "$zsh_path" | sudo tee -a /etc/shells >/dev/null; then
                    success "Added Zsh to /etc/shells"
                else
                    warning "Failed to add Zsh to /etc/shells"
                    return 1
                fi
            fi

            if chsh -s "$zsh_path" 2>/dev/null; then
                success "Set Zsh as default shell"

                # Verify shell change
                if [[ "$SHELL" != "$zsh_path" ]]; then
                    export SHELL="$zsh_path"
                fi

                # Switch to zsh if we're currently running in bash
                if [[ "$0" == *"bash"* ]] || [[ "$(ps -p $$ -o comm=)" == *"bash"* ]]; then
                    info "Switching to Zsh to continue setup..."
                    info "Remaining setup will continue in Zsh environment"
                    exec "$zsh_path" "$0" "$@"
                fi
            else
                warning "Failed to set Zsh as default shell"
                info "You can manually set it later with: chsh -s $zsh_path"
                return 1
            fi
        else
            warning "Skipping default shell change - user declined"
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

    info "Gruvbox Dark theme provides a warm, retro color scheme for Terminal.app"
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
        warning "Skipping Gruvbox theme installation - user declined"
    fi
}

# Install Oh My Zsh
install_oh_my_zsh() {
    info "Checking Oh My Zsh installation..."

    if [[ -d "$HOME/.oh-my-zsh" ]]; then
        info "Oh My Zsh already installed, skipping installation"
        return 0
    fi

    info "Oh My Zsh is a framework for managing Zsh configuration with themes and plugins"
    if confirm "Would you like to install Oh My Zsh?"; then
        info "Installing Oh My Zsh..."
        backup_file "$HOME/.zshrc"

        # Download and install Oh My Zsh
        if sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended >> "$LOG_FILE" 2>&1; then
            success "Oh My Zsh installed successfully"

            # Verify installation
            if verify_oh_my_zsh_installation; then
                return 0
            else
                warning "Oh My Zsh installation verification failed"
                if confirm "Would you like to rollback this installation?"; then
                    rollback_installation "oh-my-zsh"
                fi
                return 1
            fi
        else
            warning "Oh My Zsh installation failed"
            return 1
        fi
    else
        warning "Skipping Oh My Zsh installation - user declined"
        return 1
    fi
}

# Install Hack Nerd Font
install_hack_nerd_font() {
    info "Hack Nerd Font provides programming ligatures and icons for your terminal (~14MB download)"
    if confirm "Would you like to install Hack Nerd Font?"; then
        info "Installing Hack Nerd Font..."

        # Check if unzip is available
        if ! command_exists unzip; then
            if [[ "$PACKAGE_MANAGER" == "apt" ]]; then
                info "Installing unzip package..."
                if ! install_package "unzip"; then
                    warning "Failed to install unzip. Cannot extract font archive."
                    return 1
                fi
            else
                warning "unzip command not found. Please install unzip and try again."
                return 1
            fi
        fi

        local font_url="https://github.com/ryanoasis/nerd-fonts/releases/download/v3.1.1/Hack.zip"
        local temp_dir=$(mktemp -d)
        local font_zip="$temp_dir/Hack.zip"

        info "Downloading font from $font_url..."
        # Download font with better error handling
        if curl -L --fail --connect-timeout 30 --max-time 300 "$font_url" -o "$font_zip" >> "$LOG_FILE" 2>&1; then
            # Validate downloaded file
            if [[ ! -f "$font_zip" ]]; then
                warning "Downloaded font file not found"
                rm -rf "$temp_dir"
                return 1
            fi

            # Check if file is actually a zip file
            if ! file "$font_zip" | grep -q "Zip archive"; then
                warning "Downloaded file is not a valid zip archive"
                log "File type: $(file "$font_zip")"
                rm -rf "$temp_dir"
                return 1
            fi

            local file_size=$(stat -c%s "$font_zip" 2>/dev/null || stat -f%z "$font_zip" 2>/dev/null || echo "0")
            if [[ "$file_size" -lt 1000000 ]]; then  # Less than 1MB seems too small
                warning "Downloaded font file appears to be too small ($file_size bytes)"
                rm -rf "$temp_dir"
                return 1
            fi

            success "Font downloaded successfully ($file_size bytes)"

            cd "$temp_dir"
            info "Extracting font archive..."
            if unzip -q "$font_zip" >> "$LOG_FILE" 2>&1; then
                # Verify extraction worked
                local ttf_count=$(find . -name "*.ttf" | wc -l)
                if [[ "$ttf_count" -eq 0 ]]; then
                    warning "No TTF font files found after extraction"
                    rm -rf "$temp_dir"
                    return 1
                fi

                info "Found $ttf_count font files"

                if [[ "$OS_TYPE" == "macos" ]]; then
                    local font_dir="$HOME/Library/Fonts"
                    mkdir -p "$font_dir"
                    if find . -name "*.ttf" -exec cp {} "$font_dir/" \; 2>/dev/null; then
                        success "Installed Hack Nerd Font to $font_dir"
                    else
                        warning "Failed to copy font files to $font_dir"
                        rm -rf "$temp_dir"
                        return 1
                    fi
                else
                    local font_dir="$HOME/.local/share/fonts"
                    mkdir -p "$font_dir"
                    if find . -name "*.ttf" -exec cp {} "$font_dir/" \; 2>/dev/null; then
                        info "Refreshing font cache..."
                        if fc-cache -fv >> "$LOG_FILE" 2>&1; then
                            success "Installed Hack Nerd Font to $font_dir"
                        else
                            warning "Font files copied but font cache refresh failed"
                        fi
                    else
                        warning "Failed to copy font files to $font_dir"
                        rm -rf "$temp_dir"
                        return 1
                    fi
                fi
            else
                warning "Failed to extract font archive"
                log "Extraction error details logged to $LOG_FILE"
                rm -rf "$temp_dir"
                return 1
            fi
            rm -rf "$temp_dir"
        else
            warning "Failed to download Hack Nerd Font"
            log "Download error details logged to $LOG_FILE"
            rm -rf "$temp_dir"
            return 1
        fi
    else
        warning "Skipping Hack Nerd Font installation - user declined"
    fi
}

# Install Powerlevel10k
install_powerlevel10k() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        warning "Oh My Zsh not found. Powerlevel10k requires Oh My Zsh to be installed first."
        return 1
    fi

    info "Powerlevel10k is a fast and highly customizable Zsh theme with rich prompts"
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

        # Verify installation
        if verify_powerlevel10k_installation; then
            if confirm "Would you like to configure Powerlevel10k now?" "n"; then
                info "Run 'p10k configure' after restarting your terminal to configure Powerlevel10k"
            fi
        else
            warning "Powerlevel10k installation verification failed"
            return 1
        fi
    else
        warning "Skipping Powerlevel10k installation - user declined"
    fi
}

# Install Zsh plugins
install_zsh_plugins() {
    if [[ ! -d "$HOME/.oh-my-zsh" ]]; then
        warning "Oh My Zsh not found. Zsh plugins require Oh My Zsh to be installed first."
        return 1
    fi

    info "Zsh plugins provide syntax highlighting and fish-like autosuggestions"
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

        # Verify installation
        if ! verify_plugins_installation; then
            warning "Plugin installation verification failed"
            return 1
        fi
    else
        warning "Skipping Zsh plugins installation - user declined"
    fi
}

# Install Ruby and rbenv if needed
install_ruby_environment() {
    info "Checking Ruby environment..."

    if command_exists ruby; then
        success "Ruby is already installed"
        return 0
    fi

    info "Ruby environment with rbenv will be installed for colorls gem support"
    info "This may take 10-30 minutes to compile Ruby from source"
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
        warning "Skipping Ruby installation - user declined"
        return 1
    fi
}

# Install colorls
install_colorls() {
    if ! command_exists ruby; then
        warning "Ruby not found. Colorls requires Ruby to be installed first."
        return 1
    fi

    info "Colorls provides a colorful and icon-rich replacement for the ls command"
    if confirm "Would you like to install colorls gem and set up ls aliases?"; then
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
        warning "Skipping colorls installation - user declined"
    fi
}

# Show installation plan
show_installation_plan() {
    echo ""
    info "=== 📋 Installation Plan ==="
    echo ""
    info "The following components will be offered for installation:"
    echo ""
    echo "🔧 Core Components:"
    echo "  • Zsh shell (if not already installed)"
    echo "  • Oh My Zsh framework"
    echo "  • Powerlevel10k theme"
    echo "  • Zsh plugins (syntax highlighting & autosuggestions)"
    echo ""
    echo "🎨 Visual Enhancements:"
    echo "  • Hack Nerd Font (~14MB download)"
    if [[ "$OS_TYPE" == "macos" ]]; then
        echo "  • Gruvbox Dark terminal theme"
    fi
    echo ""
    echo "💎 Ruby Environment:"
    echo "  • rbenv and latest Ruby (if not installed)"
    echo "  • colorls gem with ls aliases"
    echo ""
    echo "⚙️ Installation Features:"
    echo "  • User confirmation for each component"
    echo "  • Automatic backups of configuration files"
    echo "  • Comprehensive logging and error handling"
    echo "  • Safe to run multiple times"
    echo ""
    if [[ "$AUTO_CONFIRM" == "true" ]]; then
        warning "AUTO-CONFIRM MODE: All prompts will be automatically accepted"
    else
        info "You will be prompted before installing each component"
    fi
    echo ""
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

# Post-installation guide
show_post_installation_guide() {
    echo ""
    info "=== 🎉 Installation Complete! ==="
    echo ""

    info "📋 Next Steps:"
    echo ""

    echo "1. 🔄 Restart your terminal or run:"
    echo "   source ~/.zshrc"
    echo ""

    if [[ -d "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" ]]; then
        echo "2. 🎨 Configure Powerlevel10k theme:"
        echo "   p10k configure"
        echo ""
        echo "   This will launch an interactive wizard to customize your prompt."
        echo "   You can re-run this anytime to change your theme."
        echo ""
    fi

    if command_exists colorls; then
        echo "3. 🌈 Test colorls:"
        echo "   ls"
        echo "   ll"
        echo "   la"
        echo ""
    fi

    echo "4. 🔧 Additional Configuration:"
    echo "   • Edit ~/.zshrc to customize your shell"
    echo "   • Add custom aliases and functions"
    echo "   • Install additional Oh My Zsh plugins"
    echo ""

    info "📚 Useful Commands:"
    echo "   • omz update          - Update Oh My Zsh"
    echo "   • omz plugin list     - List available plugins"
    echo "   • omz theme list      - List available themes"
    echo "   • p10k configure      - Reconfigure Powerlevel10k"
    echo ""

    info "🔍 Troubleshooting:"
    echo "   • If fonts look wrong: Install Hack Nerd Font in your terminal"
    echo "   • If colors are off: Check terminal color scheme settings"
    echo "   • If plugins don't work: Run 'source ~/.zshrc'"
    echo ""

    info "📁 Files and Locations:"
    echo "   • Configuration: ~/.zshrc"
    echo "   • Oh My Zsh: ~/.oh-my-zsh/"
    echo "   • Backups: $BACKUP_DIR"
    echo "   • Logs: $LOG_FILE"
    echo ""

    if [[ "$OS_TYPE" == "macos" ]] && [[ -f "$HOME/Downloads/Gruvbox-Dark.terminal" ]]; then
        echo "5. 🎨 Terminal Theme (macOS):"
        echo "   • Open Terminal preferences"
        echo "   • Import Gruvbox-Dark.terminal from Downloads"
        echo "   • Set as default profile"
        echo ""
    fi

    success "Your terminal is now ready! Enjoy your enhanced shell experience! 🚀"
}

# Main function
main() {
    # Parse command line arguments
    parse_arguments "$@"

    echo ""
    info "=== 🚀 Terminal Setup Script ==="
    info "Standardizes terminal configuration across macOS and Linux"
    echo ""

    # Initialize
    create_backup_dir
    detect_os
    show_installation_plan

    if ! confirm "Do you want to proceed with the installation?" "y"; then
        info "Installation cancelled by user"
        exit 0
    fi

    check_sudo_requirements

    # Install components with user confirmation
    info "Starting installation process..."
    echo ""

    local step=1
    local total_steps=8

    info "[$step/$total_steps] Zsh Shell Installation"
    if install_zsh; then
        verify_zsh_installation || warning "Zsh verification failed but continuing..."
    else
        error_exit "Zsh installation failed - cannot continue"
    fi
    ((step++))

    echo ""
    info "[$step/$total_steps] Terminal Theme Installation"
    install_gruvbox_theme
    ((step++))

    echo ""
    info "[$step/$total_steps] Oh My Zsh Framework Installation"
    install_oh_my_zsh
    ((step++))

    echo ""
    info "[$step/$total_steps] Hack Nerd Font Installation"
    install_hack_nerd_font
    ((step++))

    echo ""
    info "[$step/$total_steps] Powerlevel10k Theme Installation"
    install_powerlevel10k
    ((step++))

    echo ""
    info "[$step/$total_steps] Zsh Plugins Installation"
    install_zsh_plugins
    ((step++))

    echo ""
    info "[$step/$total_steps] Ruby Environment Installation"
    install_ruby_environment
    ((step++))

    echo ""
    info "[$step/$total_steps] Colorls Installation"
    install_colorls

    # Show summary and guide
    show_summary
    show_post_installation_guide
}

# Handle script interruption
trap 'echo ""; warning "Script interrupted by user"; exit 1' INT

# Run main function
main "$@"
