#!/usr/bin/env bash
# fix-apt-sources.sh — repairs broken apt sources before running setup.sh
set -euo pipefail

echo "==> Fixing apt sources..."

# ── 1. Google Chrome ──────────────────────────────────────────────────────────
# Key rotated; re-fetch the official signing key into the keyrings dir.
echo "  [fix] Google Chrome key..."
curl -fsSL https://dl.google.com/linux/linux_signing_key.pub \
  | sudo gpg --dearmor -o /usr/share/keyrings/google-chrome.gpg

# Ensure the .list file references the keyring (idempotent write)
echo "deb [arch=amd64 signed-by=/usr/share/keyrings/google-chrome.gpg] \
http://dl.google.com/linux/chrome/deb/ stable main" \
  | sudo tee /etc/apt/sources.list.d/google-chrome.list > /dev/null

# ── 2. GitHub CLI ─────────────────────────────────────────────────────────────
# Key expired; pull the current one from the official source.
echo "  [fix] GitHub CLI key..."
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
  | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg

sudo chmod go+r /usr/share/keyrings/githubcli-archive-keyring.gpg

echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] \
https://cli.github.com/packages stable main" \
  | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null

# ── 3. mc3man/trusty-media PPA ────────────────────────────────────────────────
# This PPA never published a release for Ubuntu 22.04 Jammy — remove it.
echo "  [remove] mc3man/trusty-media PPA (no Jammy release)..."
sudo add-apt-repository --remove --yes ppa:mc3man/trusty-media 2>/dev/null || \
  sudo rm -f /etc/apt/sources.list.d/mc3man-ubuntu-trusty-media-*.list \
             /etc/apt/sources.list.d/mc3man-ubuntu-trusty-media-*.sources

# ── 4. openSUSE zsh-syntax-highlighting ──────────────────────────────────────
# Key expired. setup.sh doesn't need this repo (it installs zsh via apt).
# Safest fix: remove the repo. zsh-syntax-highlighting is installed as a
# Zsh plugin (e.g. via oh-my-zsh or zplug) not as a distro package.
echo "  [remove] openSUSE zsh-syntax-highlighting repo (expired key)..."
sudo rm -f \
  /etc/apt/sources.list.d/*zsh-syntax-highlighting* \
  /etc/apt/sources.list.d/*zsh-users*

# ── Done ──────────────────────────────────────────────────────────────────────
echo ""
echo "  [done] Running apt-get update to verify..."
sudo apt-get update

echo ""
echo "==> All sources fixed. You can now run ./setup.sh"
