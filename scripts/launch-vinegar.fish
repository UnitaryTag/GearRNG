#!/usr/bin/env fish
# GearRNG Vinegar Launcher
# Workaround for kombucha Wine mimalloc page fault bug:
# Every launch must be a "first launch" — nuke prefixes+settings, keep kombucha+plugins

set VINEGAR_DATA ~/.var/app/org.vinegarhq.Vinegar/data/vinegar

echo "🧹 Cleaning Wine prefix..."
flatpak kill org.vinegarhq.Vinegar 2>/dev/null
pkill -9 -f "wineserver|RobloxStudio|bwrap.*vinegar" 2>/dev/null

rm -rf $VINEGAR_DATA/prefixes/ \
       $VINEGAR_DATA/settings.reg

# Keep versions (Studio binary) to save 500MB download
# If still broken, uncomment the next line:
# rm -rf $VINEGAR_DATA/versions/

echo "🚀 Launching Roblox Studio..."
flatpak run org.vinegarhq.Vinegar
