# nix

CLI packages for macOS and Linux, listed in `flake.nix` and installed into
`~/.local/share/nix-tools` (put on PATH by `profile/.profile`).
GUI apps (casks) stay in `macbook/Brewfile`.

## Commands

Aliases from `profile/.profile`, usable from any folder:

```bash
nixapply    # install packages from flake.nix (run after editing the list)
nixup       # update nixpkgs in flake.lock, install, then delete old versions (nix store gc)
```

Without the aliases: `./apply.sh`, `./apply.sh update`, `nix store gc` from this folder.

## Add or remove a package

1. Edit the `paths` list in `flake.nix` (find names at https://search.nixos.org/packages).
2. Run `nixapply`.
3. Commit `flake.nix`.

## Update everything

1. Run `nixup`.
2. Commit `flake.lock`.

## Roll back

```bash
git checkout <old-commit> -- flake.lock   # or flake.nix
./apply.sh
```
