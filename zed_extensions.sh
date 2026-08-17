#!/usr/bin/env bash
#
# zed_extensions.sh — check that Zed's installed extensions match what the
# committed settings.json declares.
#
#   ./zed_extensions.sh diff   # report drift, non-zero exit if any (default)
#   ./zed_extensions.sh list   # print the currently installed extension ids
#
# Unlike VSCodium, Zed needs no install script: "auto_install_extensions" in
# settings.json is authoritative and Zed acts on it at startup. But Zed never
# writes that key back when you install from the extensions page, so an
# extension added through the UI is invisible to git until someone notices.
# This script is that noticer.
#
# It deliberately only reads. settings.json is JSONC — comments and trailing
# commas — so there is no safe jq round-trip, and a mangled settings file is a
# worse outcome than pasting four lines by hand. Drift is printed ready to paste.
#
set -euo pipefail

REPO="$(dirname "$(readlink -f "$0")")"
# Both overridable so the drift paths can be exercised against fixtures.
SETTINGS="${SETTINGS:-$REPO/dev/.config/zed/settings.json}"
EXT_DIR="${EXT_DIR:-${XDG_DATA_HOME:-$HOME/.local/share}/zed/extensions/installed}"

installed() {
  [[ -d "$EXT_DIR" ]] || return 0
  find "$EXT_DIR" -mindepth 1 -maxdepth 1 -printf '%f\n' | LC_ALL=C sort
}

# Pull the ids out of the auto_install_extensions block. Only entries mapped to
# true count: an id set to false is a deliberate "keep this uninstalled".
declared() {
  [[ -f "$SETTINGS" ]] || { echo "missing $SETTINGS" >&2; exit 1; }
  awk '
    /"auto_install_extensions"[[:space:]]*:/ { inblock = 1; next }
    inblock && /^[[:space:]]*}/             { inblock = 0 }
    inblock && /"[^"]+"[[:space:]]*:[[:space:]]*true/ {
      id = $0
      sub(/^[[:space:]]*"/, "", id)
      sub(/"[[:space:]]*:.*/, "", id)
      print id
    }
  ' "$SETTINGS" | LC_ALL=C sort
}

cmd_diff() {
  local undeclared missing
  undeclared=$(comm -23 <(installed) <(declared))
  missing=$(comm -13 <(installed) <(declared))

  if [[ -z "$undeclared" && -z "$missing" ]]; then
    echo "zed extensions in sync"
    return 0
  fi

  if [[ -n "$undeclared" ]]; then
    echo "installed but not declared — these would be lost on a fresh machine."
    echo "add to \"auto_install_extensions\" in dev/.config/zed/settings.json:"
    printf '    "%s": true,\n' $undeclared
  fi

  if [[ -n "$missing" ]]; then
    [[ -n "$undeclared" ]] && echo
    echo "declared but not installed — Zed installs these next time it starts,"
    echo "so this is only a problem if it persists:"
    printf '    %s\n' $missing
  fi
  return 1
}

case "${1:-diff}" in
  diff) cmd_diff ;;
  list) installed ;;
  *) echo "usage: $0 {diff|list}" >&2; exit 2 ;;
esac
