# dotfiles

My development environment: dotfiles, keybindings, toolchain pins, and the
package list needed to reproduce them. Managed with
[chezmoi](https://chezmoi.io).

## New machine

```sh
git clone <this-repo> ~/dotfiles
~/dotfiles/bootstrap.sh
```

Then open a new shell. Credentials are deliberately not automated — run
`gh auth login` and sign in to 1Password yourself.

## Day-to-day

```sh
chezmoi diff              # what would change in $HOME
chezmoi apply             # apply repo -> $HOME
chezmoi add ~/.config/foo # start tracking a new file
chezmoi re-add            # pull local edits back into the repo
chezmoi edit ~/.zshrc     # edit the source of a managed file
chezmoi update            # git pull, then apply
```

After `chezmoi add`/`re-add`, commit and push from this repo as normal.

These bare commands work because `bootstrap.sh` records `sourceDir` in
`~/.config/chezmoi/chezmoi.toml`. `chezmoi init --source=...` does *not*
persist it, so without that step every command would need `--source=` and
`chezmoi add` would write to the wrong place.

## Why chezmoi and not stow / nix

- **chezmoi writes real files, not symlinks.** Omarchy rewrites
  `~/.config/hypr/*` and `~/.bashrc` on upgrade. Under home-manager those are
  read-only symlinks into the nix store and the upgrade fails; here the
  upgrade just succeeds and `chezmoi diff` shows what changed, so it can be
  accepted (`re-add`) or reverted (`apply`).
- **Templating handles the Arch/macOS split.** `dot_zshrc.tmpl` renders a
  correct `.zshrc` on both; `.chezmoiignore` drops `hypr/` and `omarchy/`
  entirely on macOS. Symlink farms like stow have no answer for this.
- **Nix would give byte-identical binaries**, which chezmoi does not. The
  substitute is pinning: exact versions in `mise/config.toml`, exact commits
  in `nvim/lazy-lock.json`. That is most of the practical benefit without
  making nix a fourth thing on `PATH` after pacman, yay, and mise.

## Layout

```
.chezmoiroot          -> "home", so only home/ is applied to $HOME
home/                 chezmoi source directory
  .chezmoiignore      per-OS exclusions (a template)
  .chezmoiexternal.toml   Omarchy themes, cloned rather than vendored
  dot_zshrc.tmpl      -> ~/.zshrc
  dot_config/...      -> ~/.config/...
packages/             curated install lists (arch, aur, brew, brew-cask)
bootstrap.sh          fresh-machine entrypoint
```

chezmoi's naming rules used here: `dot_` becomes a leading `.`,
`.tmpl` marks a Go-template file, `executable_` sets the executable bit,
`private_` sets 0600.

## What is deliberately excluded

- **Secrets.** `~/.config/gh` (OAuth token), `~/.claude.json`, `~/.kube`,
  `~/.config/1Password`. The repo is built from an explicit allowlist, never
  a copy-everything-minus-a-denylist.
- **`pacman -Qqe` in full.** 252 explicit packages include `base`,
  `efibootmgr`, `btrfs-progs`, `cups-*`, `intel-ucode`, `retroarch` and the
  libretro cores — install-time system state, not devex. `packages/arch.txt`
  is hand-curated.
- **Omarchy theme repos.** Cloned by `.chezmoiexternal.toml` rather than
  vendored. `event-horizon` (~406MB of video backgrounds) is commented out —
  uncomment it there if you want it.
- **`btop.conf`.** btop rewrites the whole file on exit, so tracking it means
  endless diffs for two non-default settings.
- **`kitty.conf`.** kitty is not installed; the config is an Omarchy leftover.
- **GUI apps.** `packages/` is dev tooling only. 1Password, Obsidian,
  Tailscale and LocalSend are installed by hand.
- **`~/.config/hypr/hyprland.conf`.** Dead file. Omarchy quattro's entrypoint
  is `hyprland.lua`; the `.conf` is the stock upstream sample and is not read.

## Per-machine bits

- `home/dot_config/hypr/monitors.lua.tmpl` branches on hostname. Add a block
  for each new machine (`hyprctl monitors` lists the outputs).
- `~/.zshrc.local` is sourced last if present and is never committed — the
  place for a machine's own exports.
- `hypr/autostart.lua` is empty but committed anyway: `hyprland.lua` does an
  unconditional `require("hypr.autostart")`, so a missing file would abort the
  whole config load on a fresh machine and leave Hyprland with no user config.
