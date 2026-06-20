#!/bin/bash
# Vinegar launcher — cleans mimalloc-crash triggers + reinstalls Rojo

VINEGAR="$HOME/.var/app/org.vinegarhq.Vinegar/data/vinegar"
PREFIX="$VINEGAR/prefixes/studio/drive_c/users/willi/AppData/Local/Roblox"
PERSIST="$VINEGAR/rojo-persist"

echo "🧹 Cleaning..."
flatpak kill org.vinegarhq.Vinegar 2>/dev/null
pkill -9 -f "wineserver|RobloxStudio|bwrap.*vinegar" 2>/dev/null
rm -rf "$PREFIX" "$VINEGAR/settings.reg"

mkdir -p "$PREFIX/Plugins"
cp "$PERSIST/Rojo.rbxm" "$PREFIX/Plugins/" 2>/dev/null && echo "✅ Rojo installed"

echo "🚀 Launching..."
flatpak run org.vinegarhq.Vinegar
