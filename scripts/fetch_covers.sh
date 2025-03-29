#!/bin/bash

# Set base directory
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
IMG_DIR="$BASE_DIR/assets/images/books"

# Create images directory if it doesn't exist
mkdir -p "$IMG_DIR"

# Function to download book cover
download_cover() {
    local query="$1"
    local output="$2"
    local response
    
    # URL encode the query
    query=$(echo "$query" | sed 's/ /%20/g')
    
    # Get book info from Google Books API
    response=$(curl -s "https://www.googleapis.com/books/v1/volumes?q=$query")
    
    # Extract image URL using jq (fallback to large thumbnail if no extra large)
    image_url=$(echo "$response" | jq -r '.items[0].volumeInfo.imageLinks.extraLarge // .items[0].volumeInfo.imageLinks.thumbnail' 2>/dev/null)
    
    if [ "$image_url" != "null" ] && [ ! -z "$image_url" ]; then
        # Replace http with https
        image_url=$(echo "$image_url" | sed 's/^http:/https:/')
        # Remove zoom parameter for higher quality
        image_url=$(echo "$image_url" | sed 's/&zoom=1$//')
        
        echo "Downloading cover for: $query"
        curl -s "$image_url" -o "$output"
        echo "✓ Saved to $output"
    else
        echo "× Failed to find cover for: $query"
    fi
}

# Download covers for each book
download_cover "Dune Frank Herbert" "$IMG_DIR/dune.jpg"
download_cover "Hyperion Dan Simmons" "$IMG_DIR/hyperion.jpg"
download_cover "Lonesome Dove Larry McMurtry" "$IMG_DIR/lonesome-dove.jpg"
download_cover "Fool's Errand Robin Hobb" "$IMG_DIR/fools-errand.jpg"
download_cover "The Shadow Rising Robert Jordan" "$IMG_DIR/shadow-rising.jpg"

echo "Book covers download complete!"
