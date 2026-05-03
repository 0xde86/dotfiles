#!/bin/bash

sudo pacman -Syu
paru -Syu

# rust
rustup self update
cargo install-update -a

# zig
zvm upgrade

# go
gm up
gup update

# bun
bun upgrade

# zsh plugins
cd ~/.zsh/zsh-autosuggestions
git pull
cd ~/.zsh/zsh-completions
git pull
cd ~/.zsh/zsh-syntax-highlighting
git pull

# flutter
cd ~/flutter
git pull

claude update