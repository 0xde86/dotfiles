#!/bin/bash

set -euo pipefail

export SWIFTLY_HOME_DIR="${SWIFTLY_HOME_DIR:-$HOME/.swiftly}"
export SWIFTLY_BIN_DIR="${SWIFTLY_BIN_DIR:-$SWIFTLY_HOME_DIR/bin}"
export SWIFTLY_TOOLCHAINS_DIR="${SWIFTLY_TOOLCHAINS_DIR:-$SWIFTLY_HOME_DIR/toolchains}"

archive="swiftly-$(uname -m).tar.gz"
download_url="https://download.swift.org/swiftly/linux/$archive"
install_tmp=$(mktemp -d "${TMPDIR:-/tmp}/swiftly-install.XXXXXX")
trap 'rm -rf "$install_tmp"' EXIT

curl -fL --progress-bar -o "$install_tmp/$archive" "$download_url"
tar -xzf "$install_tmp/$archive" -C "$install_tmp"

"$install_tmp/swiftly" init --no-modify-profile --quiet-shell-followup

. "$SWIFTLY_HOME_DIR/env.sh"
hash -r

printf 'Swiftly and the Swift toolchain are installed under %s\n' "$SWIFTLY_HOME_DIR"
