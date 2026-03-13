#!/bin/bash
SRC="$(dirname "$0")/Gargul_History"
DEST="/c/Games/World of Warcraft/_anniversary_/Interface/AddOns/Gargul_History"

rm -rf "$DEST"
cp -r "$SRC" "$DEST"
echo "Deployed Gargul_History to $DEST"
