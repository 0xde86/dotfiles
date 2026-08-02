#!/usr/bin/env bash

set -euo pipefail

readonly THEME_NAME="vir-norin"
readonly SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
readonly SOURCE_DIR="${SCRIPT_DIR}/plymouth/${THEME_NAME}"
readonly DESTINATION_DIR="/usr/share/plymouth/themes/${THEME_NAME}"

readonly THEME_FILES=(
  README.md
  background.png
  bar_box.png
  bar_fill.png
  generate.py
  scanlines.png
  vir-norin.plymouth
  vir-norin.script
)

if (( EUID != 0 )); then
  printf 'This installer needs root privileges. Run:\n  sudo %q\n' "$0" >&2
  exit 1
fi

for command in install plymouth-set-default-theme mkinitcpio; do
  if ! command -v "$command" >/dev/null 2>&1; then
    printf 'Required command not found: %s\n' "$command" >&2
    exit 1
  fi
done

for file in "${THEME_FILES[@]}"; do
  if [[ ! -f "${SOURCE_DIR}/${file}" ]]; then
    printf 'Theme file not found: %s\n' "${SOURCE_DIR}/${file}" >&2
    exit 1
  fi
done

printf 'Installing Plymouth theme %s...\n' "$THEME_NAME"
install -d -m 0755 "$DESTINATION_DIR"

for file in "${THEME_FILES[@]}"; do
  install -m 0644 "${SOURCE_DIR}/${file}" "${DESTINATION_DIR}/${file}"
done

printf 'Selecting %s as the default Plymouth theme...\n' "$THEME_NAME"
plymouth-set-default-theme "$THEME_NAME"

printf 'Rebuilding initramfs images...\n'
mkinitcpio -P

printf 'Plymouth theme %s installed successfully.\n' "$THEME_NAME"
