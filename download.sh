#!/bin/bash

# Base directory where the package folders are located
BASE_DIR=$(dirname "$0")

# List of package directories
PACKAGES=(croc regclient restic runitor wgcf)

# Loop through each package and run its download.sh script
for PACKAGE in "${PACKAGES[@]}"; do
    SCRIPT_PATH="$BASE_DIR/$PACKAGE/scripts/download.sh"

    echo
    if [[ -x "$SCRIPT_PATH" ]]; then
        echo "Running download.sh for $PACKAGE..."
        bash "$SCRIPT_PATH"
    else
        echo "Error: download.sh for $PACKAGE is not executable or not found."
    fi
done
