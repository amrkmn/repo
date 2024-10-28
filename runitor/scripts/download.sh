#!/bin/bash

# Set the script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")

# Define the runitor directory
RUNITOR_DIR="${ROOT_DIR}/data"
mkdir -p "$RUNITOR_DIR"
echo -e "runitor directory set to $RUNITOR_DIR\n"

# Get the latest version from GitHub API
# VERSION=$(curl -s https://api.github.com/repos/bdd/runitor/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
VERSION=1.3.0

if [ -z "$VERSION" ]; then
    echo "failed to get the version."
    exit 1
fi

echo "version detected: $VERSION"

# Create a temporary directory for downloading files
TEMP_DIR=$(mktemp -d)
echo -e "temporary directory created at $TEMP_DIR\n"

# List of Runitor files to download
FILES=(
    "runitor-v${VERSION}-linux-amd64"
    "runitor-v${VERSION}-linux-arm"
    "runitor-v${VERSION}-linux-arm64"
)

# Function to download a file
download_file() {
    local file=$1
    local url=$2
    local dest=$3

    echo -e "downloading $file..."

    # Download the file
    curl -L --no-progress-meter -o "$dest" "$url"

    echo "download completed: $file"
}

# Download and process all files
for FILE in "${FILES[@]}"; do
    TEMP_FILE="${TEMP_DIR}/${FILE}"
    ARCH=$(echo "$FILE" | sed -E 's/.*linux-([^\.]+).*/\1/')

    if [ -f "${RUNITOR_DIR}/runitor_${VERSION}_${ARCH}.deb" ]; then
        echo -e "deb file already exists. skipping download and packaging for ${FILE}\n"
    else
        URL="https://github.com/bdd/runitor/releases/download/v${VERSION}/${FILE}"

        # Download the file
        download_file "$FILE" "$URL" "$TEMP_FILE"

        # Set variables for fpm
        DEST_BINARY="/usr/local/bin/runitor"
        DEB_FILE="${RUNITOR_DIR}/runitor_${VERSION}_${ARCH}.deb"

        # Use fpm to build the .deb package and specify output location
        fpm -s dir -t deb -n runitor -v "$VERSION" -a "$ARCH" \
            -p "${DEB_FILE}" \
            --description "A command runner with healthchecks.io integration " \
            --license "BSD Zero Clause License"
            --url "https://github.com/bdd/runitor" \
            --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
            --prefix /usr/local/bin \
            --after-install <(echo "chmod +x ${DEST_BINARY}") \
            "$TEMP_FILE=runitor"

        echo -e "deb package created: $DEB_FILE\n"
    fi
done

# Clean up temporary directory
rm -rf "$TEMP_DIR"
echo -e "temporary directory cleaned up."

echo "all linux-related files downloaded, processed, and packaged."
