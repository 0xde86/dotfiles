# Login shells only, and the ly session (/etc/ly/setup.sh sources this
# before exec'ing Hyprland). Runs once per login.
#
# Environment and PATH are NOT here — they live in ~/.zshenv so that plain
# `zsh script.zsh` gets them too. This file is for once-per-session setup.

# One ssh-agent per login. Previously this ran in .zshrc, which spawned a
# fresh agent for every terminal window and leaked the processes.
if [ -z "$SSH_AUTH_SOCK" ] && command -v ssh-agent >/dev/null 2>&1; then
	eval "$(ssh-agent -s)" >/dev/null
fi
