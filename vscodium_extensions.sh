#!/usr/bin/env bash
#
# vscodium_extensions.sh — keep the set of installed VSCodium extensions in git.
#
#   ./vscodium_extensions.sh save             # write the installed set to the list
#   ./vscodium_extensions.sh restore          # install everything named in the list
#   ./vscodium_extensions.sh restore --prune  # ...and uninstall anything not in it
#   ./vscodium_extensions.sh diff             # show what save would change
#
# Only extension ids are stored, never versions, so restore always resolves to
# the current build on Open VSX. Pin a version by writing publisher.name@1.2.3
# into the list by hand; --install-extension understands that form.
#
# The settings themselves are not handled here: ~/.config/VSCodium is already a
# stow symlink into dev/.config/VSCodium, so User/settings.json is tracked
# directly. Extensions live outside that tree (~/.vscode-oss/extensions) and are
# far too large and machine-specific to commit, hence this list.
#
set -euo pipefail

LIST="$(dirname "$(readlink -f "$0")")/vscodium_extensions.txt"

# `code` is only an alias for codium in the interactive shell, so resolve the
# real binary here.
CODE_BIN=${CODE_BIN:-}
if [[ -z "$CODE_BIN" ]]; then
  for candidate in codium vscodium code; do
    if command -v "$candidate" &>/dev/null; then CODE_BIN=$candidate; break; fi
  done
fi
[[ -n "$CODE_BIN" ]] || { echo "no codium/code binary on PATH" >&2; exit 1; }

# Sorted with a fixed collation so the committed diff only ever shows real
# additions and removals.
installed() { "$CODE_BIN" --list-extensions | LC_ALL=C sort; }

wanted() {
  [[ -f "$LIST" ]] || { echo "missing $LIST" >&2; exit 1; }
  grep -v -e '^[[:space:]]*#' -e '^[[:space:]]*$' "$LIST" | LC_ALL=C sort
}

cmd_save() {
  installed >"$LIST"
  echo "wrote $(grep -c . "$LIST") extension(s) to $LIST"
}

cmd_diff() {
  if diff -u --label "$LIST" --label installed "$LIST" <(installed); then
    echo "list is up to date"
  fi
}

cmd_restore() {
  local prune=0
  [[ ${1:-} == --prune ]] && prune=1

  local failed=()
  local ext
  while read -r ext; do
    echo " ── installing $ext"
    "$CODE_BIN" --install-extension "$ext" --force || failed+=("$ext")
  done < <(comm -23 <(wanted) <(installed))

  if ((prune)); then
    while read -r ext; do
      echo " ── removing $ext"
      "$CODE_BIN" --uninstall-extension "$ext" || failed+=("$ext")
    done < <(comm -13 <(wanted) <(installed))
  fi

  if ((${#failed[@]})); then
    printf '\n  !! %d extension(s) failed:\n' "${#failed[@]}" >&2
    printf '     %s\n' "${failed[@]}" >&2
    echo "     (not every publisher mirrors to Open VSX — install those by hand)" >&2
    exit 1
  fi
  echo "extensions in sync"
}

case "${1:-save}" in
  save)    cmd_save ;;
  restore) shift || true; cmd_restore "$@" ;;
  diff)    cmd_diff ;;
  *) echo "usage: $0 {save|restore [--prune]|diff}" >&2; exit 2 ;;
esac
