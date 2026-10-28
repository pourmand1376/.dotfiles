# dotfiles

Dotfiles managed with [GNU stow](https://www.gnu.org/software/stow/), packages and macOS settings with nix (+ nix-darwin on macOS).

## Setup

```bash
git clone <this repo> ~/gitfolder/.dotfiles
~/gitfolder/.dotfiles/nix/apply.sh
```

`nix/apply.sh` installs packages (nix, brew, App Store), applies macOS settings and stows every config folder into `$HOME`. See [nix/README.md](nix/README.md).

After the first run, `~/.profile` defines:

- `nixapply` — apply the config
- `nixup` — update everything, then clean
- `nixgc` — clean old generations only

Manual macOS steps that can't be automated are in [macbook/setup.md](macbook/setup.md).

To stow a single folder by hand:

```bash
stow -d ~/gitfolder/.dotfiles -t ~ folder_name
```

## Layout

- Top-level folders (`zsh`, `git`, `nvim`, …) are stow packages
- `nix/` — packages, nix-darwin, `apply.sh`
- `install/` — older per-distro install scripts
- `mac-server/` — docker-compose stacks for the home server
- `scripts/` — standalone utilities
- `archive/` — configs no longer in use

## Install scripts

- [Windows WSL](install/windows_wsl.sh)
- [Windows Winget](install/windows_install.bat)
- [Ubuntu Server (Without root)](install/server_install.sh)
- [Ubuntu](install/ubuntu_install.sh)
- [Kubuntu](install/kubuntu_install.sh)
- [Fedora](install/install_fedora.sh)
- [Arch](install/install_arch.sh)
- [Flatpak packages](install/flatpak_packages.sh)

## Fonts

[Nerd Fonts](https://www.nerdfonts.com/) (installed by nix-darwin on macOS).
