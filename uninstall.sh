#!/usr/bin/env bash
# uninstall.sh — remove dotfile symlinks, revert Windows/VS Code configs,
#                and optionally remove installed packages
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

case "$(uname -s)" in
  Darwin) IS_MACOS=true ;;
  *)      IS_MACOS=false ;;
esac

# ──────────────────────────────────────────────
# Confirmation
# ──────────────────────────────────────────────
echo "==> This will:"
echo "    - Remove all dotfile symlinks"
echo "    - Restore any .backup files found alongside them"
echo "    - Revert Windows Terminal and VS Code theme changes (WSL)"
echo ""
read -r -p "Continue? [y/N] " confirm
[[ "$confirm" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }

# ──────────────────────────────────────────────
# Remove symlinks and restore backups
# ──────────────────────────────────────────────
echo ""
echo "==> Removing symlinks..."

files=(
  ".zshrc"
  ".gitconfig"
  ".tmux.conf"
  ".wezterm.lua"
  ".vimrc"
  ".config/starship.toml"
  ".config/glab-cli/aliases.yml"
  ".config/nvim"
)

if $IS_MACOS; then
  files+=(
    "Library/Application Support/k9s/config.yaml"
    "Library/Application Support/k9s/aliases.yaml"
    "Library/Application Support/k9s/skins"
  )
else
  files+=(
    ".config/k9s/config.yaml"
    ".config/k9s/aliases.yaml"
    ".config/k9s/skins"
  )
fi

for rel in "${files[@]}"; do
  target="$HOME/$rel"
  if [ -L "$target" ]; then
    rm "$target"
    echo "  [removed] $target"
    if [ -e "${target}.backup" ]; then
      mv "${target}.backup" "$target"
      echo "  [restored] ${target}.backup"
    fi
  elif [ -e "$target" ]; then
    echo "  [skip] $target (not a symlink, leaving untouched)"
  else
    echo "  [skip] $target (not found)"
  fi
done

# ──────────────────────────────────────────────
# Revert Windows Terminal (WSL only)
# ──────────────────────────────────────────────
if ! $IS_MACOS && grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo "==> Reverting Windows Terminal..."
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  WT_SETTINGS=""
  for candidate in \
    "/mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" \
    "/mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json"
  do
    [ -f "$candidate" ] && WT_SETTINGS="$candidate" && break
  done

  if [ -z "$WT_SETTINGS" ]; then
    echo "  [skip] settings.json not found"
  elif [ -f "${WT_SETTINGS}.backup" ]; then
    cp "${WT_SETTINGS}.backup" "$WT_SETTINGS"
    echo "  [restored] from ${WT_SETTINGS}.backup"
  elif command -v jq &>/dev/null; then
    jq '
      .schemes = [.schemes[]? | select(.name != "Catppuccin Macchiato")] |
      .themes  = [.themes[]?  | select(.name != "Catppuccin Macchiato")] |
      if .profiles.defaults.colorScheme == "Catppuccin Macchiato"
        then del(.profiles.defaults.colorScheme) else . end |
      if .theme == "Catppuccin Macchiato"
        then del(.theme) else . end
    ' "$WT_SETTINGS" > /tmp/wt_settings.json && mv /tmp/wt_settings.json "$WT_SETTINGS"
    echo "  [removed] Catppuccin scheme and theme entries"
  else
    echo "  [skip] no backup found and jq unavailable — revert manually"
  fi
fi

# ──────────────────────────────────────────────
# Revert VS Code (WSL only)
# ──────────────────────────────────────────────
if ! $IS_MACOS && grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo "==> Reverting VS Code..."
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  VSCODE_SETTINGS="/mnt/c/Users/$WIN_USER/AppData/Roaming/Code/User/settings.json"

  if [ ! -f "$VSCODE_SETTINGS" ]; then
    echo "  [skip] settings.json not found"
  elif [ -f "${VSCODE_SETTINGS}.backup" ]; then
    cp "${VSCODE_SETTINGS}.backup" "$VSCODE_SETTINGS"
    echo "  [restored] from ${VSCODE_SETTINGS}.backup"
  elif command -v jq &>/dev/null; then
    jq 'del(
      .["workbench.colorTheme"],
      .["workbench.iconTheme"],
      .["catppuccin.accentColor"]
    )' "$VSCODE_SETTINGS" > /tmp/vscode_settings.json \
      && mv /tmp/vscode_settings.json "$VSCODE_SETTINGS"
    echo "  [removed] Catppuccin theme settings"
  else
    echo "  [skip] no backup found and jq unavailable — revert manually"
  fi
fi

# ──────────────────────────────────────────────
# Optionally remove installed packages
# ──────────────────────────────────────────────
echo ""
read -r -p "Also remove installed packages? (zsh, nvim, lazygit, eza, etc.) [y/N] " remove_pkgs
if [[ "$remove_pkgs" =~ ^[Yy]$ ]]; then
  echo ""
  echo "==> Removing packages..."

  # apt packages
  if command -v apt-get &>/dev/null; then
    sudo apt-get remove -y \
      zsh tmux fzf ripgrep fd-find bat ranger tldr zoxide jq neovim 2>/dev/null || true
    sudo apt-get remove -y eza 2>/dev/null || true
    sudo apt-get autoremove -y
    sudo rm -f /etc/apt/sources.list.d/gierens.list \
               /etc/apt/keyrings/gierens.gpg
    echo "  [removed] apt packages and eza repo"
  fi

  # GitHub release binaries
  for bin in starship lazygit vivid duckdb yq k9s kubectx kubens glab fd; do
    if [ -f "/usr/local/bin/$bin" ]; then
      sudo rm -f "/usr/local/bin/$bin"
      echo "  [removed] /usr/local/bin/$bin"
    fi
  done

  # uv / uvx
  if [ -f "$HOME/.local/bin/uv" ]; then
    rm -f "$HOME/.local/bin/uv" "$HOME/.local/bin/uvx"
    echo "  [removed] uv / uvx"
  fi

  # marimo
  if command -v uv &>/dev/null; then
    uv tool uninstall marimo 2>/dev/null && echo "  [removed] marimo" || true
  fi

  echo ""
  echo "  [done] packages removed"
else
  echo "  [skip] packages left in place"
fi

echo ""
echo "==> Uninstall complete."
echo "    Open a new terminal or switch back to bash with: exec bash"