#!/usr/bin/env bash
set -e

prompt() {
  read -rp "$1 [y/N] " ans
  [[ $ans =~ ^([Yy]|yes)$ ]]
}

if ! prompt "Proceed with zsh-shell customization?"; then
  echo "Aborted." && exit 0
fi

# 1. Set Zsh as default shell
if command -v zsh >/dev/null 2>&1; then
  if [ "$SHELL" != "$(command -v zsh)" ]; then
    if prompt "Set Zsh as your default shell?"; then
      echo "Changing shell to zsh..."
      chsh -s "$(command -v zsh)"
    fi
  else
    echo "Zsh is already the default shell."
  fi
else
  echo "Zsh not found. Please install zsh first."
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

if prompt "Install Oh My Zsh?"; then
  echo "Installing Oh My Zsh..."
  if [ ! -d "$HOME/.oh-my-zsh" ]; then
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
  else
    echo "Oh My Zsh already installed."
  fi
fi

touch "$HOME/.zshrc"
add_line() {
  grep -qxF "$1" "$HOME/.zshrc" || echo "$1" >> "$HOME/.zshrc"
}

if prompt "Install Hack Nerd Font?"; then
  echo "Installing Hack Nerd Font..."
  FONT_DIR="$HOME/.local/share/fonts"
  mkdir -p "$FONT_DIR"
  curl -fLo /tmp/Hack.zip https://github.com/ryanoasis/nerd-fonts/releases/download/v3.0.2/Hack.zip
  unzip -o /tmp/Hack.zip -d "$FONT_DIR" >/dev/null
  fc-cache -fv "$FONT_DIR"
fi

if prompt "Install Powerlevel10k theme?"; then
  echo "Installing Powerlevel10k theme..."
  THEME_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k"
  if [ ! -d "$THEME_DIR" ]; then
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "$THEME_DIR"
  fi
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="powerlevel10k\/powerlevel10k"/' "$HOME/.zshrc"
fi

if prompt "Install zsh-syntax-highlighting plugin?"; then
  echo "Installing zsh-syntax-highlighting..."
  PLUG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting"
  if [ ! -d "$PLUG_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "$PLUG_DIR"
  fi
  grep -q zsh-syntax-highlighting "$HOME/.zshrc" || sed -i 's/plugins=(/plugins=(zsh-syntax-highlighting /' "$HOME/.zshrc"
fi

if prompt "Install zsh-autosuggestions plugin?"; then
  echo "Installing zsh-autosuggestions..."
  PLUG_DIR="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions"
  if [ ! -d "$PLUG_DIR" ]; then
    git clone https://github.com/zsh-users/zsh-autosuggestions "$PLUG_DIR"
  fi
  grep -q zsh-autosuggestions "$HOME/.zshrc" || sed -i 's/plugins=(/plugins=(zsh-autosuggestions /' "$HOME/.zshrc"
fi

if prompt "Install colorls and aliases?"; then
  echo "Installing colorls..."
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
