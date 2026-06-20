# Gear RNG — Roblox RNG Loot Simulator

## Setup
```bash
# Install tools (auto-installed by rokit)
rokit install

# Install Wally packages
wally install

# Generate Roblox type definitions
wally-package-types Packages/_types
```

## MCP Servers
- **studio-mcp**: HTTP bridge on `localhost:9877` — connect Roblox Studio plugin
- **blender-mcp**: WebSocket on `localhost:9876` — start Blender MCP addon first

## Project Structure
```
src/
├── client/          # LocalScripts, client modules
├── server/          # Scripts, server modules
├── shared/          # ModuleScripts (shared logic)
└── server-storage/  # Assets stored on server
Packages/            # Wally dependencies
```

## Building
```bash
rojo build -o build/gear-rng.rbxl
```
