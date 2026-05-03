#!/bin/bash

sudo pacman -Syu

sudo pacman -S hyprland xdg-desktop-portal-hyprland hyprlock hypridle
sudo pacman -S swaylock
sudo pacman -S wl-clipboard grim slurp swaybg ttf-jetbrains-mono-nerd
sudo pacman -S hyprlauncher hyprpaper hyprpolkitagent waybar hyprshot
sudo pacman -S swaync # remove dunst if needed

paru -S qt5-wayland qt6-wayland
paru -S hyprshutdown
paru -S nwg-look catppuccin-gtk-theme-frappe

# temporary fix
sudo ln -s /usr/lib/libhyprutils.so.0.13.0 /usr/lib/libhyprutils.so.11
sudo ldconfig