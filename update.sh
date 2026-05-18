#!/bin/bash

echo "Updating packman packages..."
sudo pacman -Syu
echo "Updating AUR packages..."
paru -Syu
echo "Rebuilding hyprland..."
paru -S --rebuild $(pacman -Qq | grep hypr)

echo "Updating Rustup & Updating rust binaries..."
rustup self update
cargo install-update -a

echo "Updating zvm..."
zvm upgrade

echo "Updating GM..." 
gm up
echo "Updating Go software..."
gup update

echo "Updating bun..."
bun upgrade

echo "Updating zsh plugins..."
cd ~/.zsh/zsh-autosuggestions
git pull
cd ~/.zsh/zsh-completions
git pull
cd ~/.zsh/zsh-syntax-highlighting
git pull

echo "Updating flutter"
cd ~/flutter
git pull

echo "Updating claude code..."
claude update
