#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

# Platform detection
case "$(uname -s)" in
  Darwin) IS_MACOS=true ;;
  *)      IS_MACOS=false ;;
esac

# Symlink mappings: source (relative to dotfiles) -> target (relative to $HOME)
files=(
  "zshrc:.zshrc"
  "gitconfig:.gitconfig"
  "tmux.conf:.tmux.conf"
  "wezterm.lua:.wezterm.lua"
  "vimrc:.vimrc"
  "config/starship.toml:.config/starship.toml"
  "config/glab-cli/aliases.yml:.config/glab-cli/aliases.yml"
  "config/nvim:.config/nvim"
)

# k9s: macOS uses ~/Library/Application Support, Linux uses ~/.config
if $IS_MACOS; then
  files+=(
    "config/k9s/config.yaml:Library/Application Support/k9s/config.yaml"
    "config/k9s/aliases.yaml:Library/Application Support/k9s/aliases.yaml"
    "config/k9s/skins:Library/Application Support/k9s/skins"
  )
else
  files+=(
    "config/k9s/config.yaml:.config/k9s/config.yaml"
    "config/k9s/aliases.yaml:.config/k9s/aliases.yaml"
    "config/k9s/skins:.config/k9s/skins"
  )
fi

for entry in "${files[@]}"; do
  src="${entry%%:*}"
  dest="${entry##*:}"
  target="$HOME/$dest"

  mkdir -p "$(dirname "$target")"

  if [ -L "$target" ]; then
    echo "Removing existing symlink: $target"
    rm "$target"
  elif [ -e "$target" ]; then
    echo "Backing up $target -> ${target}.backup"
    mv "$target" "${target}.backup"
  fi

  ln -s "$DOTFILES_DIR/$src" "$target"
  echo "Linked $target -> $DOTFILES_DIR/$src"
done

# Initialize submodules if needed
if [ -f "$DOTFILES_DIR/.gitmodules" ]; then
  echo ""
  echo "Initializing zsh plugin submodules..."
  git -C "$DOTFILES_DIR" submodule update --init --recursive
fi

echo ""
echo "Done! Create ~/.secrets.zsh for tokens/credentials (not tracked by git)."
