#!/usr/bin/env bash
# Bring a fresh machine up to this devex setup.
#
#   git clone <this repo> ~/devex && ~/devex/bootstrap.sh
#
# Idempotent: safe to re-run. Installs packages, then hands off to chezmoi,
# which owns every dotfile from here on.
set -euo pipefail

REPO="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
OS="$(uname -s)"

log()  { printf '\033[1;34m==>\033[0m %s\n' "$*"; }
warn() { printf '\033[1;33m!!\033[0m %s\n' "$*" >&2; }

# Strip comments and blank lines from a package list.
pkgs() { grep -vE '^\s*(#|$)' "$1" | tr '\n' ' '; }

# ---------------------------------------------------------------- packages
install_arch_packages() {
  if ! command -v yay >/dev/null; then
    warn "yay not found; skipping package install. Install yay, then re-run."
    return
  fi
  log "Installing Arch packages (yay may prompt for sudo)"
  # shellcheck disable=SC2046
  yay -S --needed --noconfirm $(pkgs "$REPO/packages/arch.txt") $(pkgs "$REPO/packages/aur.txt")
}

install_brew_packages() {
  if ! command -v brew >/dev/null; then
    log "Installing homebrew"
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    for p in /opt/homebrew /usr/local; do
      [[ -x $p/bin/brew ]] && eval "$($p/bin/brew shellenv)" && break
    done
  fi
  log "Installing homebrew formulae"
  # shellcheck disable=SC2046
  brew install $(pkgs "$REPO/packages/brew.txt")
  log "Installing homebrew casks"
  # shellcheck disable=SC2046
  brew install --cask $(pkgs "$REPO/packages/brew-cask.txt") || \
    warn "some casks failed (already installed, or need manual approval)"
}

case "$OS" in
  Linux)
    if command -v pacman >/dev/null; then
      install_arch_packages
    else
      warn "Not an Arch system — packages/arch.txt not applied. Install the"
      warn "equivalents by hand; the dotfile step below still works."
    fi
    ;;
  Darwin) install_brew_packages ;;
  *)      warn "Unsupported OS '$OS'; skipping packages." ;;
esac

# ---------------------------------------------------------------- chezmoi
if ! command -v chezmoi >/dev/null; then
  log "Installing chezmoi to ~/.local/bin"
  mkdir -p "$HOME/.local/bin"
  sh -c "$(curl -fsLS get.chezmoi.io)" -- -b "$HOME/.local/bin"
fi
export PATH="$HOME/.local/bin:$PATH"

# `chezmoi init --source` does NOT persist the source directory, so a later
# bare `chezmoi apply` / `diff` / `add` would look in ~/.local/share/chezmoi
# and fail. Record sourceDir explicitly so the day-to-day commands in the
# README work from anywhere. chezmoi reads .chezmoiroot from here, so this
# points at the repo root, not repo/home.
CHEZMOI_CONFIG="${XDG_CONFIG_HOME:-$HOME/.config}/chezmoi/chezmoi.toml"
if [[ -f $CHEZMOI_CONFIG ]] && ! grep -q "sourceDir" "$CHEZMOI_CONFIG"; then
  warn "$CHEZMOI_CONFIG exists without a sourceDir; leaving it alone."
else
  log "Recording sourceDir in $CHEZMOI_CONFIG"
  mkdir -p "$(dirname "$CHEZMOI_CONFIG")"
  printf 'sourceDir = "%s"\n' "$REPO" > "$CHEZMOI_CONFIG"
fi

log "Applying dotfiles from $REPO"
chezmoi apply --verbose

# ---------------------------------------------------------------- runtimes
if command -v mise >/dev/null; then
  log "Installing pinned runtimes with mise"
  mise install
else
  warn "mise not on PATH; open a new shell and run 'mise install'."
fi

# ---------------------------------------------------------------- shell
if [[ "$(basename "${SHELL:-}")" != zsh ]] && command -v zsh >/dev/null; then
  warn "Default shell is not zsh. Change it with:  chsh -s \"$(command -v zsh)\""
fi

log "Done. Open a new shell."
log "Not handled here (deliberately): 'gh auth login', 1Password sign-in,"
log "and anything else that needs a credential."
