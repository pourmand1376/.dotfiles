# nix

| File | What |
|---|---|
| `packages.nix` | CLI packages, shared by macOS and Linux |
| `darwin.nix` | macOS only (nix-darwin): packages, brew formulae/casks, App Store apps, macOS settings, Dock |
| `flake.nix` | wires it up: hostname-based macOS configurations, `packages.<system>.default` (Linux) |
| `apply.sh` | applies it: nix-darwin on macOS, `buildEnv` into `~/.local/share/nix-tools` on Linux |

Nix itself is installed and managed by Determinate Nix, so `darwin.nix` sets `nix.enable = false`.

## Commands

Aliases from `profile/.profile`, usable from any folder:

```bash
nixapply    # apply the config (asks for sudo on macOS)
nixup       # update nixpkgs + nix-darwin, apply, brew upgrade, then nixgc
nixgc       # delete generations older than 30 days + unused /nix/store paths (asks for sudo on macOS)
```

Without the aliases: `./apply.sh`, `./apply.sh update`, `./apply.sh gc` from this folder.

To delete *all* old generations (no rollback left): `sudo nix-collect-garbage -d`.

## Find a package

Search https://search.nixos.org/packages?channel=unstable (this flake uses `nixpkgs-unstable`).
Use the name shown there in `packages.nix`, and check "Platforms" lists `aarch64-darwin` for the Mac.
From the terminal: `nix search nixpkgs <name>`.

## Change something

- CLI tool: edit `packages.nix`
- brew cask / formula, App Store app, macOS setting, Dock: edit `darwin.nix`
- App Store ID: `mas search <name>`

Then run `nixapply` and commit.

`nixapply` installs only what you added; it does not upgrade anything. Versions come from
`flake.lock`, which only `nixup` changes, so existing packages stay the same build and are
reused from the store. Brew also only installs what is missing (`upgrade = false`).

Avoid `nix profile install nixpkgs#<name>`: it uses the latest nixpkgs instead of `flake.lock`
and is not recorded in this repo, so the other Mac won't get it. To try a tool once without
installing it: `nix shell nixpkgs#<name>`.

## Dotfiles (stow)

Every `nixapply` / `nixup` also re-stows the dotfile folders into `$HOME` (`stow -R`, which also
removes links to files deleted from the repo). The lists are at the top of `apply.sh`:

- `STOW_COMMON`: macOS and Linux
- `STOW_MAC`: macOS only
- `STOW_SKIP`: top-level folders that are not stow packages

A new top-level folder that is in none of these lists prints a warning on apply, so add it to one.
If stow reports a conflict, a real file is in the way in `$HOME`: move it into the repo or delete it.

## Roll back (macOS)

```bash
sudo darwin-rebuild --rollback      # previous generation
darwin-rebuild --list-generations
```

Or check out an old `flake.lock` / `*.nix` from git and run `nixapply`.

## How it is built

```
nix-darwin          darwin.nix: packages, apps, fonts, brew, App Store, macOS settings
  └─ Homebrew       only what nixpkgs can't provide (nix-darwin runs `brew bundle`)
Determinate Nix     installs and runs Nix itself (daemon, /etc/nix/nix.conf)
macOS
```

- Determinate Nix = Nix. nix-darwin runs on top of it and does not manage Nix (`nix.enable = false`).
- Where things end up:
  - CLI tools: `/run/current-system/sw/bin`
  - GUI apps: `/Applications/Nix Apps`
  - fonts: `/Library/Fonts/Nix Fonts`
  - brew apps: `/Applications` and `/opt/homebrew`
- Claude Code comes from nix; its own updater is off, `nixup` updates it. codex and gemini-cli come from brew.

## Install on a new Mac

1. **Determinate Nix**: download and run the macOS installer (.pkg) from
   https://install.determinate.systems/determinate-pkg/stable/Universal
   (or: `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`)
2. **Homebrew**: nothing to do; `apply.sh` installs it if `brew` is missing.
3. **This repo**: `git clone git@github.com:pourmand1376/.dotfiles.git ~/gitfolder/.dotfiles`
4. Both Macs use the shared `AmirMac` configuration. The hostname does not need to
   match; `apply.sh` selects it directly.
5. Sign in to the App Store (needed for App Store apps).
6. **nix-darwin**: run `~/gitfolder/.dotfiles/nix/apply.sh`. The first run builds nix-darwin from
   this flake and switches to it (asks for sudo). Stock `/etc/zshrc`, `/etc/bashrc` etc. are renamed
   to `*.before-nix-darwin` automatically; nix-darwin stops only if one has unknown content.
   macOS asks to give your terminal "App Management" permission (needed to copy apps into
   `/Applications/Nix Apps`).
7. Open a new terminal. From now on: `nixapply` / `nixup`.

## Install on Linux

1. `curl -fsSL https://install.determinate.systems/nix | sh -s -- install`
2. Clone this repo to `~/.dotfiles` (or `~/gitfolder/.dotfiles`) and run `nix/apply.sh`.
   It builds `packages.nix` into `~/.local/share/nix-tools` (no nix-darwin, no brew).
