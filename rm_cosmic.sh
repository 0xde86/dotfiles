#!/usr/bin/env bash

sudo pacman -Rns \
  cosmic-session cosmic-comp cosmic-greeter cosmic-settings cosmic-settings-daemon \
  cosmic-panel cosmic-applets cosmic-app-library cosmic-launcher cosmic-workspaces \
  cosmic-notifications cosmic-osd cosmic-bg cosmic-idle cosmic-randr cosmic-screenshot \
  cosmic-files cosmic-terminal cosmic-text-editor cosmic-player \
  cosmic-icon-theme cosmic-sound-theme cosmic-wallpapers \
  xdg-desktop-portal-cosmic

sudo userdel -r cosmic-greeter          # -r also removes /var/lib/cosmic-greeter
sudo rm -rf /var/lib/cosmic-greeter     # only if userdel left it behind
sudo rm -rf /usr/share/cosmic /usr/share/backgrounds/cosmic
pacman -Qdtq                            # review orphans; pipe to `sudo pacman -Rns -` if all look safe
