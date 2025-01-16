#!/bin/bash

set -e

# Base directory where the package folders and scripts are located
BASE_DIR="$(dirname "$0")/../"

# Paths to required files
VERSION_FILE="$BASE_DIR/versions.txt"
UPDATES_FILE="$BASE_DIR/updates.txt"

# Paths to scripts
CHECK_SCRIPT="$BASE_DIR/scripts/check.sh"
UPDATE_SCRIPT="$BASE_DIR/scripts/update.sh"

# Ensure the necessary files and scripts exist
if [[ ! -f "$VERSION_FILE" ]]; then
  echo "Error: versions.txt not found at $VERSION_FILE."
  exit 1
fi

if [[ ! -f "$CHECK_SCRIPT" ]]; then
  echo "Error: check.sh script not found at $CHECK_SCRIPT."
  exit 1
fi

if [[ ! -f "$UPDATE_SCRIPT" ]]; then
  echo "Error: update.sh script not found at $UPDATE_SCRIPT."
  exit 1
fi

# Run the update check script
echo "Running check.sh to detect package updates..."
bash "$CHECK_SCRIPT"

# Check if there are any updates
if [[ -s "$UPDATED_FILE" ]]; then
  echo "Updates detected. Running update-repo.sh..."
  bash "$UPDATE_SCRIPT"
else
  echo "No updates detected. Skipping repository update."
fi

echo "Cron job completed successfully."
