#!/bin/bash
# Check if makelove is installed
if ! command -v makelove &> /dev/null; then
    echo "makelove could not be found. Please install it (e.g., 'pip install makelove')."
    exit 1
fi

echo "Building game..."
makelove

echo "Build complete! Check the 'out/' directory."
