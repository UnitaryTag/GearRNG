# Roblox Studio MCP

AI vision & control over Roblox Studio via MCP.

## Architecture

```
Roblox Studio   --HTTP-->   Python Bridge   <--MCP stdio-->   AI (Copilot)
  (Plugin)      POST/GET    (port 9877)                      (VS Code)
```

## Setup

### 1. Install Python deps
```bash
cd studio-mcp
python3 -m venv .venv
.venv/bin/pip install -r requirements.txt mcp
```

### 2. Install Studio Plugin
Copy `plugin/init.lua` into Roblox Studio:

**Option A — Run as LocalScript (quick test):**
1. In Studio, open the Command Bar (View → Command Bar)
2. Paste the contents of `plugin/init.lua` and run it

**Option B — Install as Plugin (persistent):**
1. Create a folder `~/Documents/Roblox/Plugins/StudioMCP/`
2. Copy `plugin/init.lua` into it
3. Restart Studio

### 3. Start the Bridge
```bash
cd studio-mcp
.venv/bin/python bridge.py
```
The bridge runs both an HTTP server (port 9877) and MCP stdio.

### 4. Reload VS Code
`Ctrl+Shift+P` → "Reload Window"

## Tools

| Tool | Description |
|------|-------------|
| `studio_workspace_info` | Full workspace hierarchy snapshot |
| `studio_run_lua` | Execute Lua in Studio, get result |
| `studio_select_object` | Select object by name in Studio |
| `studio_status` | Check if plugin is connected |

## How It Works

1. **Studio Plugin** polls `GET /command` every 1s → executes code → `POST /result`
2. **Studio Plugin** posts workspace snapshot to `POST /workspace` every 3s
3. **AI** reads the latest snapshot via `studio_workspace_info`
4. **AI** queues commands via `studio_run_lua`
5. **Bridge** relays commands and results between AI and Studio
