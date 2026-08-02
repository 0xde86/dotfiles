#!/usr/bin/env bash

set -euo pipefail

readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly THEME_DIR="/usr/share/grub/themes/cachyos"
readonly THEME_FILE="${THEME_DIR}/theme.txt"
readonly GRUB_CONFIG="/boot/grub/grub.cfg"
readonly FONT_42_SOURCE="${SCRIPT_DIR}/grub/fonts/jetbrainsmono-42.pf2"
readonly FONT_48_SOURCE="${SCRIPT_DIR}/grub/fonts/jetbrainsmono-48.pf2"

if (( EUID != 0 )); then
    printf 'This script must run as root. Run:\n  sudo %q\n' "$0" >&2
    exit 1
fi

for required_file in "$FONT_42_SOURCE" "$FONT_48_SOURCE" "$THEME_FILE"; do
    if [[ ! -f "$required_file" ]]; then
        printf 'Required file not found: %s\n' "$required_file" >&2
        exit 1
    fi
done

if command -v grub-mkconfig >/dev/null 2>&1; then
    grub_mkconfig="grub-mkconfig"
elif command -v grub2-mkconfig >/dev/null 2>&1; then
    grub_mkconfig="grub2-mkconfig"
else
    printf 'Neither grub-mkconfig nor grub2-mkconfig was found.\n' >&2
    exit 1
fi

# Keep the first version seen by this script so repeated runs do not overwrite it.
if [[ ! -e "${THEME_FILE}.pre-jetbrains-mono.bak" ]]; then
    cp -a -- "$THEME_FILE" "${THEME_FILE}.pre-jetbrains-mono.bak"
fi

install -m 0644 -- "$FONT_42_SOURCE" "${THEME_DIR}/jetbrainsmono-42.pf2"
install -m 0644 -- "$FONT_48_SOURCE" "${THEME_DIR}/jetbrainsmono-48.pf2"

# Match settings by key, regardless of which font the theme currently uses.
sed -E -i 's|^([[:space:]]*terminal-font:[[:space:]]*).*$|\1"JetBrainsMono NF Regular 42"|' "$THEME_FILE"
sed -E -i 's|^([[:space:]]*item_font[[:space:]]*=[[:space:]]*).*$|\1"JetBrainsMono NF Regular 48"|' "$THEME_FILE"
sed -E -i 's|^([[:space:]]*font[[:space:]]*=[[:space:]]*).*$|\1"JetBrainsMono NF Regular 42"|' "$THEME_FILE"
sed -E -i 's|^([[:space:]]*item_height)[[:space:]]*=.*$|\1 = 54|' "$THEME_FILE"

grep -Eq '^[[:space:]]*terminal-font:[[:space:]]*"JetBrainsMono NF Regular 42"[[:space:]]*$' "$THEME_FILE"
grep -Eq '^[[:space:]]*item_font[[:space:]]*=[[:space:]]*"JetBrainsMono NF Regular 48"[[:space:]]*$' "$THEME_FILE"
grep -Eq '^[[:space:]]*font[[:space:]]*=[[:space:]]*"JetBrainsMono NF Regular 42"[[:space:]]*$' "$THEME_FILE"
grep -Eq '^[[:space:]]*item_height[[:space:]]*=[[:space:]]*54[[:space:]]*$' "$THEME_FILE"

"$grub_mkconfig" -o "$GRUB_CONFIG"

printf 'Installed JetBrains Mono Nerd Font and updated %s.\n' "$THEME_FILE"
