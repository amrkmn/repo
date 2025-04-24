#!/bin/bash

# Constants
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
RESTIC_DIR="${ROOT_DIR}/data"
#GITHUB_REPO="https://api.github.com/repos/restic/restic/releases/latest"
GITHUB_REPO="https://ungh.cc/repos/restic/restic/releases/latest"

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
    local extracted_binary="${TEMP_DIR}/${file%.bz2}"
    local dest_binary="/usr/local/bin/restic"
    local deb_file="${RESTIC_DIR}/restic_${version}_${arch}.deb"

    if [ -f "$deb_file" ]; then
        log "DEB file already exists. Skipping download and packaging for $file"
    else
        log "Creating DEB package for $file..."
        URL="https://gh-v6.com/restic/restic/releases/download/v${version}/${file}"
        download_file "$file" "$URL" "${TEMP_DIR}/${file}"

        log "Extracting $file..."
        bunzip2 "${TEMP_DIR}/${file}" || { log "Extraction failed for $file"; return; }

        fpm -s dir -t deb -n restic -v "$version" -a "$arch" \
            -p "$deb_file" \
            --description "Fast, secure, efficient backup program" \
            --license "BSD 2-Clause License" \
            --url "https://restic.net/" \
            --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
            --prefix /usr/local/bin \
            --after-install <(echo "chmod +x $dest_binary") \
            "$extracted_binary=restic"

        if [ $? -ne 0 ]; then
            error "Failed to create DEB package for $file"
        fi
        log "DEB package created: $deb_file"
    fi
}

# Main script logic
log "Setting Restic directory to $RESTIC_DIR"
mkdir -p "$RESTIC_DIR"

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
    "restic_${VERSION}_linux_386.bz2"
    "restic_${VERSION}_linux_amd64.bz2"
    "restic_${VERSION}_linux_arm.bz2"
    "restic_${VERSION}_linux_arm64.bz2"
)

for FILE in "${FILES[@]}"; do
    create_deb_package "$FILE" "$VERSION" "$(echo "$FILE" | sed -E 's/.*linux_([^\.]+).*/\1/')"
done

log "Cleaning up temporary directory"
rm -rf "$TEMP_DIR"
log "Temporary directory cleaned up."

log "All Linux-related files downloaded, processed, and packaged."
