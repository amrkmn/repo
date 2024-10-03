#!/bin/bash

# Set the script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")

# Define the restic directory
RESTIC_DIR="${ROOT_DIR}/data"
mkdir -p "$RESTIC_DIR"
echo -e "restic directory set to $RESTIC_DIR\n"

# Get the latest version from GitHub API
VERSION=$(curl -s https://api.github.com/repos/restic/restic/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')

if [ -z "$VERSION" ]; then
  echo "failed to get the latest version from github."
  exit 1
fi

echo "latest version detected: $VERSION"

# Create a temporary directory for downloading files
TEMP_DIR=$(mktemp -d)
echo -e "temporary directory created at $TEMP_DIR\n"

# List of Linux-related restic files to download
FILES=(
  "restic_${VERSION}_linux_386.bz2"
  "restic_${VERSION}_linux_amd64.bz2"
  "restic_${VERSION}_linux_arm.bz2"
  "restic_${VERSION}_linux_arm64.bz2"
  "restic_${VERSION}_linux_mips.bz2"
  "restic_${VERSION}_linux_mips64.bz2"
  "restic_${VERSION}_linux_mips64le.bz2"
  "restic_${VERSION}_linux_mipsle.bz2"
  "restic_${VERSION}_linux_ppc64le.bz2"
  "restic_${VERSION}_linux_riscv64.bz2"
  "restic_${VERSION}_linux_s390x.bz2"
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
  ARCH=$(echo "$FILE" | sed -E 's/.*linux_([^\.]+)\.bz2/\1/')

  if [ -f "${RESTIC_DIR}/restic_${VERSION}_${ARCH}.deb" ]; then
    echo -e "deb file already exists. skipping download and packaging for ${FILE%.bz2}\n"
  else
    URL="https://github.com/restic/restic/releases/download/v${VERSION}/${FILE}"

    # Download the file
    download_file "$FILE" "$URL" "$TEMP_FILE"

    # Extract the file
    echo "extracting ${FILE}..."
    bunzip2 "$TEMP_FILE"

    # Check if extraction was successful
    if [ $? -ne 0 ]; then
      echo -e "extraction failed for ${FILE}.\n"
      continue
    fi

    # Set variables for fpm
    EXTRACTED_BINARY="${TEMP_FILE%.bz2}"
    DEST_BINARY="/usr/local/bin/restic"
    DEB_FILE="${RESTIC_DIR}/restic_${VERSION}_${ARCH}.deb"

    # Use fpm to build the .deb package and specify output location
    fpm -s dir -t deb -n restic -v "$VERSION" -a "$ARCH" \
      -p "${DEB_FILE}" \
      --description "Fast, secure, efficient backup program" \
      --url "https://restic.net/" \
      --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
      --prefix /usr/local/bin \
      --after-install <(echo "chmod +x ${DEST_BINARY}") \
      "$EXTRACTED_BINARY=restic"

    echo -e "deb package created: $DEB_FILE\n"
  fi
done

# Clean up temporary directory
rm -rf "$TEMP_DIR"
echo -e "temporary directory cleaned up."

echo "all linux-related files downloaded, processed, and packaged."
