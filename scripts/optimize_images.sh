#!/usr/bin/env bash
#
# Resize and convert images to WebP for the website.
#
# Usage:
#   scripts/optimize_images.sh [directory]
#
# Defaults to assets/images/ if no directory given.
# Requires: sips (macOS built-in), cwebp (brew install webp)
#
# What it does:
#   1. Finds all .jpeg/.jpg/.png files in the target directory
#   2. Resizes any image wider than MAX_WIDTH (default 1200px)
#   3. Converts to WebP at QUALITY (default 82)
#   4. Removes the original file
#
# Run this before committing new images.

set -euo pipefail

MAX_WIDTH=1200
QUALITY=82
TARGET_DIR="${1:-assets/images/}"

cd "$(git rev-parse --show-toplevel)"

if ! command -v cwebp &>/dev/null; then
  echo "Error: cwebp not found. Install with: brew install webp"
  exit 1
fi

find "$TARGET_DIR" -type f \( -iname '*.jpeg' -o -iname '*.jpg' -o -iname '*.png' \) | while read -r img; do
  # Get current width
  width=$(sips -g pixelWidth "$img" | awk '/pixelWidth/{print $2}')

  # Resize if wider than MAX_WIDTH
  if [ "$width" -gt "$MAX_WIDTH" ]; then
    sips --resampleWidth "$MAX_WIDTH" "$img" --out "$img" >/dev/null 2>&1
    echo "  resized: $(basename "$img") (${width}px -> ${MAX_WIDTH}px)"
  fi

  # Convert to WebP
  webp_path="${img%.*}.webp"
  cwebp -q "$QUALITY" "$img" -o "$webp_path" >/dev/null 2>&1

  # Report sizes
  orig_size=$(stat -f%z "$img")
  webp_size=$(stat -f%z "$webp_path")
  savings=$(( (orig_size - webp_size) * 100 / orig_size ))
  echo "  converted: $(basename "$img") -> $(basename "$webp_path") (${savings}% smaller)"

  # Remove original
  rm "$img"
done

echo ""
echo "Done. Update any .html/.md references from .jpeg/.jpg/.png to .webp"
