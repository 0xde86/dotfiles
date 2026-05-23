#!/bin/bash

sudo pacman -Syu

sudo pacman -S base-devel git
sudo pacman -S ttf-jetbrains-mono-nerd ttf-font-nerd ttf-firacode-nerd ttf-font-awesome stow fzf eza ripgrep bat btop kitty starship
sudo pacman -S bubblewrap socat
sudo pacman -S yazi ffmpeg 7zip jq poppler fd zoxide imagemagick
sudo pacman -S zed helix neovim vscodium lldb hugo graphviz docker
sudo pacman -S flatpak
sudo pacman -S lua-language-server
sudo pacman -S lcov

# hyprland
sudo pacman -S hyprland xdg-desktop-portal-hyprland hyprlock hypridle
sudo pacman -S swaylock hyprshutdown nwg-look
sudo pacman -S wl-clipboard grim slurp swaybg ttf-jetbrains-mono-nerd
sudo pacman -S hyprlauncher hyprpaper hyprpolkitagent waybar hyprshot
sudo pacman -S swaync # remove dunst if needed
sudo pacman -S qt5-wayland qt6-wayland

# sudo pacman -S dnscrypt-proxy
# systemctl enable dnscrypt-proxy.service

# rebuild font cache
fc-cache -fv

# Setup KVM
sudo pacman -S qemu-full virt-manager virt-viewer libvirt dnsmasq edk2-ovmf swtpm iptables-nft
# enable and start the libvirtd daemon to manage virtual machines
sudo systemctl enable --now libvirtd
# non-root control over virtual machines
sudo usermod -aG libvirt $(whoami)
# start the default NAT network so VMs have internet access
sudo virsh net-start default
sudo virsh net-autostart default   

# Setup appimage support
sudo pacman -S fuse
sudo modprobe fuse

# Setup integrated video
sudo pacman -Sy vulkan-intel

# install catppucin gtk theme
curl -sL https://api.github.com/repos/catppuccin/gtk/releases/latest | \
jq -r '.assets[] | select(.name == "catppuccin-frappe-rosewater-standard+default.zip") | .browser_download_url' | \
xargs curl -L -o "theme.zip"
if echo "7693b77cef70814e277b6199b699c32c5229457641f811da9f70d2f51fbd89a3 theme.zip" | sha256sum --check --status; then
	mkdir -p ~/.local/share/themes
	unzip theme.zip -d ~/.local/share/themes/
	rm theme.zip

	mkdir -p ~/.config/gtk-3.0
	mkdir -p ~/.config/gtk-4.0
	THEME_DIR=~/.local/share/themes/catppuccin-frappe-rosewater-standard+default
	ln -sf "${THEME_DIR}/gtk-4.0/assets" ~/.config/gtk-4.0/assets
	ln -sf "${THEME_DIR}/gtk-4.0/gtk.css" ~/.config/gtk-4.0/gtk.css
	ln -sf "${THEME_DIR}/gtk-4.0/gtk-dark.css" ~/.config/gtk-4.0/gtk-dark.css
	ln -sf "${THEME_DIR}/gtk-3.0/assets" ~/.config/gtk-3.0/assets
	ln -sf "${THEME_DIR}/gtk-3.0/gtk.css" ~/.config/gtk-3.0/gtk.css
	ln -sf "${THEME_DIR}/gtk-3.0/gtk-dark.css" ~/.config/gtk-3.0/gtk-dark.css
else
	echo "theme.zip checksum mismatch, skipping GTK theme install" >&2
fi

# flutter dev
sudo pacman -S --needed jdk21-openjdk cmake
sudo archlinux-java set java-21-openjdk
git clone --depth 1 -b stable https://github.com/flutter/flutter.git ~/flutter


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
cargo install just
cargo install just-lsp
cargo install flutter_rust_bridge_codegen
cargo install cargo-update

# Setup zapp (zsa flash tool)
mkdir ~/dev
git clone https://github.com/zsa/zapp.git ~/dev/zapp
cargo install --path ~/dev/zapp/zapp

sudo cp ~/dev/zapp/udev/50-zsa.rules /etc/udev/rules.d/
sudo udevadm control --reload-rules
sudo udevadm trigger

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
# lint+lsp
go install github.com/golangci/golangci-lint/v2/cmd/golangci-lint@latest
go install github.com/nametake/golangci-lint-langserver@latest
# update tool
go install github.com/nao1215/gup@latest
# cobra cli
go install github.com/spf13/cobra-cli@latest
# go releaser
go install github.com/goreleaser/goreleaser/v2@latest
# hacker-news reader
go install github.com/bensadeh/circumflex/cmd/clx@latest
# benchstat
go install golang.org/x/perf/cmd/benchstat@latest

# install bun
curl -fsSL https://bun.sh/install | bash

reboot
