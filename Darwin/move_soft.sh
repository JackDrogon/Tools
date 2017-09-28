#!/bin/sh

DOWNLOAD_DIR="${HOME}/Downloads"
SOFT_DIR="${DOWNLOAD_DIR}/Soft"

mkdir -p $SOFT_DIR || exit 1
find $DOWNLOAD_DIR -name '*.dmg' -print0 | xargs -0 -I{} mv '{}' "$SOFT_DIR"
