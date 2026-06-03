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

printf "\n ────────── Updating claude code ────────── \n\n"
claude update
