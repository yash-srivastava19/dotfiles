# dotfiles

My development environment — dotfiles, keybindings, toolchain pins and package
lists — managed with [chezmoi](https://chezmoi.io). Works on Arch/Omarchy and
macOS from the same source.

## New machine

```sh
git clone https://github.com/yash-srivastava19/dotfiles ~/dotfiles
~/dotfiles/bootstrap.sh
```

Installs packages, applies dotfiles, installs the pinned runtimes. Then open a
new shell and run `gh auth login`.

## Day-to-day

```sh
chezmoi diff              # what would change in $HOME
chezmoi apply             # repo -> $HOME
chezmoi add ~/.config/foo # start tracking a file
chezmoi re-add            # pull local edits back into the repo
chezmoi update            # git pull, then apply
```

Then commit and push from this repo as usual.

## Layout

```
.chezmoiroot            "home" — only that subtree is applied to $HOME
home/                   chezmoi source directory
  .chezmoiignore        per-OS exclusions (itself a template)
  .chezmoiexternal.toml Omarchy themes, cloned rather than vendored
  dot_zshrc.tmpl        -> ~/.zshrc
  dot_config/...        -> ~/.config/...
packages/               curated install lists
bootstrap.sh            fresh-machine entrypoint
```

chezmoi naming: `dot_` becomes a leading `.`, `.tmpl` marks a Go template,
`executable_` sets the executable bit, `private_` sets 0600.

## Why chezmoi

- **It writes real files, not symlinks.** Omarchy rewrites `~/.config/hypr/*`
  on upgrade. Under home-manager those are read-only symlinks into the nix
  store and the upgrade fails; here it succeeds and `chezmoi diff` shows what
  changed, to accept (`re-add`) or revert (`apply`).
- **Templates handle the Arch/macOS split.** `dot_zshrc.tmpl` renders correctly
  on both; `.chezmoiignore` drops `hypr/` and `omarchy/` on macOS. stow has no
  answer for this.
- **Reproducibility comes from pinning**, not from nix: exact versions in
  `mise/config.toml`, exact commits in `nvim/lazy-lock.json`. Most of the
  benefit without a fourth thing on `PATH` after pacman, yay and mise.

## Notes

- **No secrets.** Built from an explicit allowlist, so tokens and keys are
  excluded by construction rather than by a denylist that eventually leaks.
- **`packages/` is not `pacman -Qqe`.** That list is mostly install-time system
  state (`base`, `efibootmgr`, `cups-*`, `intel-ucode`) which must not be
  replayed onto another machine. This one is hand-curated dev tooling; GUI apps
  are installed by hand.
- **Per-machine bits.** `hypr/monitors.lua.tmpl` branches on hostname — add a
  block per machine (`hyprctl monitors` lists outputs). `~/.zshrc.local` is
  sourced last if present and never committed.
- **`hypr/autostart.lua` is empty but committed.** `hyprland.lua` does an
  unconditional `require("hypr.autostart")`, so a missing file aborts the whole
  config load on a fresh machine.
- **Not tracked:** `btop.conf` (btop rewrites it on every exit),
  `kitty.conf` (kitty not installed). `event-horizon` is commented out in
  `.chezmoiexternal.toml` — ~406MB of video backgrounds.
