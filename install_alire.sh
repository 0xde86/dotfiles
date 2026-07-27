#!/bin/sh
# Download the latest Alire (alr) release from GitHub and install it into ~/.alire/
#
# Usage: ./install_alire.sh [-d DEST] [-t TAG]
#   -d DEST  install prefix (default: ~/.alire)
#   -t TAG   install a specific release tag (default: latest)

set -eu

REPO="alire-project/alire"
DEST="${ALIRE_PREFIX:-$HOME/.alire}"
TAG="latest"

while getopts "d:t:h" opt; do
    case "$opt" in
        d) DEST="$OPTARG" ;;
        t) TAG="$OPTARG" ;;
        h) sed -n '2,7p' "$0" | cut -c3-; exit 0 ;;
        *) exit 2 ;;
    esac
done

die() { printf 'error: %s\n' "$*" >&2; exit 1; }
have() { command -v "$1" >/dev/null 2>&1; }

have curl || die "curl is required"
have unzip || die "unzip is required"

# --- Figure out which asset we need -----------------------------------------

case "$(uname -s)" in
    Linux)  os="linux" ;;
    Darwin) os="macos" ;;
    MINGW*|MSYS*|CYGWIN*) os="windows" ;;
    *) die "unsupported OS: $(uname -s)" ;;
esac

case "$(uname -m)" in
    x86_64|amd64)  arch="x86_64" ;;
    aarch64|arm64) arch="aarch64" ;;
    *) die "unsupported architecture: $(uname -m)" ;;
esac

if [ "$TAG" = "latest" ]; then
    api="https://api.github.com/repos/$REPO/releases/latest"
else
    api="https://api.github.com/repos/$REPO/releases/tags/$TAG"
fi

printf 'Querying %s (%s)...\n' "$REPO" "$TAG"
release=$(curl -fsSL -H "Accept: application/vnd.github+json" "$api") ||
    die "failed to query the GitHub API"

version=$(printf '%s\n' "$release" |
    sed -n 's/.*"tag_name"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' | head -n1)
[ -n "$version" ] || die "could not determine the release tag"

# Binary assets are named like: alr-2.1.0-bin-x86_64-linux.zip
url=$(printf '%s\n' "$release" |
    sed -n 's/.*"browser_download_url"[[:space:]]*:[[:space:]]*"\([^"]*\)".*/\1/p' |
    grep -- "-bin-" | grep -- "-$arch-" | grep -- "-$os\." | head -n1)
[ -n "$url" ] || die "no $arch-$os binary asset in release $version"

archive=$(basename "$url")

# --- Download ----------------------------------------------------------------

tmp=$(mktemp -d "${TMPDIR:-/tmp}/alire-install.XXXXXX")
trap 'rm -rf "$tmp"' EXIT INT TERM

printf 'Downloading %s...\n' "$archive"
curl -fL --progress-bar -o "$tmp/$archive" "$url" || die "download failed"

# --- Extract into DEST -------------------------------------------------------

printf 'Extracting into %s...\n' "$DEST"
mkdir -p "$tmp/unpacked"
case "$archive" in
    *.zip)            unzip -q "$tmp/$archive" -d "$tmp/unpacked" ;;
    *.tar.gz|*.tgz)   tar -xzf "$tmp/$archive" -C "$tmp/unpacked" ;;
    *.tar.xz)         tar -xJf "$tmp/$archive" -C "$tmp/unpacked" ;;
    *) die "don't know how to extract $archive" ;;
esac

# Some releases wrap everything in a single top-level directory; unwrap it so
# the binary always lands at DEST/bin/alr.
src="$tmp/unpacked"
if [ "$(ls -A "$src" | wc -l)" -eq 1 ]; then
    only="$src/$(ls -A "$src")"
    [ -d "$only" ] && src="$only"
fi

mkdir -p "$DEST"
rm -rf "$DEST/bin"
(cd "$src" && cp -R . "$DEST/")

alr="$DEST/bin/alr"
[ -f "$alr" ] || die "expected $alr after extraction, but it is missing"
chmod +x "$alr"

printf '\nInstalled Alire %s to %s\n' "$version" "$DEST"
"$alr" --version || true

case ":$PATH:" in
    *":$DEST/bin:"*) ;;
    *) printf '\nAdd it to your PATH:\n    export PATH="%s/bin:$PATH"\n' "$DEST" ;;
esac
