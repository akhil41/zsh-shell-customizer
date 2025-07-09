# zsh-shell-customizer

> Seamlessly synchronize your terminal experience across macOS and Linux.
> Includes Zsh shell, Gruvbox Dark theme, Nerd Fonts, Powerlevel10k, plugins, and more.

---

## ⚙️ What This Script Does

This setup script customizes your terminal environment consistently across **macOS and Linux** by:

1. Ensuring Zsh is the default shell
2. Optionally showing instructions for the **Gruvbox Dark** terminal theme
3. Installing and configuring **Oh My Zsh**
4. Installing **Hack Nerd Font**
5. Installing **Powerlevel10k** theme
6. Installing essential Zsh plugins:
   - `zsh-syntax-highlighting`
   - `zsh-autosuggestions`
7. Installing `colorls` in a Ruby environment
8. Adding aliases for `colorls`
9. Providing interactive prompts for safe installation

---

## 🚀 Quick Start

```bash
bash -c "$(curl -fsSL https://raw.githubusercontent.com/yourusername/zsh-shell-customizer/main/install.sh)"
```

---

## ✅ Manual Tests

After running the script:

1. **Check the shell**

   ```bash
   echo $SHELL
   ```

   Ensure the output path ends with `zsh`.

2. **Gruvbox instructions**
   If you opted in, apply the Gruvbox Dark color scheme in your terminal settings.

3. **Plugin directories**

   ```bash
   ls ~/.oh-my-zsh/custom/plugins
   ```

   Verify `zsh-syntax-highlighting` and `zsh-autosuggestions` exist.

4. **Run colorls**

   ```bash
   cls
   ```

   The command should display a colorful directory listing.

5. **Font and Powerlevel10k**
   Start a new terminal session and confirm the Hack Nerd Font is selectable and that Powerlevel10k loads without errors.
