#!/bin/bash

# Check for pip
if ! command -v pip3 &> /dev/null && ! command -v pip &> /dev/null; then
    echo "pip not found. Please install it first (e.g., sudo apt install python3-pip)"
    exit 1
fi

PIP_CMD="pip3"
if ! command -v pip3 &> /dev/null; then
    PIP_CMD="pip"
fi

echo "Installing dependencies from requirements.txt..."
$PIP_CMD install -r requirements.txt

# Check for ffmpeg and imagemagick
if ! command -v ffmpeg &> /dev/null; then
    echo "Warning: ffmpeg not found. Video conversion will not work."
fi

if ! command -v convert &> /dev/null; then
    echo "Warning: ImageMagick (convert) not found. Image conversion will not work."
fi

# Check for Qt dependencies (specifically for PySide6 6.5+)
if ! dpkg -l | grep -q libxcb-cursor0; then
    echo "Notice: libxcb-cursor0 is recommended for Qt6. You might need to install it: sudo apt install libxcb-cursor0"
fi

echo "Setup complete. You can run the app with: python3 main.py"
