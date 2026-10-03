#!/bin/bash

# Builds the AppImage inside the oldest still-supported Ubuntu LTS so the
# bundled libpython/Qt only require an old glibc and run on most distros.
# Building directly on a rolling-release host links against its newer glibc.

set -e

BASE_IMAGE="ubuntu:22.04"
IMAGE_TAG="yaofc-appimage-builder:22.04"
ROOT_DIR=$(cd "$(dirname "$0")" && pwd)

if ! command -v docker &> /dev/null; then
    echo "ERROR: docker is required. Install it or run build_appimage.sh on an Ubuntu 22.04 machine."
    exit 1
fi

echo "Building builder image ($BASE_IMAGE)..."
docker build -t "$IMAGE_TAG" - <<EOF
FROM $BASE_IMAGE
ENV DEBIAN_FRONTEND=noninteractive
RUN apt-get update && apt-get install -y --no-install-recommends \
        python3 python3-venv python3-pip python3-dev \
        binutils file wget ca-certificates \
        libxcb-cursor0 libxkbcommon-x11-0 libxcb-icccm4 libxcb-image0 \
        libxcb-keysyms1 libxcb-randr0 libxcb-render-util0 libxcb-shape0 \
        libxcb-xinerama0 libxcb-xkb1 libegl1 libgl1 libfontconfig1 \
        libdbus-1-3 libglib2.0-0 \
    && rm -rf /var/lib/apt/lists/*
EOF

# Separate build dir so the host venv (built for the host's Python) isn't reused.
echo "Running build inside container..."
docker run --rm \
    --user "$(id -u):$(id -g)" \
    -e HOME=/tmp \
    -e BUILD_DIR=build_files_docker \
    -v "$ROOT_DIR:/src" \
    -w /src \
    "$IMAGE_TAG" \
    bash ./build_appimage.sh

echo "Done. AppImage is in: $ROOT_DIR"
