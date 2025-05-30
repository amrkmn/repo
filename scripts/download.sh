#!/bin/bash

# Base directory where the package folders are located
BASE_DIR="$(cd "$(dirname "$0")/../" && pwd)"
PACKAGES_DIR="$BASE_DIR/packages"

# Find all download.sh scripts in subdirectories
find "$PACKAGES_DIR" -type f -path '*/scripts/download.sh' | while read -r SCRIPT_PATH; do
    PACKAGE_NAME=$(basename "$(dirname "$(dirname "$SCRIPT_PATH")")")
    
    echo "Running download.sh for $PACKAGE_NAME..."
    
    if [[ -x "$SCRIPT_PATH" ]]; then
        bash "$SCRIPT_PATH"
    else
        echo "Error: $SCRIPT_PATH is not executable. Attempting to run with bash anyway..."
        bash "$SCRIPT_PATH"
    fi

    echo
done