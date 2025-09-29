#!/usr/bin/env bash
set -euo pipefail

# Colors
green() { printf "\033[32m%s\033[0m\n" "$*"; }
yellow() { printf "\033[33m%s\033[0m\n" "$*"; }
red() { printf "\033[31m%s\033[0m\n" "$*"; }

require_cmd() {
  command -v "$1" >/dev/null 2>&1 || { red "Missing required command: $1"; exit 1; }
}

# 0) Pre-checks
require_cmd sudo
if ! id -nG | grep -q "\bsudo\b"; then
  red "Your user is not in sudoers. Add it first: sudo usermod -aG sudo $(whoami) and relogin."
  exit 1
fi

# 1) Base update
yellow "[1/7] Updating apt index..."
sudo apt-get update -y

# 2) Install packages
yellow "[2/7] Installing zsh, htop, jq, vim, git, curl, wget, ca-certificates..."
sudo apt-get install -y zsh htop jq vim git curl wget ca-certificates

# 3) Install bat (handle bat/batcat differences)
yellow "[3/7] Installing bat..."
if ! dpkg -s bat >/dev/null 2>&1; then
  sudo apt-get install -y bat || true
fi

# Some Ubuntu versions name it 'batcat'
if ! command -v bat >/dev/null 2>&1; then
  if command -v batcat >/dev/null 2>&1; then
    # Create an alias for current shell sessions and future shells
    if ! grep -q "alias bat=batcat" "$HOME/.bashrc" 2>/dev/null; then
      echo "alias bat=batcat" >> "$HOME/.bashrc"
    fi
    if ! grep -q "alias bat=batcat" "$HOME/.zshrc" 2>/dev/null; then
      touch "$HOME/.zshrc"
      echo "alias bat=batcat" >> "$HOME/.zshrc"
    fi
    yellow "Mapped bat -> batcat via alias."
  else
    red "Neither bat nor batcat found after installation. You may need: sudo apt-get install -y bat"
  fi
fi

# 4) Install Oh My Zsh (unattended, non-interactive)
yellow "[4/7] Installing Oh My Zsh (unattended)..."
export RUNZSH=no
export CHSH=no
export KEEP_ZSHRC=yes
OMZ_DIR="${ZSH:-$HOME/.oh-my-zsh}"
if [ ! -d "$OMZ_DIR" ]; then
  sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" || {
    red "Oh My Zsh install script failed."
    exit 1
  }
else
  yellow "Oh My Zsh already installed. Skipping."
fi

# 5) Configure .zshrc (backup once, add plugins if not present)
yellow "[5/7] Configuring ~/.zshrc ..."
ZSHRC="$HOME/.zshrc"
if [ ! -f "$ZSHRC.bak.pre-omz" ]; then
  cp -a "$ZSHRC" "$ZSHRC.bak.pre-omz" 2>/dev/null || true
fi
touch "$ZSHRC"

# Ensure ZSH path exported by OMZ
if ! grep -q '^export ZSH=' "$ZSHRC"; then
  echo 'export ZSH="$HOME/.oh-my-zsh"' >> "$ZSHRC"
fi

# Set a sane theme
if grep -q '^ZSH_THEME=' "$ZSHRC"; then
  sed -i 's/^ZSH_THEME=.*/ZSH_THEME="robbyrussell"/' "$ZSHRC"
else
  echo 'ZSH_THEME="robbyrussell"' >> "$ZSHRC"
fi

# Ensure plugins include git, zsh-autosuggestions, zsh-syntax-highlighting
if ! grep -q '^plugins=' "$ZSHRC"; then
  echo 'plugins=(git)' >> "$ZSHRC"
fi

# Install plugins (if missing)
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-autosuggestions" ]; then
  git clone https://github.com/zsh-users/zsh-autosuggestions "$ZSH_CUSTOM/plugins/zsh-autosuggestions"
fi
if [ ! -d "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting" ]; then
  git clone https://github.com/zsh-users/zsh-syntax-highlighting "$ZSH_CUSTOM/plugins/zsh-syntax-highlighting"
fi

# Ensure plugins in zshrc
if grep -q '^plugins=' "$ZSHRC"; then
  if ! grep -q 'zsh-autosuggestions' "$ZSHRC"; then
    sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-autosuggestions)/' "$ZSHRC"
  fi
  if ! grep -q 'zsh-syntax-highlighting' "$ZSHRC"; then
    sed -i 's/^plugins=(\(.*\))/plugins=(\1 zsh-syntax-highlighting)/' "$ZSHRC"
  fi
fi

# 6) Make zsh default shell (WSL-safe)
yellow "[6/7] Setting zsh as default shell..."
ZSH_PATH="$(command -v zsh)"
if [ -n "$ZSH_PATH" ]; then
  if command -v chsh >/dev/null 2>&1; then
    if [ "${SHELL:-}" != "$ZSH_PATH" ]; then
      # In WSL, chsh may require password and a re-login
      chsh -s "$ZSH_PATH" "$USER" || yellow "chsh failed in WSL. Use the WSL method listed in notes below."
    fi
  else
    yellow "chsh not available. Use WSL method listed in notes below."
  fi
else
  red "zsh not found in PATH."
fi

# 7) Summary
green "[7/7] Done."
green "Next steps:"
echo " - Close and reopen your WSL session (or run: exec zsh) to enter zsh."
echo " - If zsh is not default on login, see 'WSL设为默认shell的方法' below."
