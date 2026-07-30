#!/usr/bin/env bash
set -euo pipefail

REPO="lovozeto/deck-patcher"
TMPFILE=$(mktemp /tmp/deck-patcher-XXXXXX.flatpak)
trap 'rm -f "$TMPFILE"' EXIT

echo "Deck Patcher installer"
echo "======================"

LATEST=$(curl -sSL "https://api.github.com/repos/$REPO/releases/latest" \
  | grep -o '"browser_download_url": *"[^"]*\.flatpak"' \
  | head -1 | cut -d'"' -f4)

if [ -z "$LATEST" ]; then
    echo "Error: no .flatpak release found at $REPO"
    exit 1
fi

echo "Downloading latest release..."
curl -sSL -o "$TMPFILE" "$LATEST"

echo "Installing..."
flatpak install --user --bundle --noninteractive "$TMPFILE"

echo ""
echo "Deck Patcher installed. Launch from the app menu or run:"
echo "  flatpak run com.github.lovozeto.DeckPatcher"
