# ──────────────────────────────────────────────
# Zsh config — no oh-my-zsh, starship prompt
# ──────────────────────────────────────────────

# Platform detection
case "$(uname -s)" in
  Darwin) IS_MACOS=true ;;
  *)      IS_MACOS=false ;;
esac

# History
HISTFILE=~/.zsh_history
HISTSIZE=10000
SAVEHIST=10000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# Key bindings — emacs mode
bindkey -e

# Completion system
autoload -Uz compinit
compinit -u 2>/dev/null

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-z}={A-Z}'

# ──────────────────────────────────────────────
# Editor
# ──────────────────────────────────────────────
if [[ -n $SSH_CONNECTION ]]; then
  export EDITOR='vim'
elif $IS_MACOS && command -v neovide &>/dev/null; then
  export EDITOR='neovide'
else
  export EDITOR='nvim'
fi

# WSL: neovide runs as a Windows GUI app
if ! $IS_MACOS && grep -qi microsoft /proc/version 2>/dev/null; then
  alias neovide='neovide.exe --wsl'
fi

# ──────────────────────────────────────────────
# PATH
# ──────────────────────────────────────────────
export PATH="$HOME/.duckdb/cli/latest:$PATH"
if $IS_MACOS; then
  export PATH="$PATH:/Applications/Visual Studio Code.app/Contents/Resources/app/bin"
fi
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
# Ensure /usr/local/bin is prioritised (needed on WSL)
if [[ ":$PATH:" != *":/usr/local/bin:"* ]]; then
  export PATH="/usr/local/bin:$PATH"
fi

# ──────────────────────────────────────────────
# Tool completions (replaces oh-my-zsh plugins)
# ──────────────────────────────────────────────
# kubectl
if command -v kubectl &>/dev/null; then
  source <(kubectl completion zsh)
  alias k="kubectl"
fi

# docker — guard against Docker Desktop WSL error output being sourced
if command -v docker &>/dev/null; then
  _dc=$(docker completion zsh 2>/dev/null) \
    && [[ "$_dc" == *"compdef"* || "$_dc" == *"function"* ]] \
    && eval "$_dc" \
    || true
  unset _dc
fi

# GCP
if command -v brew &>/dev/null; then
  source "$(brew --prefix)/share/google-cloud-sdk/path.zsh.inc"
  source "$(brew --prefix)/share/google-cloud-sdk/completion.zsh.inc"
elif [ -f /usr/share/google-cloud-sdk/path.zsh.inc ]; then
  source /usr/share/google-cloud-sdk/path.zsh.inc
  source /usr/share/google-cloud-sdk/completion.zsh.inc
elif [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then
  source "$HOME/google-cloud-sdk/path.zsh.inc"
  source "$HOME/google-cloud-sdk/completion.zsh.inc"
fi

# uv / uvx
if command -v uv &>/dev/null; then
  eval "$(uv generate-shell-completion zsh)"
  eval "$(uvx --generate-shell-completion zsh)"
fi

# fzf
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
if command -v fzf &>/dev/null && fzf --zsh &>/dev/null 2>&1; then
  source <(fzf --zsh)
fi

# jenv
if command -v jenv &>/dev/null; then
  eval "$(jenv init -)"
fi

# nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"

# ──────────────────────────────────────────────
# Aliases
# ──────────────────────────────────────────────
# docker
alias docker_stop_all='docker stop $(docker ps -aq)'
alias docker_remove_all_containers='docker rm -vf $(docker ps -aq)'
alias docker_remove_all_images='docker rmi -f $(docker images -aq)'

# eza (ls replacement)
if command -v vivid &>/dev/null; then
  export LS_COLORS="$(vivid generate catppuccin-macchiato)"
fi
if command -v eza &>/dev/null; then
  alias ls="eza --icons"
  alias ll="ls -l"
  alias la="ls -a"
fi

# lazygit
if $IS_MACOS; then
  LG_CONFIG_FILE="$HOME/Library/Application Support/lazygit/config.yml,$HOME/lazygit/themes-mergable/macchiato/blue.yml"
else
  LG_CONFIG_FILE="$HOME/.config/lazygit/config.yml,$HOME/lazygit/themes-mergable/macchiato/blue.yml"
fi

# bat (cat replacement)
if command -v bat &>/dev/null; then
  alias cat="bat"
  export BAT_THEME="Catppuccin Macchiato"
fi

# dbt
alias dbtf="$HOME/.local/bin/dbt"


# ──────────────────────────────────────────────
# Environment
# ──────────────────────────────────────────────
export NVIM_THEME="catppuccin-macchiato"

# ──────────────────────────────────────────────
# Secrets (not tracked in git)
# Set GOOGLE_CLOUD_PROJECT and other credentials in ~/.secrets.zsh
# ──────────────────────────────────────────────
[ -f ~/.secrets.zsh ] && source ~/.secrets.zsh

[ -f "$HOME/.local/bin/env" ] && . "$HOME/.local/bin/env"

# ──────────────────────────────────────────────
# Catppuccin Macchiato — fzf colors
# ──────────────────────────────────────────────
export FZF_DEFAULT_OPTS=" \
--color=bg+:#363A4F,bg:#24273A,spinner:#F4DBD6,hl:#ED8796 \
--color=fg:#CAD3F5,header:#ED8796,info:#C6A0F6,pointer:#F4DBD6 \
--color=marker:#B7BDF8,fg+:#CAD3F5,prompt:#C6A0F6,hl+:#ED8796 \
--color=selected-bg:#494D64 \
--color=border:#6E738D,label:#CAD3F5"

# ──────────────────────────────────────────────
# Zsh plugins (from dotfiles submodules)
# ──────────────────────────────────────────────
DOTFILES_DIR="$HOME/repos/dotfiles"

source "$DOTFILES_DIR/zsh/catppuccin_macchiato-zsh-syntax-highlighting.zsh"
source "$DOTFILES_DIR/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
source "$DOTFILES_DIR/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ──────────────────────────────────────────────
# zoxide (smarter cd)
# ──────────────────────────────────────────────
if command -v zoxide &>/dev/null; then
  eval "$(zoxide init zsh)"
fi

# ──────────────────────────────────────────────
# Prompt — Starship
# ──────────────────────────────────────────────
eval "$(starship init zsh)"
