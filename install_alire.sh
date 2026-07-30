#!/bin/sh
# Download the latest Alire (alr) and Ada Language Server releases from GitHub
# and install them into ~/.alire/ and ~/.als/ respectively.
#
# An install that already matches the requested release is left alone; only the
# GitHub API is queried in that case, nothing is downloaded. -f forces a redo.
#
# Usage: ./install_alire.sh [-d DIR] [-l DIR] [-t TAG] [-s TAG] [-o WHAT] [-f]
#   -d DIR   Alire install prefix        (default: ~/.alire)
#   -l DIR   ALS install prefix          (default: ~/.als)
#   -t TAG   Alire release tag           (default: latest)
#   -s TAG   ALS release tag             (default: latest)
#   -o WHAT  install only "alr" or "als" (default: both)
#   -f       reinstall even if already up to date

set -eu

ALR_REPO="alire-project/alire"
ALS_REPO="AdaCore/ada_language_server"

ALR_DEST="${ALIRE_PREFIX:-$HOME/.alire}"
ALS_DEST="${ALS_PREFIX:-$HOME/.als}"
ALR_TAG="latest"
ALS_TAG="latest"
ONLY="both"
FORCE=no

# Written into each prefix so the next run knows what it installed.
STAMP=".install-tag"

while getopts "d:l:t:s:o:fh" opt; do
    case "$opt" in
        d) ALR_DEST="$OPTARG" ;;
        l) ALS_DEST="$OPTARG" ;;
        t) ALR_TAG="$OPTARG" ;;
        s) ALS_TAG="$OPTARG" ;;
        o) ONLY="$OPTARG" ;;
        f) FORCE=yes ;;
        h) sed -n '2,14p' "$0" | cut -c3-; exit 0 ;;
        *) exit 2 ;;
    esac
done

case "$ONLY" in
    both|alr|als) ;;
    *) printf 'error: -o must be "alr", "als" or "both"\n' >&2; exit 2 ;;
esac

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

have curl || die "curl is required"
have unzip || die "unzip is required"

# --- Platform detection ------------------------------------------------------
# Alire and ALS spell their assets differently (x86_64-linux vs Linux_amd64),
# so match on a set of aliases rather than one fixed name.

case "$(uname -s)" in
    Linux)  os_re="linux" ;;
    Darwin) os_re="macos|osx|darwin" ;;
    MINGW*|MSYS*|CYGWIN*) os_re="windows|win32|win64" ;;
    *) die "unsupported OS: $(uname -s)" ;;
esac

case "$(uname -m)" in
    x86_64|amd64)  arch_re="x86_64|amd64|x64" ;;
    aarch64|arm64) arch_re="aarch64|arm64" ;;
    *) die "unsupported architecture: $(uname -m)" ;;
esac

# --- Helpers -----------------------------------------------------------------

# release_json REPO TAG
release_json() {
    if [ "$2" = "latest" ]; then
        api="https://api.github.com/repos/$1/releases/latest"
    else
        api="https://api.github.com/repos/$1/releases/tags/$2"
    fi
    curl -fsSL -H "Accept: application/vnd.github+json" "$api" ||
        die "failed to query the GitHub API for $1"
}

# release_tag JSON
release_tag() {
    printf '%s\n' "$1" |
        sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1
}

# asset_url JSON [EXTRA_REGEX] -> the download URL matching this platform
asset_url() {
    _extra="${2:-}"
    _urls=$(printf '%s\n' "$1" |
        sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
        grep -Ev '\.(vsix|sha256|sha512|sig|asc|txt)$' |
        grep -Ei "($os_re)" |
        grep -Ei "($arch_re)" || true)
    if [ -n "$_extra" ]; then
        _urls=$(printf '%s\n' "$_urls" | grep -Ei -e "$_extra" || true)
    fi
    printf '%s\n' "$_urls" | head -n1
}

# version_number STRING -> the first dotted numeric run, e.g. "v2.1.0" -> "2.1.0"
version_number() {
    printf '%s' "$1" | grep -Eo '[0-9]+(\.[0-9]+)+' | head -n1 || true
}

# up_to_date DEST TAG BIN -> success if BIN is already at TAG, so skip the download
up_to_date() {
    _dest="$1"; _tag="$2"; _bin="$3"

    [ "$FORCE" = no ] || return 1
    [ -n "$_bin" ] && [ -f "$_bin" ] || return 1

    # Preferred: the stamp a previous run left, which needs no version parsing.
    if [ -f "$_dest/$STAMP" ]; then
        _stamp=$(cat "$_dest/$STAMP")
        [ "$_stamp" = "$_tag" ]
        return $?
    fi

    # No stamp (hand-installed, or installed before stamping existed): fall back
    # to asking the binary, comparing only the numeric part so that a "v" prefix
    # or a trailing build string doesn't cause a needless reinstall.
    _have=$(version_number "$("$_bin" --version 2>/dev/null || true)")
    _want=$(version_number "$_tag")
    [ -n "$_have" ] && [ -n "$_want" ] && [ "$_have" = "$_want" ]
}

# Refuse to wipe anything that isn't a dedicated install prefix.
safe_to_replace() {
    case "$1" in
        ""|"/"|"$HOME"|"$HOME/") return 1 ;;
        /*) return 0 ;;
        *) return 1 ;;
    esac
}

# fetch_and_extract URL DEST -- downloads, unwraps a single top-level
# directory if present, and replaces DEST with the archive contents.
fetch_and_extract() {
    _url="$1"
    _dest="$2"
    _archive=$(basename "$_url")

    _tmp=$(mktemp -d "${TMPDIR:-/tmp}/ada-install.XXXXXX")
    trap 'rm -rf "$_tmp"' EXIT INT TERM

    printf 'Downloading %s...\n' "$_archive"
    curl -fL --progress-bar -o "$_tmp/$_archive" "$_url" || die "download failed"

    mkdir -p "$_tmp/unpacked"
    case "$_archive" in
        *.zip)          unzip -q "$_tmp/$_archive" -d "$_tmp/unpacked" ;;
        *.tar.gz|*.tgz) tar -xzf "$_tmp/$_archive" -C "$_tmp/unpacked" ;;
        *.tar.xz)       tar -xJf "$_tmp/$_archive" -C "$_tmp/unpacked" ;;
        *) die "don't know how to extract $_archive" ;;
    esac

    _src="$_tmp/unpacked"
    if [ "$(ls -A "$_src" | wc -l)" -eq 1 ]; then
        _only="$_src/$(ls -A "$_src")"
        [ -d "$_only" ] && _src="$_only"
    fi

    printf 'Extracting into %s...\n' "$_dest"
    safe_to_replace "$_dest" || die "refusing to replace $_dest"
    rm -rf "$_dest"
    mkdir -p "$_dest"
    (cd "$_src" && cp -R . "$_dest/")

    rm -rf "$_tmp"
    trap - EXIT INT TERM
}

# --- Installers --------------------------------------------------------------

install_alire() {
    printf '\n== Alire ==\n'
    json=$(release_json "$ALR_REPO" "$ALR_TAG")
    version=$(release_tag "$json")
    [ -n "$version" ] || die "could not determine the Alire release tag"

    if up_to_date "$ALR_DEST" "$version" "$ALR_DEST/bin/alr"; then
        printf 'Alire %s already installed in %s -- skipping.\n' "$version" "$ALR_DEST"
        return 0
    fi

    # Binary assets are named like: alr-2.1.0-bin-x86_64-linux.zip
    url=$(asset_url "$json" "-bin-")
    [ -n "$url" ] || die "no matching Alire binary asset in release $version"

    fetch_and_extract "$url" "$ALR_DEST"

    [ -f "$ALR_DEST/bin/alr" ] || die "expected $ALR_DEST/bin/alr after extraction"
    chmod +x "$ALR_DEST/bin/alr"
    printf '%s\n' "$version" > "$ALR_DEST/$STAMP"

    printf 'Installed Alire %s to %s\n' "$version" "$ALR_DEST"
    "$ALR_DEST/bin/alr" --version || true
}

# The ALS layout has moved around between releases, so locate the binary rather
# than assuming a fixed path.
als_binary() {
    [ -d "$ALS_DEST" ] || return 0
    find "$ALS_DEST" -type f -name ada_language_server -print 2>/dev/null | head -n1
}

install_als() {
    printf '\n== Ada Language Server ==\n'
    json=$(release_json "$ALS_REPO" "$ALS_TAG")
    version=$(release_tag "$json")
    [ -n "$version" ] || die "could not determine the ALS release tag"

    if up_to_date "$ALS_DEST" "$version" "$(als_binary)"; then
        printf 'ALS %s already installed in %s -- skipping.\n' "$version" "$ALS_DEST"
        return 0
    fi

    url=$(asset_url "$json")
    [ -n "$url" ] || die "no matching ALS asset in release $version"

    fetch_and_extract "$url" "$ALS_DEST"

    als=$(als_binary)
    [ -n "$als" ] || die "ada_language_server not found under $ALS_DEST"
    chmod +x "$als"
    printf '%s\n' "$version" > "$ALS_DEST/$STAMP"

    # Upstream nests the binary per-platform, e.g.
    # vscode/ada/x64/linux/ada_language_server, and has changed that layout
    # between releases. Symlink it to a fixed spot so a PATH entry in your
    # shell config keeps working across upgrades.
    mkdir -p "$ALS_DEST/bin"
    ln -sf "$als" "$ALS_DEST/bin/ada_language_server"

    printf 'Installed ALS %s to %s\n' "$version" "$ALS_DEST"
    printf 'Binary:  %s\n' "$als"
    printf 'Symlink: %s/bin/ada_language_server\n' "$ALS_DEST"
}

# --- Run ---------------------------------------------------------------------

[ "$ONLY" = "als" ] || install_alire
[ "$ONLY" = "alr" ] || install_als

printf '\nDone.\n'

# Only suggest directories that actually hold a binary.
hint_dirs=""
[ -f "$ALR_DEST/bin/alr" ] && hint_dirs="$ALR_DEST/bin"
if [ -e "$ALS_DEST/bin/ada_language_server" ]; then
    hint_dirs="$hint_dirs $ALS_DEST/bin"
else
    als=$(als_binary)
    [ -n "$als" ] && hint_dirs="$hint_dirs $(dirname "$als")"
fi

for d in $hint_dirs; do
    case ":$PATH:" in
        *":$d:"*) ;;
        *) printf '    export PATH="%s:$PATH"\n' "$d" ;;
    esac
done
