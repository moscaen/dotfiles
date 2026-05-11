# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Overview

Personal dotfiles for macOS and WSL (Ubuntu/Debian). Catppuccin Macchiato is the universal theme. The repo assumes it lives at `~/repos/dotfiles`.

## Key Commands

```bash
./setup.sh      # Install all tools + link configs (runs install.sh at the end)
./install.sh    # Symlink configs only (backs up existing files to *.backup)
```

Both scripts auto-detect macOS vs Linux/WSL via `uname -s` and adjust paths and install methods accordingly.

## Architecture

**Two-script model:** `setup.sh` installs tools (brew on macOS, apt + manual GitHub releases on Linux), then calls `install.sh`. `install.sh` creates symlinks from the repo into `$HOME` and patches Windows Terminal settings on WSL.

**Zsh plugins** are git submodules under `zsh/plugins/` — after cloning, run `git submodule update --init --recursive` (install.sh does this automatically).

**Platform-specific paths:** k9s config goes to `~/Library/Application Support/k9s/` on macOS and `~/.config/k9s/` on Linux. lazygit config path also differs. Both are handled via `$IS_MACOS` conditionals.

**Neovim** uses LazyVim (bootstrapped in `config/nvim/init.lua`). Plugin extras are declared in `config/nvim/lazyvim.json`. Neovide-specific config is gated behind `vim.g.neovide`.

**Secrets** go in `~/.secrets.zsh` (sourced by zshrc, never committed).

## Adding a New Config

1. Add the config file under the appropriate directory.
2. Add a `"source:target"` symlink entry in `install.sh` (use `$IS_MACOS` for platform-specific paths).
3. If it needs a new tool, add an install block in `setup.sh` using the `install_if_missing` helper or a custom block for tools not in apt.

## Adding a New Zsh Plugin

Add as a git submodule under `zsh/plugins/`, then source it in `zshrc`.
