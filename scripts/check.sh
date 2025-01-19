#!/bin/bash

set -e

# Define the path to versions.txt in the root folder
VERSION_FILE="$(dirname "$(dirname "$0")")/versions.txt"

# List of packages and their GitHub repositories
declare -A packages=(
  ["restic"]="https://api.github.com/repos/restic/restic/releases/latest"
  ["runitor"]="https://api.github.com/repos/bdd/runitor/releases/latest"
  ["croc"]="https://api.github.com/repos/schollz/croc/releases/latest"
  ["regclient"]="https://api.github.com/repos/regclient/regclient/releases/latest"
  ["wgcf"]="https://api.github.com/repos/ViRb3/wgcf/releases/latest"
  ["yt-dlp"]="https://api.github.com/repos/yt-dlp/yt-dlp/releases/latest"
)

# Read current versions into an associative array
declare -A current_versions
while IFS='=' read -r pkg ver; do
  current_versions[$pkg]=$ver
done < "$VERSION_FILE"

updated=false

# Check updates for each package
for pkg in "${!packages[@]}"; do
  latest_version=$(curl --silent "${packages[$pkg]}" | jq -r '.tag_name' | sed 's/^v//') # Remove 'v' prefix
  if [[ "$latest_version" != "${current_versions[$pkg]}" ]]; then
    echo "Update available for $pkg: ${current_versions[$pkg]} -> $latest_version"
    echo "$pkg" >> updates.txt
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
