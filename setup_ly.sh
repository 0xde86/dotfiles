#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly CONFIG_SOURCE="${SCRIPT_DIR}/ly/config.ini"
readonly STARTUP_SOURCE="${SCRIPT_DIR}/ly/startup.sh"
readonly CONFIG_DESTINATION="/etc/ly/config.ini"
readonly STARTUP_DESTINATION="/etc/ly/startup.sh"

if (( EUID != 0 )); then
    printf 'This installer needs root privileges. Run:\n  sudo %q\n' "$0" >&2
    exit 1
fi

for command in pacman systemctl install cp; do
    if ! command -v "$command" >/dev/null 2>&1; then
        printf 'Required command not found: %s\n' "$command" >&2
        exit 1
    fi
done

for source_file in "$CONFIG_SOURCE" "$STARTUP_SOURCE"; do
    if [[ ! -f "$source_file" ]]; then
        printf 'Required file not found: %s\n' "$source_file" >&2
        exit 1
    fi
done

printf 'Installing Ly and brightness controls...\n'
pacman -S --needed ly brightnessctl

# Preserve the first pre-dotfiles version so the change remains recoverable.
for destination in "$CONFIG_DESTINATION" "$STARTUP_DESTINATION"; do
    if [[ -e "$destination" && ! -e "${destination}.pre-dotfiles.bak" ]]; then
        cp -a -- "$destination" "${destination}.pre-dotfiles.bak"
    fi
done

printf 'Installing the captured Ly configuration...\n'
install -d -m 0755 /etc/ly
install -m 0644 -- "$CONFIG_SOURCE" "$CONFIG_DESTINATION"
install -m 0755 -- "$STARTUP_SOURCE" "$STARTUP_DESTINATION"

# These are the greeters installed on the source machine. Leave them installed,
# but prevent them from competing with Ly on the next boot.
for unit in cosmic-greeter-daemon.service cosmic-greeter.service; do
    for unit_dir in /etc/systemd/system /run/systemd/system \
        /usr/local/lib/systemd/system /usr/lib/systemd/system \
        /lib/systemd/system; do
        if [[ -e "${unit_dir}/${unit}" ]]; then
            systemctl disable "$unit"
            break
        fi
    done
done

printf 'Enabling Ly on TTY 2...\n'
systemctl enable ly@tty2.service

printf 'Ly setup complete. The display-manager change takes effect at the next boot.\n'
