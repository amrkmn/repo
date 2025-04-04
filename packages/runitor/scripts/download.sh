#!/bin/bash

# Constants
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
RUNITOR_DIR="${ROOT_DIR}/data"
#GITHUB_REPO="https://api.github.com/repos/bdd/runitor/releases/latest"
GITHUB_REPO="https://ungh.cc/repos/bdd/runitor/releases/latest"

# Functions
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1"
}

error() {
    log "ERROR: $1" >&2
    exit 1
}

download_file() {
    local file=$1
    local url=$2
    local dest=$3

    log "Downloading $file..."
    curl -L --no-progress-meter -o "$dest" "$url"
    if [ $? -ne 0 ]; then
        error "Failed to download $file from $url"
    fi
    log "Download completed: $file"
}

create_deb_package() {
    local file=$1
    local version=$2
    local arch=$3
    local dest_binary="/usr/local/bin/runitor"
    local deb_file="${RUNITOR_DIR}/runitor_${version}_${arch}.deb"

    if [ -f "$deb_file" ]; then
        log "DEB file already exists. Skipping download and packaging for $file"
    else
        log "Creating DEB package for $file..."
        URL="https://github.com/bdd/runitor/releases/download/v${version}/${file}"
        download_file "$file" "$URL" "${TEMP_DIR}/${file}"

        fpm -s dir -t deb -n runitor -v "$version" -a "$arch" \
            -p "${deb_file}" \
            --description "A command runner with healthchecks.io integration" \
            --license "BSD Zero Clause License" \
            --url "https://github.com/bdd/runitor" \
            --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
            --prefix /usr/local/bin \
            --after-install <(echo "chmod +x ${dest_binary}") \
            "${TEMP_DIR}/${file}=runitor"

        if [ $? -ne 0 ]; then
            error "Failed to create DEB package for $file"
        fi
        log "DEB package created: $deb_file"
    fi
}

# Main script logic
log "Setting runitor directory to $RUNITOR_DIR"
mkdir -p "$RUNITOR_DIR"

log "Getting latest version from GitHub API"
#VERSION=$(curl -s "$GITHUB_REPO" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
VERSION=$(curl -s "$GITHUB_REPO" | grep '"tag":' | sed -E 's/.*"v([^"]+)".*/\1/')
if [ -z "$VERSION" ]; then
    error "Failed to get the version."
fi

log "Version detected: $VERSION"

TEMP_DIR=$(mktemp -d)
log "Temporary directory created at $TEMP_DIR"

FILES=(
    "runitor-v${VERSION}-linux-amd64"
    "runitor-v${VERSION}-linux-arm"
    "runitor-v${VERSION}-linux-arm64"
)

for FILE in "${FILES[@]}"; do
    create_deb_package "$FILE" "$VERSION" "$(echo "$FILE" | sed -E 's/.*linux-([^\.]+).*/\1/')"
done

log "Cleaning up temporary directory"
rm -rf "$TEMP_DIR"
log "Temporary directory cleaned up."

log "All linux-related files downloaded, processed, and packaged."
