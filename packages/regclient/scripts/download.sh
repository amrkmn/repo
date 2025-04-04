#!/bin/bash

# Constants
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
REGCLIENT_DIR="${ROOT_DIR}/data"
#GITHUB_REPO="https://api.github.com/repos/regclient/regclient/releases/latest"
GITHUB_REPO="https://ungh.cc/repos/regclient/regclient/releases/latest"

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
        "amd64")
            echo "amd64"
            ;;
        "arm64")
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
    local package_name=$(echo "$file" | sed 's/-.*//')
    local extracted_binary="${TEMP_DIR}/${file}"
    local dest_binary="/usr/local/bin/$package_name"
    local deb_file="${REGCLIENT_DIR}/${package_name}_${version}_${arch}.deb"

    if [ -f "$deb_file" ]; then
        log "DEB file already exists. Skipping download and packaging for $package_name"
    else
        log "Creating DEB package for $package_name..."
        URL="https://github.com/regclient/regclient/releases/download/v${version}/${file}"
        download_file "$file" "$URL" "${TEMP_DIR}/${file}"

        log "Extracting $file..."
        chmod +x "${TEMP_DIR}/${file}"

        fpm -s dir -t deb -n "$package_name" -v "$version" -a "$arch" \
            -p "$deb_file" \
            --description "A tool for managing and interacting with container registries" \
            --license "Apache License 2.0" \
            --url "https://github.com/regclient/regclient" \
            --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
            --prefix /usr/local/bin \
            --after-install <(echo "chmod +x $dest_binary") \
            "${TEMP_DIR}/${file}=$package_name"

        if [ $? -ne 0 ]; then
            error "Failed to create DEB package for $package_name"
        fi
        log "DEB package created: $deb_file"
    fi
}

# Main script logic
log "Setting Regclient directory to $REGCLIENT_DIR"
mkdir -p "$REGCLIENT_DIR"

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
    "regctl-linux-amd64"
    "regctl-linux-arm64"
    "regsync-linux-amd64"
    "regsync-linux-arm64"
    "regbot-linux-amd64"
    "regbot-linux-arm64"
)

# Loop through files for each package (regctl, regsync, regbot)
for FILE in "${FILES[@]}"; do
    create_deb_package "$FILE" "$VERSION" "$(echo "$FILE" | sed -E 's/.*linux-([^\.]+)$/\1/')"
done

log "Cleaning up temporary directory"
rm -rf "$TEMP_DIR"
log "Temporary directory cleaned up."

log "All Linux-related files downloaded, processed, and packaged."
