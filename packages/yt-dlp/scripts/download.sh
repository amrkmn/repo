#!/bin/bash

# Constants
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")
YTDLP_DIR="${ROOT_DIR}/data"
#GITHUB_REPO="https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
GITHUB_REPO="https://ungh.cc/repos/yt-dlp/yt-dlp/releases/latest"
# BUILD_NUMBER=1

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

    case "$arch" in
        "linux") arch="amd64" ;;
        "armv7l") arch="arm" ;;
        "aarch64") arch="arm64" ;;
        *) error "Unsupported architecture: $arch" ;;
    esac

    # Add build number
    # version+="-build${BUILD_NUMBER}"

    local dest_binary="/usr/local/bin/yt-dlp"
    local deb_file="${YTDLP_DIR}/yt-dlp_${version}_${arch}.deb"

    if [ -f "$deb_file" ]; then
        log "DEB file already exists. Skipping download and packaging for $file"
    else
        log "Creating DEB package for $file..."
        URL="https://github.com/yt-dlp/yt-dlp/releases/latest/download/${file}"
        download_file "$file" "$URL" "${TEMP_DIR}/${file}"

        fpm -s dir -t deb -n yt-dlp -v "$version" -a "$arch" \
            -p "$deb_file" \
            --description "A feature-rich command-line audio/video downloader" \
            --license "Unlicense" \
            --url "https://github.com/yt-dlp/yt-dlp" \
            --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
            --prefix /usr/local/bin \
            --after-install <(echo "chmod +x ${dest_binary}") \
            "${TEMP_DIR}/${file}=yt-dlp"

        if [ $? -ne 0 ]; then
            error "Failed to create DEB package for $file"
        fi
        log "DEB package created: $deb_file"
    fi
}

# Main script logic
log "Setting yt-dlp directory to $YTDLP_DIR"
mkdir -p "$YTDLP_DIR"

log "Getting latest version from GitHub API"
#VERSION=$(curl -s "$GITHUB_REPO" | grep '"tag_name":' | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
VERSION=$(curl -s "$GITHUB_REPO" | grep '"tag":' | sed -E 's/.*"([0-9]+\.[0-9]+\.[0-9]+)".*/\1/')
if [ -z "$VERSION" ]; then
    error "Failed to get the version."
fi

log "Version detected: $VERSION"

TEMP_DIR=$(mktemp -d)
log "Temporary directory created at $TEMP_DIR"

FILES=(
    "yt-dlp_linux"
    "yt-dlp_linux_armv7l"
    "yt-dlp_linux_aarch64"
)

for FILE in "${FILES[@]}"; do
    ARCH=$(echo "$FILE" | sed -E 's/yt-dlp_linux(_)?(armv7l|aarch64)?/\2/')
    ARCH=${ARCH:-linux} # Default to linux if no architecture suffix
    create_deb_package "$FILE" "$VERSION" "$ARCH"
done

log "Cleaning up temporary directory"
rm -rf "$TEMP_DIR"
log "Temporary directory cleaned up."

log "All Linux-related files downloaded, processed, and packaged."
