#!/usr/bin/env bash
set -e

prompt() {
  read -rp "$1 [y/N] " ans
  [[ $ans =~ ^([Yy]|yes)$ ]]
}

# 1. Set Zsh as default shell
if prompt "Make Zsh the default shell?"; then
  if command -v zsh >/dev/null 2>&1; then
    if [ "$SHELL" != "$(command -v zsh)" ]; then
      echo "Changing shell to zsh..."
      chsh -s "$(command -v zsh)"
    else
      echo "Zsh is already the default shell."
    fi
  else
    echo "Zsh not found. Please install zsh first."
  fi
fi

echo
# 2. Gruvbox instructions
if prompt "Install Gruvbox Dark theme?"; then
  cat <<'GRUV'
To enable the Gruvbox Dark theme:
1. Open your terminal preferences.
2. Choose the Gruvbox Dark color scheme.
3. Apply the theme and restart the terminal if needed.
GRUV
fi

echo
# 3. Oh My Zsh
if prompt "Install Oh My Zsh?"; then
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    echo "Installing Oh My Zsh..."
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh already installed."
  fi
fi

# Utility to modify .zshrc safely
add_line() {
  grep -qxF "$1" "$HOME/.zshrc" || echo "$1" >> "$HOME/.zshrc"
}

# 4. Hack Nerd Font
if prompt "Install Hack Nerd Font?"; then
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"
  echo "Downloading Hack Nerd Font..."
  curl -fLo /tmp/Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip
  unzip -o /tmp/Hack.zip -d "$FONT_DIR" >/dev/null
  fc-cache -fv "$FONT_DIR"
fi

echo
# 5. Powerlevel10k
if prompt "Install Powerlevel10k theme?"; then
  THEME_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ ! -d "$THEME_DIR" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
  fi
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
fi

# 6. zsh-syntax-highlighting
if prompt "Install zsh-syntax-highlighting?"; then
  PLUG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ ! -d "$PLUG_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUG_DIR"
  fi
  sed -i 's/plugins=(/plugins=(zsh-syntax-highlighting /' "$HOME/.zshrc"
fi

# 7. zsh-autosuggestions
if prompt "Install zsh-autosuggestions?"; then
  PLUG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [ ! -d "$PLUG_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUG_DIR"
  fi
  sed -i 's/plugins=(/plugins=(zsh-autosuggestions /' "$HOME/.zshrc"
fi

# 8. colorls
if prompt "Install colorls?"; then
  if command -v gem >/dev/null 2>&1; then
    gem install --user-install colorls
    add_line "alias cls='colorls'"
    add_line "alias l='colorls -lA'"
    add_line "alias tree='colorls --tree'"
  else
    echo "Ruby gem not found. Please install Ruby first."
  fi
fi

echo "\nInstallation complete. Restart your terminal or run 'exec zsh' to start using Zsh."
