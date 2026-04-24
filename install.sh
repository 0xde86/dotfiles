#!/bin/bash

sudo pacman -Syu
paru -Syu

sudo pacman -S ttf-font-nerd ttf-firacode-nerd ttf-font-awesome stow fzf eza ripgrep bat btop kitty starship
sudo pacman -S bubblewrap socat
sudo pacman -S yazi ffmpeg 7zip jq poppler fd zoxide imagemagick
sudo pacman -S zed helix neovim lldb hugo graphviz docker
sudo pacman -S flatpak
sudo pacman -S lua-language-server

# Setup appimage support
sudo pacman -S fuse
sudo modprobe fuse

# Setup integrated video
sudo pacman -Sy vulkan-intel

paru -S ttf-jetbrains-mono-nerd
paru -S brave-bin
paru -S vscodium-bin
paru -S golangci-lint

# Prepare dotfiles
cd ~/dotfiles
rm ~/.zshrc
rm ~/.zshenv
stow terminal
stow dev
rm -rf ~/.config/cosmic
rm -rf ~/.local/state/cosmic
rm -rf ~/.local/state/cosmic-comp
stow desktop

chsh -s $(which zsh)

# Setup zsh plugins
git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.zsh/zsh-syntax-highlighting
git clone https://github.com/zsh-users/zsh-completions.git ~/.zsh/zsh-completions

# Setup docker
sudo usermod -aG docker $USER
sudo systemctl start docker
sudo systemctl enable docker

# Setup Rust
curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh
. "$HOME/.cargo/env"

rustup component add rust-analyzer

# Install cargo software
cargo install fnm
cargo install cargo-audit
cargo install codebook-lsp
cargo install cargo-update

# Setup Zig (zvm)
curl https://raw.githubusercontent.com/tristanisham/zvm/master/install.sh | bash
source ~/.zshenv
zvm i --zls master

# Install Go manager
curl -fsSL https://raw.githubusercontent.com/x-dvr/gm/master/install.sh | bash
source ~/.zshenv

# Install Go toolchain
gm i latest

# Install Go software
# debugger
go install github.com/go-delve/delve/cmd/dlv@latest
# language server
go install golang.org/x/tools/gopls@latest
# lint lsp
go install github.com/nametake/golangci-lint-langserver@latest
# update tool
go install github.com/nao1215/gup@latest
# cobra cli
go install github.com/spf13/cobra-cli@latest
# go releaser
go install github.com/goreleaser/goreleaser/v2@latest
# hacker-news reader
go install github.com/bensadeh/circumflex/cmd/clx@latest

# install bun
curl -fsSL https://bun.sh/install | bash

reboot
