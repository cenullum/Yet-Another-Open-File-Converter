#!/bin/bash

# Exit on any error
set -e

# Configuration
APP_NAME="Yet Another Open File Converter"
BINARY_NAME="Yet-Another-Open-File-Converter" # No spaces for the binary
BUILD_DIR="build_files"
DESKTOP_PATH="$HOME/Desktop"

echo "Starting build process for: $APP_NAME"

# Check for essential Qt dependencies on the build host
if ! dpkg -l | grep -q libxcb-cursor0 && ! find /usr/lib -name "libxcb-cursor*" | grep -q .; then
    echo "ERROR: libxcb-cursor0 is missing. This is required for packaging PySide6 apps."
    echo "Please install it: sudo apt install libxcb-cursor0"
    exit 1
fi

# Create build directory if it doesn't exist
mkdir -p "$BUILD_DIR"

# 1. Handle Python dependencies
USE_VENV=true
echo "Setting up virtual environment in $BUILD_DIR..."
if ! python3 -m venv "$BUILD_DIR/venv" 2>/dev/null; then
    echo "Notice: python3-venv is missing. Falling back to direct installation with --break-system-packages."
    USE_VENV=false
else
    echo "Virtual environment created successfully."
    source "$BUILD_DIR/venv/bin/activate"
fi

# 2. Install Build Dependencies
echo "Installing build dependencies..."
if [ "$USE_VENV" = true ]; then
    pip install --upgrade pip
    pip install PyInstaller PySide6
else
    pip3 install PyInstaller PySide6 --break-system-packages
fi

# 3. Build with PyInstaller
# We use absolute paths for --add-data to ensure PyInstaller finds them in root
echo "Running PyInstaller..."
ROOT_DIR=$(pwd)
PYINSTALLER_CMD="python3 -m PyInstaller"
[ "$USE_VENV" = true ] && PYINSTALLER_CMD="pyinstaller"

$PYINSTALLER_CMD --noconsole --onefile --clean \
    --name "$BINARY_NAME" \
    --workpath "$BUILD_DIR/work" \
    --specpath "$BUILD_DIR" \
    --distpath "$BUILD_DIR/dist" \
    --add-data "$ROOT_DIR/styles.py:." \
    --add-data "$ROOT_DIR/settings_manager.py:." \
    --add-data "$ROOT_DIR/converter_worker.py:." \
    --add-data "$ROOT_DIR/logger.py:." \
    --add-data "$ROOT_DIR/config.py:." \
    --add-data "$ROOT_DIR/codec_manager.py:." \
    main.py

# 4. Download linuxdeploy into build_files
echo "Downloading packaging tools..."
LINUXDEPLOY_BIN="$BUILD_DIR/linuxdeploy-x86_64.AppImage"
if [ ! -f "$LINUXDEPLOY_BIN" ]; then
    wget -q --show-progress -O "$LINUXDEPLOY_BIN" https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-x86_64.AppImage
    chmod +x "$LINUXDEPLOY_BIN"
fi

# 5. Prepare AppDir
echo "Structuring AppDir..."
APPDIR="$BUILD_DIR/AppDir"
rm -rf "$APPDIR"
mkdir -p "$APPDIR/usr/bin"
cp "$BUILD_DIR/dist/$BINARY_NAME" "$APPDIR/usr/bin/"

# 6. Generate Desktop file and handle Icon
# Desktop file goes into build_files
DESKTOP_FILE="$BUILD_DIR/$BINARY_NAME.desktop"
cat <<EOF > "$DESKTOP_FILE"
[Desktop Entry]
Type=Application
Name=$APP_NAME
Exec=$BINARY_NAME
Icon=icon
Categories=Utility;
EOF

# Use icon.png from root if exists, otherwise create placeholder in build_files
ICON_FILE="icon.png"
if [ ! -f "$ICON_FILE" ]; then
    echo "Notice: icon.png not found in root. Creating a placeholder."
    ICON_FILE="$BUILD_DIR/icon.png"
    touch "$ICON_FILE"
fi

# 7. Finalize AppImage
echo "Generating AppImage..."
# Using extract-and-run for compatibility
./"$LINUXDEPLOY_BIN" --appimage-extract-and-run --appdir "$APPDIR" -d "$DESKTOP_FILE" -i "$ICON_FILE" --output appimage

# AppImage is usually generated in the current directory by linuxdeploy
# We move it to Desktop and rename it properly
FINAL_APPIMAGE=$(ls *.AppImage | grep -v "linuxdeploy" | head -n 1)

if [ -n "$FINAL_APPIMAGE" ] && [ -d "$DESKTOP_PATH" ]; then
    TARGET_NAME="${APP_NAME// /-}.AppImage"
    echo "Moving executable to Desktop as $TARGET_NAME..."
    mv "$FINAL_APPIMAGE" "$DESKTOP_PATH/$TARGET_NAME"
    echo "Success! Find your AppImage here: $DESKTOP_PATH/$TARGET_NAME"
else
    echo "Build complete. Output located in the current directory."
fi

# 8. Cleanup (Optional: keep build_files but remove PyInstaller artifacts)
echo "Build process finished. Permanent build files are in $BUILD_DIR/"
[ "$USE_VENV" = true ] && deactivate || true
