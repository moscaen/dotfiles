#!/usr/bin/env bash
set -euo pipefail

# Platform detection
case "$(uname -s)" in
  Darwin) IS_MACOS=true ;;
  *)      IS_MACOS=false ;;
esac

echo "==> Detected platform: $(uname -s)"

# ──────────────────────────────────────────────
# Package manager
# ──────────────────────────────────────────────
if $IS_MACOS; then
  if ! command -v brew &>/dev/null; then
    echo "==> Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  fi
  PKG_INSTALL="brew install"
  CASK_INSTALL="brew install --cask"
else
  if command -v brew &>/dev/null; then
    PKG_INSTALL="brew install"
    CASK_INSTALL=""
  elif command -v apt-get &>/dev/null; then
    echo "==> Updating apt..."
    sudo apt-get update -qq
    PKG_INSTALL="sudo apt-get install -y"
    CASK_INSTALL=""
  else
    echo "Error: No supported package manager found (brew or apt)"
    exit 1
  fi
fi

# ──────────────────────────────────────────────
# Helper
# ──────────────────────────────────────────────
install_if_missing() {
  local cmd="$1"
  local pkg="${2:-$1}"

  if command -v "$cmd" &>/dev/null; then
    echo "  [ok] $cmd already installed"
  else
    echo "  [install] $pkg..."
    $PKG_INSTALL "$pkg"
  fi
}

# ──────────────────────────────────────────────
# Shell & prompt
# ──────────────────────────────────────────────
echo ""
echo "==> Shell & prompt"
install_if_missing zsh
install_if_missing starship

# ──────────────────────────────────────────────
# Terminal tools
# ──────────────────────────────────────────────
echo ""
echo "==> Terminal tools"
install_if_missing tmux
install_if_missing fzf
install_if_missing eza
install_if_missing vivid
install_if_missing ranger
install_if_missing bat
install_if_missing tldr

# ──────────────────────────────────────────────
# Search & navigation
# ──────────────────────────────────────────────
echo ""
echo "==> Search & navigation"
install_if_missing rg ripgrep
install_if_missing fd
install_if_missing zoxide

# ──────────────────────────────────────────────
# Editor
# ──────────────────────────────────────────────
echo ""
echo "==> Editor"
install_if_missing nvim neovim
if $IS_MACOS; then
  if ! command -v neovide &>/dev/null; then
    echo "  [install] neovide..."
    $CASK_INSTALL neovide
  else
    echo "  [ok] neovide already installed"
  fi
fi

# ──────────────────────────────────────────────
# Git tools
# ──────────────────────────────────────────────
echo ""
echo "==> Git tools"
install_if_missing lazygit
install_if_missing glab glab

# ──────────────────────────────────────────────
# Python tooling
# ──────────────────────────────────────────────
echo ""
echo "==> Python tooling"
if command -v uv &>/dev/null; then
  echo "  [ok] uv already installed"
else
  echo "  [install] uv..."
  curl -LsSf https://astral.sh/uv/install.sh | sh
fi
install_if_missing marimo

# ──────────────────────────────────────────────
# Data tools
# ──────────────────────────────────────────────
echo ""
echo "==> Data tools"
install_if_missing duckdb
install_if_missing jq
install_if_missing yq

# ──────────────────────────────────────────────
# Kubernetes
# ──────────────────────────────────────────────
echo ""
echo "==> Kubernetes"
install_if_missing k9s
install_if_missing kubectx

# ──────────────────────────────────────────────
# Terminal emulator (macOS only)
# ──────────────────────────────────────────────
if $IS_MACOS; then
  echo ""
  echo "==> Terminal emulator"
  if ! command -v wezterm &>/dev/null; then
    echo "  [install] wezterm..."
    $CASK_INSTALL wezterm
  else
    echo "  [ok] wezterm already installed"
  fi
fi

# ──────────────────────────────────────────────
# Font (Nerd Font for icons)
# ──────────────────────────────────────────────
if $IS_MACOS; then
  echo ""
  echo "==> Font"
  if brew list --cask font-meslo-lg-nerd-font &>/dev/null 2>&1; then
    echo "  [ok] MesloLGS NF already installed"
  else
    echo "  [install] MesloLGS Nerd Font..."
    brew install --cask font-meslo-lg-nerd-font
  fi
fi

# ──────────────────────────────────────────────
# Run dotfiles installer
# ──────────────────────────────────────────────
echo ""
echo "==> Linking dotfiles..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
bash "$SCRIPT_DIR/install.sh"

echo ""
echo "==> Setup complete!"
echo "    Open a new terminal to load the new config."
echo "    Run 'neovide' to install nvim plugins automatically."
