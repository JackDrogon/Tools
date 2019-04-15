#!/bin/sh

EXPORT_FILE="$HOME/Tmp/ncdu-export.zst"

rm -f $EXPORT_FILE
ncdu -1xo- / | zstd -9 -o $EXPORT_FILE
