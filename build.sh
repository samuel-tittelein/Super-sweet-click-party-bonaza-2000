#!/bin/bash
# Check if boon is installed
if ! command -v boon &> /dev/null; then
    echo "boon could not be found. Please install it (e.g., 'cargo install boon')."
    exit 1
fi

echo "Building game with boon..."
boon build . -t all

echo "Build complete! Check the 'out/' directory."
