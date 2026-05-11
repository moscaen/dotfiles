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


# ──────────────────────────────────────────────
# Windows Terminal — Catppuccin Macchiato theme
# (WSL only: patches the Windows-side settings.json)
# ──────────────────────────────────────────────
if ! $IS_MACOS && grep -qi microsoft /proc/version 2>/dev/null; then
  echo ""
  echo "==> Patching Windows Terminal with Catppuccin Macchiato..."

  # Locate Windows Terminal settings.json (stable or preview)
  WT_SETTINGS=""
  WIN_USER=$(cmd.exe /c "echo %USERNAME%" 2>/dev/null | tr -d '\r')
  for candidate in \
    "/mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminal_8wekyb3d8bbwe/LocalState/settings.json" \
    "/mnt/c/Users/$WIN_USER/AppData/Local/Packages/Microsoft.WindowsTerminalPreview_8wekyb3d8bbwe/LocalState/settings.json"
  do
    if [ -f "$candidate" ]; then
      WT_SETTINGS="$candidate"
      break
    fi
  done

  if [ -z "$WT_SETTINGS" ]; then
    echo "  [skip] Windows Terminal settings.json not found (is Windows Terminal installed?)"
  elif ! command -v jq &>/dev/null; then
    echo "  [skip] jq not installed — run 'sudo apt-get install -y jq' then re-run install.sh"
  else
    PATCH="$DOTFILES_DIR/config/windows-terminal/catppuccin-macchiato.json"
    SCHEME_NAME=$(jq -r '.scheme.name' "$PATCH")
    THEME_NAME=$(jq -r '.theme.name' "$PATCH")

    # Back up before modifying
    cp "$WT_SETTINGS" "${WT_SETTINGS}.backup"

    # Inject scheme if not already present
    if jq -e --arg n "$SCHEME_NAME" '.schemes[]? | select(.name == $n)' "$WT_SETTINGS" >/dev/null 2>&1; then
      echo "  [ok] scheme '$SCHEME_NAME' already present"
    else
      jq --argjson s "$(jq '.scheme' "$PATCH")" \
        '.schemes = ((.schemes // []) + [$s])' \
        "$WT_SETTINGS" > /tmp/wt_settings.json && mv /tmp/wt_settings.json "$WT_SETTINGS"
      echo "  [added] scheme '$SCHEME_NAME'"
    fi

    # Inject theme if not already present
    if jq -e --arg n "$THEME_NAME" '.themes[]? | select(.name == $n)' "$WT_SETTINGS" >/dev/null 2>&1; then
      echo "  [ok] theme '$THEME_NAME' already present"
    else
      jq --argjson t "$(jq '.theme' "$PATCH")" \
        '.themes = ((.themes // []) + [$t])' \
        "$WT_SETTINGS" > /tmp/wt_settings.json && mv /tmp/wt_settings.json "$WT_SETTINGS"
      echo "  [added] theme '$THEME_NAME'"
    fi

    # Apply to default profile
    jq --arg s "$SCHEME_NAME" --arg t "$THEME_NAME" '
      .profiles.defaults.colorScheme = $s |
      .theme = $t
    ' "$WT_SETTINGS" > /tmp/wt_settings.json && mv /tmp/wt_settings.json "$WT_SETTINGS"
    echo "  [applied] set as default color scheme and theme"
    echo "  [backup]  original saved to ${WT_SETTINGS}.backup"
  fi
fi

echo ""
echo "Done! Create ~/.secrets.zsh for tokens/credentials (not tracked by git)."
