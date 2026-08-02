#!/bin/bash

set -euo pipefail

export SWIFTLY_HOME_DIR="${SWIFTLY_HOME_DIR:-$HOME/.swiftly}"
export SWIFTLY_BIN_DIR="${SWIFTLY_BIN_DIR:-$SWIFTLY_HOME_DIR/bin}"
export SWIFTLY_TOOLCHAINS_DIR="${SWIFTLY_TOOLCHAINS_DIR:-$SWIFTLY_HOME_DIR/toolchains}"

die() {
    printf 'error: %s\n' "$*" >&2
    exit 1
}

require_patchelf() {
    if ! command -v patchelf >/dev/null 2>&1; then
        printf '%s\n' \
            'patchelf is required. Install the Swift dependencies on CachyOS with:' \
            'sudo pacman -S --needed base-devel git curl gnupg patchelf util-linux-libs libxml2-legacy ncurses libedit sqlite zlib-ng-compat' >&2
        exit 1
    fi
}

# Official UBI 9 binaries refer to the non-wide ncurses ABI names. CachyOS
# provides the ABI-compatible wide libraries instead, so rewrite the ELF NEEDED
# entries inside the user-owned toolchains. The libedit rewrite also makes the
# patcher useful for a toolchain previously installed for Debian.
patch_toolchains() {
    require_patchelf
    [ -d "$SWIFTLY_TOOLCHAINS_DIR" ] ||
        die "Swift toolchains directory not found: $SWIFTLY_TOOLCHAINS_DIR"

    patched=0
    toolchains=0

    while IFS= read -r -d '' toolchain_dir; do
        [ -d "$toolchain_dir/usr" ] || continue
        toolchains=$((toolchains + 1))

        while IFS= read -r -d '' elf_file; do
            needed=$(patchelf --print-needed "$elf_file" 2>/dev/null) || continue

            while IFS=: read -r old_library new_library; do
                if printf '%s\n' "$needed" | grep -Fqx "$old_library"; then
                    patchelf --replace-needed "$old_library" "$new_library" "$elf_file"
                    patched=$((patched + 1))
                fi
            done <<'EOF'
libncurses.so.6:libncursesw.so.6
libpanel.so.6:libpanelw.so.6
libform.so.6:libformw.so.6
libedit.so.2:libedit.so.0
EOF
        done < <(
            find "$toolchain_dir/usr" -type f \
                \( -perm /111 -o -name '*.so' -o -name '*.so.*' \) -print0
        )
    done < <(find "$SWIFTLY_TOOLCHAINS_DIR" -mindepth 1 -maxdepth 1 -type d -print0)

    [ "$toolchains" -gt 0 ] || die "no Swift toolchains found in $SWIFTLY_TOOLCHAINS_DIR"

    missing_libraries=$(
        find "$SWIFTLY_TOOLCHAINS_DIR" -type f \
            \( -perm /111 -o -name '*.so' -o -name '*.so.*' \) -print0 |
            while IFS= read -r -d '' elf_file; do
                patchelf --print-needed "$elf_file" >/dev/null 2>&1 || continue
                ldd "$elf_file" 2>/dev/null || true
            done |
            sed -n 's/^[[:space:]]*\([^[:space:]]*\) => not found$/\1/p' |
            sort -u
    )

    # UBI 9's LLDB is linked to Python 3.9. CachyOS does not package that ABI.
    # The compiler, SwiftPM and SourceKit-LSP work without it, but LLDB and the
    # Swift REPL require a separate Python 3.9 runtime.
    optional_missing=$(
        printf '%s\n' "$missing_libraries" |
            grep -Fx 'libpython3.9.so.1.0' || true
    )
    unresolved=$(
        printf '%s\n' "$missing_libraries" |
            grep -Fvx 'libpython3.9.so.1.0' || true
    )

    if [ -n "$unresolved" ]; then
        printf 'Unresolved Swift libraries after patching:\n%s\n' "$unresolved" >&2
        printf '%s\n' \
            'Install the Swift dependencies on CachyOS with:' \
            'sudo pacman -S --needed base-devel git curl gnupg patchelf util-linux-libs libxml2-legacy ncurses libedit sqlite zlib-ng-compat' >&2
        exit 1
    fi

    if [ -n "$optional_missing" ]; then
        printf '%s\n' \
            'warning: UBI 9 LLDB expects libpython3.9.so.1.0, which CachyOS does not package.' \
            'The compiler, SwiftPM and SourceKit-LSP will work; LLDB and the Swift REPL may not start.' >&2
    fi

    printf 'Patched %d ELF dependencies across %d Swift toolchain(s).\n' \
        "$patched" "$toolchains"
}

if [ "${1:-}" = "--patch-only" ]; then
    [ "$#" -eq 1 ] || die 'usage: install_swiftly.sh [--patch-only]'
    patch_toolchains
    exit 0
elif [ "$#" -ne 0 ]; then
    die 'usage: install_swiftly.sh [--patch-only]'
fi

archive="swiftly-$(uname -m).tar.gz"
download_url="https://download.swift.org/swiftly/linux/$archive"
install_tmp=$(mktemp -d "${TMPDIR:-/tmp}/swiftly-install.XXXXXX")
trap 'rm -rf "$install_tmp"' EXIT

curl -fL --progress-bar -o "$install_tmp/$archive" "$download_url"
tar -xzf "$install_tmp/$archive" -C "$install_tmp"

init_options=(
    init
    --platform ubi9
    --no-modify-profile
    --quiet-shell-followup
    --assume-yes
)

if [ -f "$SWIFTLY_HOME_DIR/config.json" ]; then
    configured_platform=$(
        sed -n 's/.*"name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' \
            "$SWIFTLY_HOME_DIR/config.json" | head -n 1
    )
    if [ "$configured_platform" != "ubi9" ]; then
        printf 'Replacing the existing %s Swift toolchain with UBI 9.\n' \
            "${configured_platform:-unknown}"
        init_options+=(--overwrite)
    fi
fi

"$install_tmp/swiftly" "${init_options[@]}"

. "$SWIFTLY_HOME_DIR/env.sh"
hash -r

patch_toolchains

swift --version
printf 'Swiftly and the patched UBI 9 Swift toolchain are installed under %s\n' \
    "$SWIFTLY_HOME_DIR"
