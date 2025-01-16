#!/bin/bash

set -e

# Base directory where the package folders are located
BASE_DIR="$(dirname "$0")/../"

# Path to the updated.txt file
UPDATES_FILE="$BASE_DIR/updates.txt"

# Version file at the root directory
VERSION_FILE="$BASE_DIR/versions.txt"

# Check if updated.txt exists and read the list of updated packages
if [[ ! -f "$UPDATES_FILE" ]]; then
  echo "Error: updated.txt file not found. No updates to process."
  exit 1
fi

# Read updated packages from updated.txt
UPDATES_PACKAGES=($(cat "$UPDATES_FILE"))

if [[ ${#UPDATES_PACKAGES[@]} -eq 0 ]]; then
  echo "No packages listed in updated.txt. Nothing to update."
  exit 0
fi

# Loop through updated packages and run their download.sh scripts
echo "Running download scripts for updated packages..."
for PACKAGE in "${UPDATES_PACKAGES[@]}"; do
    SCRIPT_PATH="$BASE_DIR/packages/$PACKAGE/scripts/download.sh"

    echo
    if [[ -x "$SCRIPT_PATH" ]]; then
        echo "Running download.sh for $PACKAGE..."
        bash "$SCRIPT_PATH"
    else
        echo "Error: download.sh for $PACKAGE is not executable or not found."
    fi
done

# Function to add packages to aptly
add_to_aptly() {
  local pkg=$1
  echo "Adding $pkg packages to aptly repository..."
  aptly repo add apt "$BASE_DIR/packages/$pkg/data"
}

# Check if the Aptly repo is already published
is_repo_published() {
  aptly publish list | grep -q "filesystem:repo:apt"
}

# Update aptly repo with updated packages
echo "Adding updated packages to aptly repository..."
updated=false
for PACKAGE in "${UPDATES_PACKAGES[@]}"; do
  DATA_DIR="$BASE_DIR/packages/$PACKAGE/data"

  if [[ -d "$DATA_DIR" ]]; then
    add_to_aptly "$PACKAGE"
    updated=true

    # Clear the data folder to save space
    echo "Clearing data folder for $PACKAGE..."
    rm -rf "$DATA_DIR"/* || {
      echo "Warning: Failed to clear data folder for $PACKAGE."
    }
  else
    echo "No data directory found for $PACKAGE. Skipping..."
  fi
done

# Publish updates if any package was added
if $updated; then
  if is_repo_published; then
    echo "Repository already published. Updating published repository..."
    aptly publish update stable filesystem:repo:apt
  else
    echo "Publishing new repository..."
    aptly publish repo apt filesystem:repo:apt
  fi
  echo "Repository updated and published."
else
  echo "No updates were found. Repository not modified."
fi

# Clear updated.txt after processing
echo "Clearing updated.txt..."
> "$UPDATES_FILE"

echo "Process completed successfully."
