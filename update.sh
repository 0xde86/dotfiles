#!/bin/bash

printf "\n ────────── Updating packman packages ────────── \n\n"
sudo pacman -Syu
# printf "\nRebuilding hyprland"
# paru -S --rebuild $(pacman -Qq | grep hypr)

printf "\n ────────── Updating Rustup & Updating rust binaries ────────── \n\n"
rustup self update
cargo install-update -a

printf "\n ────────── Updating zvm ────────── \n\n"
zvm upgrade

printf "\n ────────── Updating GM ────────── \n\n" 
gm up
printf "\n ────────── Updating Go software ────────── \n\n"
gup update

printf "\n ────────── Updating helix ────────── \n\n"
cd ~/.local/src/helix || exit 1
helix_head_before=$(git rev-parse HEAD) || exit 1
if git pull --ff-only; then
    helix_head_after=$(git rev-parse HEAD) || exit 1
    if [[ "$helix_head_before" != "$helix_head_after" ]]; then
        if cargo install --path helix-term --locked; then
            # Grammar revisions are pinned in languages.toml, which is compiled
            # into the binary, so refetch and rebuild them against the new one.
            hx --grammar fetch
            hx --grammar build
        else
            printf "Helix build failed; skipping grammar rebuild.\n" >&2
        fi
    else
        printf "Helix is already up to date; skipping build.\n"
    fi
else
    printf "Helix update failed; skipping build.\n" >&2
fi

printf "\n ────────── Updating bun ────────── \n\n"
bun upgrade

printf "\n ────────── Updating zsh plugins ────────── \n\n"
cd ~/.zsh/zsh-autosuggestions
git pull
cd ~/.zsh/zsh-completions
git pull
cd ~/.zsh/zsh-syntax-highlighting
git pull

printf "\n ────────── Updating flutter ────────── \n\n"
cd ~/flutter
git pull

printf "\n ────────── Updating rpiboot ────────── \n\n"
cd ~/.rpiboot
git pull --recurse-submodules
make
cd ~/dotfiles

printf "\n ────────── Updating claude code ────────── \n\n"
claude update

printf "\n ────────── Updating codex ────────── \n\n"
codex update

printf "\n ────────── Recording VSCodium extensions ────────── \n\n"
# Only rewrites the list; commit it to make the change stick.
DOTFILES="$(dirname "$(readlink -f "$0")")"
"$DOTFILES/vscodium_extensions.sh" save

printf "\n ────────── Checking Zed extensions ────────── \n\n"
# Read-only: Zed's settings.json is the source of truth, this just reports
# anything installed from the extensions page that never made it into git.
"$DOTFILES/zed_extensions.sh" diff || true
