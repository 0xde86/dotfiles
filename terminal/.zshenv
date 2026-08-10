# Sourced by EVERY zsh: login, interactive, and scripts — and by the ly
# session before Hyprland starts (see /etc/ly/setup.sh, the */zsh branch).
#
# That makes it the one hook where login shells, scripts and Hyprland all
# agree, which is why the environment lives here. Keep it to environment
# only: no output, no interactive setup, nothing slow.

[ -f "$HOME/.config/shell/env" ] && . "$HOME/.config/shell/env"
