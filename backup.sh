#!/usr/bin/env bash
# backup.sh — snapshot dotfiles, Windows Terminal, and VS Code settings
# Creates a timestamped archive at ~/dotfiles-backup-<date>.tar.gz
set -euo pipefail

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
BACKUP_DIR="$HOME/dotfiles-backup-$TIMESTAMP"
mkdir -p "$BACKUP_DIR"

case "$(uname -s)" in
  Darwin) IS_MACOS=true ;;
  *)      IS_MACOS=false ;;
esac

echo "==> Backing up to $BACKUP_DIR"

# ──────────────────────────────────────────────
# Dotfiles (resolve symlinks to real content)
# ──────────────────────────────────────────────
echo ""
echo "==> Dotfiles"

dotfiles=(
  "$HOME/.zshrc"
  "$HOME/.gitconfig"
  "$HOME/.tmux.conf"
  "$HOME/.vimrc"
  "$HOME/.config/starship.toml"
  "$HOME/.config/glab-cli/aliases.yml"
  "$HOME/.config/nvim"
  "$HOME/.config/k9s"
)

if $IS_MACOS; then
  dotfiles+=(
    "$HOME/.wezterm.lua"
    "$HOME/Library/Application Support/k9s"
  )
fi

for f in "${dotfiles[@]}"; do
  if [ -e "$f" ] || [ -L "$f" ]; then
    rel="${f#$HOME/}"
    dest="$BACKUP_DIR/home/$rel"
    mkdir -p "$(dirname "$dest")"
    cp -rL "$f" "$dest" 2>/dev/null \
      && echo "  [ok] $f" \
      || echo "  [skip] $f (unreadable)"
  else
    echo "  [skip] $f (not found)"
  fi
done

# ──────────────────────────────────────────────
# Windows Terminal (WSL only)
# ──────────────────────────────────────────────
if ! $IS_MACOS && grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo "==> Windows Terminal"
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  for candidate in \
    "/mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" \
    "/mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json"
  do
    if [ -f "$candidate" ]; then
      label=$(echo "$candidate" | grep -oP 'Microsoft\.WindowsTerminal[^/]*')
      dest="$BACKUP_DIR/windows-terminal/$label-settings.json"
      mkdir -p "$(dirname "$dest")"
      cp "$candidate" "$dest"
      echo "  [ok] $candidate"
    fi
  done
fi

# ──────────────────────────────────────────────
# VS Code (WSL)
# ──────────────────────────────────────────────
if ! $IS_MACOS && grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo "==> VS Code"
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  for f in \
    "/mnt/c/Users/$WIN_USER/AppData/Roaming/Code/User/settings.json" \
    "/mnt/c/Users/$WIN_USER/AppData/Roaming/Code/User/keybindings.json"
  do
    if [ -f "$f" ]; then
      dest="$BACKUP_DIR/vscode/$(basename "$f")"
      mkdir -p "$(dirname "$dest")"
      cp "$f" "$dest"
      echo "  [ok] $f"
    else
      echo "  [skip] $f (not found)"
    fi
  done
fi

# ──────────────────────────────────────────────
# VS Code (macOS)
# ──────────────────────────────────────────────
if $IS_MACOS; then
  echo ""
  echo "==> VS Code"
  for f in \
    "$HOME/Library/Application Support/Code/User/settings.json" \
    "$HOME/Library/Application Support/Code/User/keybindings.json"
  do
    if [ -f "$f" ]; then
      dest="$BACKUP_DIR/vscode/$(basename "$f")"
      mkdir -p "$(dirname "$dest")"
      cp "$f" "$dest"
      echo "  [ok] $f"
    else
      echo "  [skip] $f (not found)"
    fi
  done
fi

# ──────────────────────────────────────────────
# Archive
# ──────────────────────────────────────────────
echo ""
echo "==> Compressing..."
tar -czf "$HOME/dotfiles-backup-$TIMESTAMP.tar.gz" -C "$HOME" "dotfiles-backup-$TIMESTAMP"
rm -rf "$BACKUP_DIR"

echo ""
echo "==> Done! Saved to: ~/dotfiles-backup-$TIMESTAMP.tar.gz"
echo "    To inspect: tar -tzf ~/dotfiles-backup-$TIMESTAMP.tar.gz"
echo "    To restore: tar -xzf ~/dotfiles-backup-$TIMESTAMP.tar.gz"
