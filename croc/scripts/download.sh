#!/bin/bash

# Set the script directory
SCRIPT_DIR=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" &>/dev/null && pwd)
ROOT_DIR=$(dirname "$SCRIPT_DIR")

# Define the croc directory
CROC_DIR="${ROOT_DIR}/data"
mkdir -p "$CROC_DIR"
echo -e "croc directory set to $CROC_DIR\n"

# Define the version for Croc
# VERSION=$(curl -s https://api.github.com/repos/schollz/croc/releases/latest | grep '"tag_name":' | sed -E 's/.*"v([^"]+)".*/\1/')
echo "croc version: $VERSION"

# Create a temporary directory for downloading files
TEMP_DIR=$(mktemp -d)
echo -e "temporary directory created at $TEMP_DIR\n"

# List of Linux-related croc files to download
FILES=(
  "croc_v${VERSION}_Linux-32bit.tar.gz"
  "croc_v${VERSION}_Linux-64bit.tar.gz"
  "croc_v${VERSION}_Linux-ARM.tar.gz"
  "croc_v${VERSION}_Linux-ARM64.tar.gz"
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

# Map architecture from Croc file to standard arch format
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
      echo "unknown"
      ;;
  esac
}

# Download and process all files
for FILE in "${FILES[@]}"; do
  TEMP_FILE="${TEMP_DIR}/${FILE}"
  ARCH=$(echo "$FILE" | sed -E 's/.*Linux-([^\.]+)\.tar\.gz/\1/')
  MAPPED_ARCH=$(map_architecture "$ARCH")

  if [ -f "${CROC_DIR}/croc_${VERSION}_${MAPPED_ARCH}.deb" ]; then
    echo -e "deb file already exists. skipping download and packaging for ${FILE%.tar.gz}\n"
  else
    URL="https://github.com/schollz/croc/releases/download/v${VERSION}/${FILE}"

    # Download the file
    download_file "$FILE" "$URL" "$TEMP_FILE"

    # Extract the file
    echo "extracting ${FILE}..."
    tar -xzf "$TEMP_FILE" -C "$TEMP_DIR"

    # Check if extraction was successful
    if [ $? -ne 0 ]; then
      echo -e "extraction failed for ${FILE}.\n"
      continue
    fi

    # Set variables for fpm
    EXTRACTED_BINARY="${TEMP_DIR}/croc"
    DEST_BINARY="/usr/local/bin/croc"
    DEB_FILE="${CROC_DIR}/croc_${VERSION}_${MAPPED_ARCH}.deb"

    # Use fpm to build the .deb package and specify output location
    fpm -s dir -t deb -n croc -v "$VERSION" -a "$MAPPED_ARCH" \
      -p "${DEB_FILE}" \
      --description "Easily and securely send things from one computer to another" \
      --license "MIT License" \
      --url "https://github.com/schollz/croc" \
      --maintainer "Amar Tukimin <amartukiminj@gmail.com>" \
      --prefix /usr/local/bin \
      --after-install <(echo "chmod +x ${DEST_BINARY}") \
      "$EXTRACTED_BINARY=croc"

    echo -e "deb package created: $DEB_FILE\n"
  fi
done

# Clean up temporary directory
rm -rf "$TEMP_DIR"
echo -e "temporary directory cleaned up."

echo "all linux-related files downloaded, processed, and packaged."
