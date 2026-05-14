#!/usr/bin/env bash
set -euo pipefail

ICNS_PATH="/System/Applications/Messages.app/Contents/Resources/AppIcon.icns"
OUT_DIR="$(dirname "$0")/Public/icons"

if [[ ! -f "$ICNS_PATH" ]]; then
  echo "Error: Icon not found at $ICNS_PATH" >&2
  exit 1
fi

TMPDIR=$(mktemp -d)
trap 'rm -rf "$TMPDIR"' EXIT

echo "Extracting icons from $ICNS_PATH..."

iconutil -c iconset "$ICNS_PATH" -o "$TMPDIR/AppIcon.iconset"

# Prefer 512x512; fall back to largest available
SRC="$TMPDIR/AppIcon.iconset/icon_512x512.png"
if [[ ! -f "$SRC" ]]; then
  SRC=$(ls "$TMPDIR/AppIcon.iconset/"*.png | grep -v '@' | sort -t_ -k2 -rn | head -1)
fi

sips -s format png -z 512 512 "$SRC" --out "$OUT_DIR/icon-512.png" >/dev/null
echo "Wrote $OUT_DIR/icon-512.png"

sips -s format png -z 192 192 "$SRC" --out "$OUT_DIR/icon-192.png" >/dev/null
echo "Wrote $OUT_DIR/icon-192.png"
