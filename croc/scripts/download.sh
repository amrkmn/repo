#!/bin/bash

# Constants
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
CROC_DIR="${ROOT_DIR}/data"
GITHUB_REPO="https://api.github.com/repos/schollz/croc/releases/latest"

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

map_architecture() {
    local arch=$1

    case "$arch" in
        "32bit")
            echo "386"
            ;;
        "64bit")
            echo "amd64"
            ;;
        "ARM")
            echo "arm"
            ;;
        "ARM64")
            echo "arm64"
            ;;
        *)
            error "Unknown architecture: $arch"
            ;;
    esac
}

create_deb_package() {
    local file=$1
    local version=$2
    local arch=$3
    local extracted_binary="${TEMP_DIR}/croc"
    local dest_binary="/usr/local/bin/croc"
    local deb_file="${CROC_DIR}/croc_${version}_${arch}.deb"

    if [ -f "$deb_file" ]; then
        log "DEB file already exists. Skipping download and packaging for $file"
    else
        log "Creating DEB package for $file..."
        URL="https://github.com/schollz/croc/releases/download/v${version}/${file}"
        download_file "$file" "$URL" "${TEMP_DIR}/${file}"

        log "Extracting $file..."
        tar -xzf "${TEMP_DIR}/${file}" -C "$TEMP_DIR"
        if [ $? -ne 0 ]; then
            error "Extraction failed for $file"
        fi

        fpm -s dir -t deb -n croc -v "$version" -a "$arch" \
            -p "$deb_file" \
            --description "Easily and securely send things from one computer to another" \
            --license "MIT License" \
            --url "https://github.com/schollz/croc" \
            --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
            --prefix /usr/local/bin \
            --after-install <(echo "chmod +x $dest_binary") \
            "$extracted_binary=croc"

        if [ $? -ne 0 ]; then
            error "Failed to create DEB package for $file"
        fi
        log "DEB package created: $deb_file"
    fi
}

# Main script logic
log "Setting Croc directory to $CROC_DIR"
mkdir -p "$CROC_DIR"

log "Getting latest version from GitHub API"
# VERSION=$(curl -s "$GITHUB_REPO" | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
VERSION="10.0.13"
if [ -z "$VERSION" ]; then
    error "Failed to get the version."
fi

log "Version detected: $VERSION"

TEMP_DIR=$(mktemp -d)
log "Temporary directory created at $TEMP_DIR"

FILES=(
    "croc_v${VERSION}_Linux-32bit.tar.gz"
    "croc_v${VERSION}_Linux-64bit.tar.gz"
    "croc_v${VERSION}_Linux-ARM.tar.gz"
    "croc_v${VERSION}_Linux-ARM64.tar.gz"
)

for FILE in "${FILES[@]}"; do
    ARCH=$(echo "$FILE" | sed -E 's/.*Linux-([^\.]+)\.tar\.gz/\1/')
    MAPPED_ARCH=$(map_architecture "$ARCH")
    create_deb_package "$FILE" "$VERSION" "$MAPPED_ARCH"
done

log "Cleaning up temporary directory"
rm -rf "$TEMP_DIR"
log "Temporary directory cleaned up."

log "All Linux-related files downloaded, processed, and packaged."
