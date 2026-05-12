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
# starship is not in apt — use the official installer
if command -v starship &>/dev/null; then
  echo "  [ok] starship already installed"
else
  echo "  [install] starship..."
  curl -sS https://starship.rs/install.sh | sh -s -- --yes
fi

# ──────────────────────────────────────────────
# Terminal tools
# ──────────────────────────────────────────────
echo ""
echo "==> Terminal tools"
install_if_missing tmux
# fzf: apt ships an old version; install from GitHub to get --zsh support (0.48+)
if command -v fzf &>/dev/null && fzf --zsh &>/dev/null 2>&1; then
  echo "  [ok] fzf already installed (supports --zsh)"
else
  echo "  [install] fzf (latest)..."
  FZF_VERSION=$(curl -s https://api.github.com/repos/junegunn/fzf/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
  if $IS_MACOS; then
    $PKG_INSTALL fzf
  else
    curl -Lo /tmp/fzf.tar.gz \
      "https://github.com/junegunn/fzf/releases/download/v${FZF_VERSION}/fzf-${FZF_VERSION}-linux_amd64.tar.gz"
    sudo tar -xzf /tmp/fzf.tar.gz -C /usr/local/bin fzf
    rm -f /tmp/fzf.tar.gz
  fi
fi
# eza is not in standard apt — add the official eza apt repo
if command -v eza &>/dev/null; then
  echo "  [ok] eza already installed"
else
  echo "  [install] eza..."
  sudo mkdir -p /etc/apt/keyrings
  wget -qO- https://raw.githubusercontent.com/eza-community/eza/main/deb.asc \
    | sudo gpg --dearmor -o /etc/apt/keyrings/gierens.gpg
  echo "deb [signed-by=/etc/apt/keyrings/gierens.gpg] http://deb.gierens.de stable main" \
    | sudo tee /etc/apt/sources.list.d/gierens.list > /dev/null
  sudo chmod 644 /etc/apt/keyrings/gierens.gpg /etc/apt/sources.list.d/gierens.list
  sudo apt-get update -qq
  sudo apt-get install -y eza
fi

# vivid is not in standard apt — install GitHub release (sharkdp/vivid)
if command -v vivid &>/dev/null; then
  echo "  [ok] vivid already installed"
else
  echo "  [install] vivid..."
  VIVID_VERSION=$(curl -s https://api.github.com/repos/sharkdp/vivid/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
  curl -Lo /tmp/vivid.tar.gz \
    "https://github.com/sharkdp/vivid/releases/download/v${VIVID_VERSION}/vivid-v${VIVID_VERSION}-x86_64-unknown-linux-musl.tar.gz"
  tar -xzf /tmp/vivid.tar.gz -C /tmp
  sudo install "/tmp/vivid-v${VIVID_VERSION}-x86_64-unknown-linux-musl/vivid" /usr/local/bin/vivid
  rm -rf /tmp/vivid.tar.gz "/tmp/vivid-v${VIVID_VERSION}-x86_64-unknown-linux-musl"
fi
install_if_missing ranger
# bat is not in standard apt — install .deb from GitHub releases (sharkdp/bat)
if command -v bat &>/dev/null; then
  echo "  [ok] bat already installed"
else
  echo "  [install] bat..."
  BAT_VERSION=$(curl -s https://api.github.com/repos/sharkdp/bat/releases/latest     | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
  curl -Lo /tmp/bat.deb     "https://github.com/sharkdp/bat/releases/download/v${BAT_VERSION}/bat_${BAT_VERSION}_amd64.deb"
  sudo dpkg -i /tmp/bat.deb
  rm -f /tmp/bat.deb
fi
install_if_missing tldr

# ──────────────────────────────────────────────
# Search & navigation
# ──────────────────────────────────────────────
echo ""
echo "==> Search & navigation"
install_if_missing rg ripgrep
# fd is packaged as 'fd-find' on Debian/Ubuntu; symlink to 'fd'
if command -v fd &>/dev/null; then
  echo "  [ok] fd already installed"
elif $IS_MACOS; then
  $PKG_INSTALL fd
else
  echo "  [install] fd-find..."
  sudo apt-get install -y fd-find
  sudo ln -sf "$(which fdfind)" /usr/local/bin/fd
fi
install_if_missing zoxide

# ──────────────────────────────────────────────
# Editor
# ──────────────────────────────────────────────
echo ""
echo "==> Editor"

# vim-plug
if [ -f "$HOME/.vim/autoload/plug.vim" ]; then
  echo "  [ok] vim-plug already installed"
else
  echo "  [install] vim-plug..."
  curl -fLo "$HOME/.vim/autoload/plug.vim" --create-dirs \
    https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
fi

if command -v nvim &>/dev/null; then
  echo "  [ok] nvim already installed"
elif $IS_MACOS; then
  $PKG_INSTALL neovim
else
  # apt ships 0.6 on Ubuntu 22.04 — install latest from GitHub tarball
  echo "  [install] nvim (latest stable)..."
  NVIM_VERSION=$(curl -s https://api.github.com/repos/neovim/neovim/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  curl -Lo /tmp/nvim.tar.gz \
    "https://github.com/neovim/neovim/releases/download/${NVIM_VERSION}/nvim-linux-x86_64.tar.gz"
  sudo tar -xzf /tmp/nvim.tar.gz -C /opt/
  sudo ln -sf /opt/nvim-linux-x86_64/bin/nvim /usr/local/bin/nvim
  rm -f /tmp/nvim.tar.gz
fi

# neovide
if $IS_MACOS; then
  if ! command -v neovide &>/dev/null; then
    echo "  [install] neovide..."
    $CASK_INSTALL neovide
  else
    echo "  [ok] neovide already installed"
  fi
elif grep -qi microsoft /proc/version 2>/dev/null; then
  # install following https://neovide.dev/installation.html
  # WSL: neovide is a Windows GUI app — install it on the Windows side.
  # Download from: https://github.com/neovide/neovide/releases/latest
  # Then add it to your Windows PATH so it can be launched from WSL.
  if command -v neovide.exe &>/dev/null; then
    echo "  [ok] neovide already accessible from WSL"
  else
    echo "  [info] neovide: install the Windows .msi from https://github.com/neovide/neovide/releases"
    echo "         then ensure neovide.exe is on your Windows PATH"
  fi
else
  # Native Linux: install neovide AppImage
  if command -v neovide &>/dev/null; then
    echo "  [ok] neovide already installed"
  else
    echo "  [install] neovide..."
    NEOVIDE_VERSION=$(curl -s https://api.github.com/repos/neovide/neovide/releases/latest       | grep '"tag_name"' | cut -d'"' -f4)
    curl -Lo /tmp/neovide.tar.gz       "https://github.com/neovide/neovide/releases/download/${NEOVIDE_VERSION}/neovide-linux-x86_64.tar.gz"
    sudo tar -xzf /tmp/neovide.tar.gz -C /usr/local/bin/
    rm -f /tmp/neovide.tar.gz
  fi
fi

# ──────────────────────────────────────────────
# Git tools
# ──────────────────────────────────────────────
echo ""
echo "==> Git tools"
# lazygit is not in apt — install via GitHub release
if command -v lazygit &>/dev/null; then
  echo "  [ok] lazygit already installed"
else
  echo "  [install] lazygit..."
  LAZYGIT_VERSION=$(curl -s https://api.github.com/repos/jesseduffield/lazygit/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4 | sed 's/v//')
  curl -Lo /tmp/lazygit.tar.gz \
    "https://github.com/jesseduffield/lazygit/releases/download/v${LAZYGIT_VERSION}/lazygit_${LAZYGIT_VERSION}_Linux_x86_64.tar.gz"
  tar -xzf /tmp/lazygit.tar.gz -C /tmp lazygit
  sudo install /tmp/lazygit /usr/local/bin/lazygit
  rm /tmp/lazygit.tar.gz /tmp/lazygit
fi


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
# marimo is a Python package — install via uv (already installed above) or pip
if command -v marimo &>/dev/null; then
  echo "  [ok] marimo already installed"
else
  echo "  [install] marimo..."
  if command -v uv &>/dev/null; then
    uv tool install marimo
  else
    pip install --user marimo
  fi
fi

# ──────────────────────────────────────────────
# Data tools
# ──────────────────────────────────────────────
echo ""
echo "==> Data tools"
# duckdb is not in apt — install the CLI binary from GitHub
if command -v duckdb &>/dev/null; then
  echo "  [ok] duckdb already installed"
else
  echo "  [install] duckdb..."
  DUCKDB_VERSION=$(curl -s https://api.github.com/repos/duckdb/duckdb/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  curl -Lo /tmp/duckdb.zip \
    "https://github.com/duckdb/duckdb/releases/download/${DUCKDB_VERSION}/duckdb_cli-linux-amd64.zip"
  unzip -o /tmp/duckdb.zip -d /tmp duckdb
  sudo install /tmp/duckdb /usr/local/bin/duckdb
  rm -f /tmp/duckdb.zip /tmp/duckdb
fi
install_if_missing jq
# yq is not in standard apt — install GitHub release (mikefarah/yq)
if command -v yq &>/dev/null; then
  echo "  [ok] yq already installed"
else
  echo "  [install] yq..."
  YQ_VERSION=$(curl -s https://api.github.com/repos/mikefarah/yq/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  sudo wget -qO /usr/local/bin/yq \
    "https://github.com/mikefarah/yq/releases/download/${YQ_VERSION}/yq_linux_amd64"
  sudo chmod +x /usr/local/bin/yq
fi

# ──────────────────────────────────────────────
# Kubernetes
# ──────────────────────────────────────────────
echo ""
echo "==> Kubernetes"
# k9s is not in apt — install via GitHub release
if command -v k9s &>/dev/null; then
  echo "  [ok] k9s already installed"
else
  echo "  [install] k9s..."
  K9S_VERSION=$(curl -s https://api.github.com/repos/derailed/k9s/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  curl -Lo /tmp/k9s.tar.gz \
    "https://github.com/derailed/k9s/releases/download/${K9S_VERSION}/k9s_Linux_amd64.tar.gz"
  tar -xzf /tmp/k9s.tar.gz -C /tmp k9s
  sudo install /tmp/k9s /usr/local/bin/k9s
  rm -f /tmp/k9s.tar.gz /tmp/k9s
fi
# kubectx (and kubens) are not in apt — install from GitHub
if command -v kubectx &>/dev/null; then
  echo "  [ok] kubectx already installed"
else
  echo "  [install] kubectx + kubens..."
  KUBECTX_VERSION=$(curl -s https://api.github.com/repos/ahmetb/kubectx/releases/latest \
    | grep '"tag_name"' | cut -d'"' -f4)
  curl -Lo /tmp/kubectx.tar.gz \
    "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubectx_${KUBECTX_VERSION}_linux_x86_64.tar.gz"
  tar -xzf /tmp/kubectx.tar.gz -C /tmp kubectx
  sudo install /tmp/kubectx /usr/local/bin/kubectx
  curl -Lo /tmp/kubens.tar.gz \
    "https://github.com/ahmetb/kubectx/releases/download/${KUBECTX_VERSION}/kubens_${KUBECTX_VERSION}_linux_x86_64.tar.gz"
  tar -xzf /tmp/kubens.tar.gz -C /tmp kubens
  sudo install /tmp/kubens /usr/local/bin/kubens
  rm -f /tmp/kubectx* /tmp/kubens*
fi

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
echo ""
echo "==> Font"
if $IS_MACOS; then
  if brew list --cask font-meslo-lg-nerd-font &>/dev/null 2>&1; then
    echo "  [ok] MesloLGS NF already installed"
  else
    echo "  [install] MesloLGS Nerd Font..."
    brew install --cask font-meslo-lg-nerd-font
  fi
else
  # Linux/WSL: install monospace font with variants and MesloLGS NF
  install_if_missing curl
  install_if_missing fc-cache fontconfig
  if command -v apt-get &>/dev/null; then
    $PKG_INSTALL fonts-liberation2
    $PKG_INSTALL fonts-dejavu-core
  fi

  FONT_DIR="/usr/local/share/fonts/meslo-lg-nerd-font"
  sudo mkdir -p "$FONT_DIR"

  declare -a meslo_fonts=(
    "MesloLGS NF Regular.ttf"
    "MesloLGS NF Bold.ttf"
    "MesloLGS NF Italic.ttf"
    "MesloLGS NF Bold Italic.ttf"
  )
  declare -a meslo_urls=(
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Regular.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Italic.ttf"
    "https://github.com/romkatv/powerlevel10k-media/raw/master/MesloLGS%20NF%20Bold%20Italic.ttf"
  )

  for i in "${!meslo_fonts[@]}"; do
    font_file="$FONT_DIR/${meslo_fonts[i]}"
    if [ -f "$font_file" ]; then
      echo "  [ok] ${meslo_fonts[i]} already installed"
    else
      echo "  [install] ${meslo_fonts[i]}..."
      sudo curl -fsSL -o "$font_file" "${meslo_urls[i]}"
    fi
  done

  sudo fc-cache -fv &>/dev/null || true
  echo "  [ok] MesloLGS NF fonts configured"
fi

# ──────────────────────────────────────────────
# VS Code extensions
# ──────────────────────────────────────────────
echo ""
echo "==> VS Code extensions"
if command -v code &>/dev/null; then
  install_vscode_ext() {
    local ext="$1"
    if code --list-extensions 2>/dev/null | grep -qi "^${ext}$"; then
      echo "  [ok] $ext already installed"
    else
      echo "  [install] $ext..."
      code --install-extension "$ext" --force
    fi
  }
  install_vscode_ext "catppuccin.catppuccin-vsc"
  install_vscode_ext "catppuccin.catppuccin-vsc-icons"
else
  echo "  [skip] 'code' not in PATH — extensions will be applied by install.sh when VS Code is available"
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