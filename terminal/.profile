# Read by sh/bash login shells and by anything that is not zsh.
#
# zsh NEVER reads this file — not even as a login shell. It uses ~/.zshenv,
# which sources the same env file, so the two stay in sync by construction.

[ -f "$HOME/.config/shell/env" ] && . "$HOME/.config/shell/env"
