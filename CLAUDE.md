# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS and WSL (Ubuntu/Debian). Catppuccin Macchiato is the universal theme. The repo assumes it lives at `~/repos/dotfiles`.

## Key Commands

```bash
./setup.sh          # Install all tools + link configs (runs install.sh at the end)
./install.sh        # Symlink configs only (backs up existing files to *.backup)
./uninstall.sh      # Remove symlinks, revert Windows Terminal/VS Code, optionally remove packages
./backup.sh         # Snapshot dotfiles + Windows Terminal/VS Code settings to a timestamped tarball
./fix-apt-sources.sh  # Repair broken apt signing keys before setup.sh (WSL only)
```

Both `setup.sh` and `install.sh` auto-detect macOS vs Linux/WSL via `uname -s` and adjust paths and install methods accordingly.

The `Dockerfile` builds an Ubuntu 22.04 container that runs `setup.sh` end-to-end — use it to test the installer without touching the host.

## Architecture

**Two-script model:** `setup.sh` installs tools (brew on macOS, apt + manual GitHub releases on Linux), then calls `install.sh`. `install.sh` creates symlinks from the repo into `$HOME`, and on WSL also patches Windows Terminal settings.json and VS Code settings.json with the Catppuccin Macchiato theme (using `jq`; VS Code's JSONC is pre-processed with Python before passing to `jq`).

**Zsh plugins** are git submodules under `zsh/plugins/` — after cloning, run `git submodule update --init --recursive` (install.sh does this automatically).

**Platform-specific paths:** k9s config goes to `~/Library/Application Support/k9s/` on macOS and `~/.config/k9s/` on Linux. lazygit config path also differs. Both are handled via `$IS_MACOS` conditionals.

**Neovim** uses LazyVim (bootstrapped in `config/nvim/init.lua`). LazyVim extras (language packs etc.) are declared in `config/nvim/lazyvim.json`. Custom plugin overrides live in `config/nvim/lua/plugins/` — each file exports a table that LazyVim merges with its defaults. Neovide-specific config is gated behind `vim.g.neovide`.

**Lazygit theme** is loaded at runtime from `~/lazygit/themes-mergable/macchiato/blue.yml` (see `LG_CONFIG_FILE` in `zshrc`). This path is **not** managed by this repo — clone `catppuccin/lazygit` there separately.

**Secrets** go in `~/.secrets.zsh` (sourced by zshrc, never committed).

## Adding a New Config

1. Add the config file under the appropriate directory.
2. Add a `"source:target"` symlink entry in `install.sh` (use `$IS_MACOS` for platform-specific paths).
3. If it needs a new tool, add an install block in `setup.sh` using the `install_if_missing` helper or a custom block for tools not in apt.

## Adding a New Zsh Plugin

Add as a git submodule under `zsh/plugins/`, then source it in `zshrc`.
