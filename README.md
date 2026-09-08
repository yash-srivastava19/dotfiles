# dotfiles

My dev environment — configs, keybindings, toolchain pins, package lists.
Managed with [chezmoi](https://chezmoi.io). Arch/Omarchy and macOS.

## New machine

```sh
git clone https://github.com/yash-srivastava19/dotfiles ~/dotfiles
~/dotfiles/bootstrap.sh
```

Then open a new shell and `gh auth login`.

## Day-to-day

```sh
chezmoi diff              # what would change in $HOME
chezmoi apply             # repo -> $HOME
chezmoi add ~/.config/foo # track a new file
chezmoi re-add            # pull local edits back in
chezmoi update            # pull, then apply
```

Commit and push from this repo as usual.

## Layout

`.chezmoiroot` points at `home/`, the chezmoi source tree: `dot_` becomes a
leading `.`, `.tmpl` is a Go template, `executable_` sets the executable bit.
`.chezmoiignore` drops `hypr/` and `omarchy/` on macOS. `packages/` holds the
install lists; `bootstrap.sh` runs the whole thing.

## Notes

- No secrets: built from an allowlist, not a denylist.
- Versions are pinned exactly in `mise/config.toml` and `nvim/lazy-lock.json`.
  That is where reproducibility comes from — bump deliberately.
- `hypr/monitors.lua.tmpl` branches on hostname. `~/.zshrc.local` is sourced
  last if present and never committed.
- `hypr/autostart.lua` is empty but required — `hyprland.lua` does an
  unconditional `require("hypr.autostart")`.
