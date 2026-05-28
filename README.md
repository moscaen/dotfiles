# dotfiles

Personal development environment configuration. Catppuccin Macchiato theme everywhere. Works on macOS and WSL.

## Prerequisites — SSH access to GitHub

You need GitHub SSH access before you can clone this repo.

**Option A — generate an SSH key manually**

```bash
ssh-keygen -t ed25519 -C "your@email.com"
cat ~/.ssh/id_ed25519.pub   # copy this
```

Paste the key at **github.com → Settings → SSH and GPG keys → New SSH key**, then clone.

**Option B — clone via HTTPS (public repo), set up SSH after**

```bash
git clone https://github.com/<you>/dotfiles.git ~/repos/dotfiles
```

After `setup.sh` finishes, authenticate with `gh` and switch to SSH:

```bash
gh auth login        # follow prompts, choose SSH
git -C ~/repos/dotfiles remote set-url origin git@github.com:<you>/dotfiles.git
```

## Quick start

```bash
git clone --recursive git@github.com:<you>/dotfiles.git ~/repos/dotfiles
cd ~/repos/dotfiles

# Install all tools + link configs
./setup.sh

# Or just link configs (tools already installed)
./install.sh
```

`install.sh` backs up existing files to `*.backup` before symlinking.

## What's included

### Shell

- **zshrc** -- Starship prompt, no oh-my-zsh. Completions for kubectl, docker, gcloud, uv, fzf. Platform-aware (macOS/WSL).
- **starship.toml** -- Catppuccin Macchiato prompt with all 4 palette variants.
- **zsh plugins** -- zsh-autosuggestions and zsh-syntax-highlighting as git submodules, Catppuccin syntax theme.

### Editor

- **nvim** (LazyVim) -- Python-focused setup: debugpy, Ruff, Pyright, LazyGit, multi-cursor (`Ctrl+N`), supertab. Extras for Docker, SQL, JSON, Markdown, TOML, Git.
- **vimrc** -- Minimal vim-plug with Catppuccin.

### Terminal

- **wezterm** -- Catppuccin Macchiato, MesloLGS Nerd Font, cross-platform font sizing.
- **tmux** -- Catppuccin Macchiato with CPU, battery, session, and date/time in status bar.

### Tools

- **k9s** -- Catppuccin Macchiato skin, custom aliases (dp, sec, jo, cr, etc.).
- **lazygit** -- Catppuccin Macchiato theme (referenced from config).
- **glab** -- GitLab CLI aliases (`ci` for pipeline, `co` for MR checkout).
- **gitconfig** -- Fetch prune enabled.

## Neovim keybindings

### Navigation

| Shortcut   | Action                        |
| ---------- | ----------------------------- |
| `Space`    | Show all commands (which-key) |
| `Space ff` | Find file by name             |
| `Space sg` | Grep across project           |
| `Space fb` | Open buffers                  |
| `Space e`  | File explorer                 |
| `H` / `L`  | Previous / next buffer        |
| `gd`       | Go to definition              |
| `gr`       | Find references               |
| `Ctrl+o`   | Jump back                     |

### Editing

| Shortcut      | Action                               |
| ------------- | ------------------------------------ |
| `Ctrl+N`      | Multi-cursor: select next occurrence |
| `Ctrl+X`      | Multi-cursor: skip current           |
| `gcc`         | Toggle comment line                  |
| `gc` (visual) | Toggle comment selection             |

### Python debugging

| Shortcut    | Action                 |
| ----------- | ---------------------- |
| `Space db`  | Toggle breakpoint      |
| `Space dc`  | Continue / start debug |
| `Space di`  | Step into              |
| `Space dO`  | Step over              |
| `Space do`  | Step out               |
| `Space du`  | Toggle DAP UI          |
| `Space dPt` | Debug method           |
| `Space dPc` | Debug class            |

### LSP

| Shortcut   | Action             |
| ---------- | ------------------ |
| `K`        | Hover docs         |
| `Space ca` | Code actions       |
| `Space cr` | Rename symbol      |
| `Space cf` | Format file        |
| `Space cv` | Select Python venv |

## Tools installed by setup.sh

| Category             | Tools                                    |
| -------------------- | ---------------------------------------- |
| Shell & prompt       | zsh, starship                            |
| Terminal             | tmux, fzf, eza, vivid, ranger, bat, tldr |
| Search               | ripgrep, fd, zoxide                      |
| Editor               | neovim, neovide (macOS)                  |
| Git                  | gh, lazygit, glab                        |
| Python               | uv, marimo                               |
| Data                 | duckdb, jq, yq                           |
| Kubernetes           | kubectl, k9s, kubectx, kubens            |
| Infrastructure       | terraform                                |
| Node / AI            | node (nvm), claude-code                  |
| Terminal emulator    | wezterm (macOS)                          |
| Font                 | MesloLGS Nerd Font                       |

## Secrets

Tokens and credentials go in `~/.secrets.zsh` (not tracked by git):

```bash
export RS_TOKEN_STG=...
```

## Adding more configs

1. Add the config file under the appropriate directory in the repo.
2. Add a symlink entry in `install.sh` (use the `IS_MACOS` flag for platform-specific paths).
3. If it's a new tool, add an install step in `setup.sh`.
