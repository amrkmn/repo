#!/bin/bash

set -e

# Define the path to versions.txt in the root folder
VERSION_FILE="$(dirname "$(dirname "$0")")/versions.txt"
UPDATES_FILE="$(dirname "$(dirname "$0")")/updates.txt"

# List of packages and their GitHub repositories
declare -A packages=(
  ["restic"]="https://ungh.cc/repos/restic/restic/releases/latest"
  ["runitor"]="https://ungh.cc/repos/bdd/runitor/releases/latest"
  ["croc"]="https://ungh.cc/repos/schollz/croc/releases/latest"
  ["regclient"]="https://ungh.cc/repos/regclient/regclient/releases/latest"
  ["wgcf"]="https://ungh.cc/repos/ViRb3/wgcf/releases/latest"
  ["yt-dlp"]="https://ungh.cc/repos/yt-dlp/yt-dlp/releases/latest"
)

# Read current versions into an associative array
declare -A current_versions
while IFS='=' read -r pkg ver; do
  current_versions[$pkg]=$ver
done < "$VERSION_FILE"

updated=false

# Check updates for each package
for pkg in "${!packages[@]}"; do
  latest_version=$(curl --silent "${packages[$pkg]}" | jq -r '.release.tag' | sed 's/^v//') # Remove 'v' prefix
  if [[ "$latest_version" != "${current_versions[$pkg]}" ]]; then
    echo "Update available for $pkg: ${current_versions[$pkg]} -> $latest_version"
    echo "$pkg" >> "$UPDATES_FILE"
    current_versions[$pkg]=$latest_version
    updated=true
  fi
done

# Update versions.txt if any package was updated
if $updated; then
  for pkg in "${!current_versions[@]}"; do
    echo "$pkg=${current_versions[$pkg]}"
  done > "$VERSION_FILE"
fi
