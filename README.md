# zsh-shell-customizer

> Seamlessly synchronize your terminal experience across macOS and Linux.
> Includes Zsh shell, Gruvbox Dark theme, Nerd Fonts, Powerlevel10k, plugins, and more.

---

## ⚙️ What This Script Does

This setup script customizes your terminal environment consistently across **macOS and Linux** by:

1. **Installing Zsh** as the default shell with automatic package manager detection
2. **Installing Gruvbox Dark theme** for macOS Terminal.app (with user confirmation)
3. **Installing and configuring Oh My Zsh** framework
4. **Installing Hack Nerd Font** with OS-specific installation paths
5. **Installing Powerlevel10k** theme with configuration wizard option
6. **Installing essential Zsh plugins**:
   - `zsh-syntax-highlighting` - Syntax highlighting for commands
   - `zsh-autosuggestions` - Fish-like autosuggestions
7. **Setting up Ruby environment** with rbenv and latest stable Ruby
8. **Installing colorls gem** with convenient aliases (`ls`, `ll`, `la`)
9. **Creating automatic backups** of all modified configuration files
10. **Comprehensive logging** of all installation steps

---

## 🚀 Quick Start

```bash
# Download and run the script
curl -fsSL https://raw.githubusercontent.com/akhil41/zsh-shell-customizer/main/terminal-setup.sh | bash

# Or clone and run locally
git clone https://github.com/akhil41/zsh-shell-customizer.git
cd zsh-shell-customizer
chmod +x terminal-setup.sh
./terminal-setup.sh
```

---

## 📋 Prerequisites

### macOS

- **Homebrew** - Install from [brew.sh](https://brew.sh)
- **Xcode Command Line Tools** - `xcode-select --install`

### Linux

- One of the supported package managers:
  - `apt` (Ubuntu/Debian)
  - `yum` (CentOS/RHEL)
  - `dnf` (Fedora)
  - `pacman` (Arch Linux)
- `curl` and `git` installed

---

## 🎯 Features

### Interactive Installation

- **User confirmation** for each installation step
- **Progress indicators** and detailed status messages
- **Graceful cancellation** - stop at any point without breaking your system
- **Idempotent design** - safe to run multiple times

### Backup & Safety

- **Automatic backups** of all modified files in `~/.terminal-setup-backups/`
- **Comprehensive logging** in `~/terminal-setup.log`
- **Non-destructive** - preserves existing configurations when possible

### Cross-Platform Support

- **macOS** with Homebrew
- **Linux** with multiple package manager support
- **Consistent experience** across different operating systems

---

## 📁 What Gets Installed

| Component | Description | Location |
|-----------|-------------|----------|
| **Zsh** | Modern shell with advanced features | System package |
| **Oh My Zsh** | Zsh framework and configuration | `~/.oh-my-zsh/` |
| **Powerlevel10k** | Fast and customizable prompt theme | `~/.oh-my-zsh/custom/themes/` |
| **Zsh Plugins** | Syntax highlighting and autosuggestions | `~/.oh-my-zsh/custom/plugins/` |
| **Hack Nerd Font** | Programming font with icons | `~/Library/Fonts/` (macOS) or `~/.local/share/fonts/` (Linux) |
| **Ruby + rbenv** | Ruby version manager and latest Ruby | `~/.rbenv/` (Linux) or via Homebrew (macOS) |
| **colorls** | Colorful `ls` replacement | Ruby gem |
| **Gruvbox Theme** | Dark color scheme for Terminal.app | Downloads folder (macOS only) |

---

## ✅ Post-Installation Verification

After running the script, verify your installation:

1. **Check the shell**

   ```bash
   echo $SHELL
   # Should show path ending with 'zsh'
   ```

2. **Verify Oh My Zsh**

   ```bash
   ls ~/.oh-my-zsh
   # Should show Oh My Zsh directory structure
   ```

3. **Test plugins**

   ```bash
   ls ~/.oh-my-zsh/custom/plugins
   # Should show 'zsh-syntax-highlighting' and 'zsh-autosuggestions'
   ```

4. **Test colorls**

   ```bash
   ls
   # Should display colorful directory listing
   ```

5. **Check Powerlevel10k**

   ```bash
   echo $ZSH_THEME
   # Should show 'powerlevel10k/powerlevel10k'
   ```

6. **Verify font installation**
   - **macOS**: Check Font Book for "Hack Nerd Font"
   - **Linux**: Run `fc-list | grep -i hack`

---

## 🔧 Configuration

### Powerlevel10k Setup

After installation, configure your prompt:

```bash
p10k configure
```

### Gruvbox Theme (macOS)

1. Open Terminal.app preferences
2. Go to Profiles tab
3. Import the downloaded `Gruvbox-Dark.terminal` file
4. Set as default profile

### Custom Aliases

The script adds these aliases to your `~/.zshrc`:

```bash
alias ls='colorls'      # Colorful ls
alias ll='colorls -l'   # Long format
alias la='colorls -la'  # Long format with hidden files
```

---

## 📝 Logs and Backups

### Installation Log

All installation steps are logged to:

```
~/terminal-setup.log
```

### Configuration Backups

Original configuration files are backed up to:

```
~/.terminal-setup-backups/YYYYMMDD_HHMMSS/
```

### Restore from Backup

To restore a configuration file:

```bash
cp ~/.terminal-setup-backups/YYYYMMDD_HHMMSS/zshrc.backup ~/.zshrc
```

---

## 🐛 Troubleshooting

### Common Issues

**Script fails with "Homebrew required"**

- Install Homebrew: `/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"`

**Ruby installation takes too long**

- This is normal - Ruby compilation can take 10-30 minutes

**Fonts not appearing**

- **macOS**: Restart Terminal.app and check Font preferences
- **Linux**: Run `fc-cache -fv` and restart terminal

**Powerlevel10k not loading**

- Restart terminal or run `source ~/.zshrc`
- Run `p10k configure` to set up the theme

### Getting Help

1. Check the installation log: `cat ~/terminal-setup.log`
2. Verify prerequisites are installed
3. Try running the script again (it's safe to re-run)
4. Open an issue on GitHub with your log file

---

## 🔄 Uninstallation

To remove components installed by this script:

```bash
# Remove Oh My Zsh
uninstall_oh_my_zsh

# Remove rbenv (Linux)
rm -rf ~/.rbenv

# Restore original shell
chsh -s /bin/bash

# Remove colorls gem
gem uninstall colorls

# Restore from backup
cp ~/.terminal-setup-backups/YYYYMMDD_HHMMSS/zshrc.backup ~/.zshrc
```

---

## 🤝 Contributing

Contributions are welcome! Please:

1. Fork the repository
2. Create a feature branch
3. Test your changes on both macOS and Linux
4. Submit a pull request

---

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

---

## 🙏 Acknowledgments

- [Oh My Zsh](https://ohmyz.sh/) - Zsh framework
- [Powerlevel10k](https://github.com/romkatv/powerlevel10k) - Zsh theme
- [Hack Nerd Font](https://github.com/ryanoasis/nerd-fonts) - Programming font
- [colorls](https://github.com/athityakumar/colorls) - Colorful ls replacement
- [Gruvbox](https://github.com/morhetz/gruvbox) - Color scheme
