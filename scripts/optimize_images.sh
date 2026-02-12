#!/usr/bin/env bash
# Generates WebP versions of all JPEG/PNG images in assets/images/
# Requires: brew install webp
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
ASSETS_DIR="$SCRIPT_DIR/../assets/images"

if ! command -v cwebp &> /dev/null; then
    echo "Error: cwebp not found. Install with: brew install webp"
    exit 1
fi

find "$ASSETS_DIR" -type f \( -name "*.jpg" -o -name "*.jpeg" -o -name "*.png" \) | while read -r img; do
    webp="${img%.*}.webp"
    echo "Converting: $img -> $webp"
    cwebp -q 80 "$img" -o "$webp"
done

echo "Done!"
