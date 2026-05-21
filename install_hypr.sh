#!/bin/bash

sudo pacman -Syu

sudo pacman -S hyprland xdg-desktop-portal-hyprland hyprlock hypridle
sudo pacman -S swaylock hyprshutdown nwg-look
sudo pacman -S wl-clipboard grim slurp swaybg ttf-jetbrains-mono-nerd
sudo pacman -S hyprlauncher hyprpaper hyprpolkitagent waybar hyprshot
sudo pacman -S swaync # remove dunst if needed
sudo pacman -S qt5-wayland qt6-wayland