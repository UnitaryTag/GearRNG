#!/usr/bin/env python3
"""
Roblox Studio MCP Bridge
========================
Dual-purpose server:
  - HTTP API (port 9877) for Roblox Studio plugin to push/pull data
  - MCP stdio for AI to read workspace state and send commands

The Studio plugin POSTs workspace snapshots and polls for commands.
The AI reads snapshots and queues commands via MCP tools.
"""

import asyncio
import json
import os
import sys
import time
import threading
from typing import Any

# MCP imports
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from mcp.server import Server
from mcp.server.models import InitializationOptions
from mcp.server.stdio import stdio_server
from mcp.types import Tool, TextContent, ServerCapabilities

# ── Shared State (Studio ↔ AI) ───────────────────────────────────

_state_lock = asyncio.Lock()

class BridgeState:
    def __init__(self):
        self.workspace_json: dict | None = None  # Latest from Studio
        self.workspace_time: float = 0
        self.pending_command: dict | None = None  # AI → Studio
        self.command_result: dict | None = None   # Studio → AI
        self.command_id: int = 0

state = BridgeState()

# ── MCP Server ────────────────────────────────────────────────────

mcp = Server(
    name="studio-mcp",
    version="1.0.0",
    instructions="Roblox Studio MCP — view workspace, execute Lua in Studio.",
)

TOOLS = [
    Tool(
        name="studio_workspace_info",
        description="Get the latest snapshot of the Roblox Studio workspace — all objects, their types, positions, sizes. Updated when Studio plugin is connected.",
        inputSchema={"type": "object", "properties": {}, "required": []},
    ),
    Tool(
        name="studio_run_lua",
        description="Execute Lua code in Roblox Studio. The code runs in a plugin context with access to game, workspace, etc. Returns the result.",
        inputSchema={
            "type": "object",
            "properties": {
                "code": {"type": "string", "description": "Lua code to execute in Studio"},
                "timeout": {"type": "integer", "description": "Max seconds to wait for result (default 10)"},
            },
            "required": ["code"],
        },
    ),
    Tool(
        name="studio_select_object",
        description="Select an object in Roblox Studio by name or path.",
        inputSchema={
            "type": "object",
            "properties": {
                "name": {"type": "string", "description": "Object name to select"},
            },
            "required": ["name"],
        },
    ),
    Tool(
        name="studio_status",
        description="Check if the Roblox Studio plugin is connected and when the last workspace update was received.",
        inputSchema={"type": "object", "properties": {}, "required": []},
    ),
]


@mcp.list_tools()
async def list_tools() -> list[Tool]:
    return TOOLS


@mcp.call_tool()
async def call_tool(name: str, arguments: dict[str, Any]) -> list[TextContent]:
    async with _state_lock:
        if name == "studio_workspace_info":
            if state.workspace_json:
                return [TextContent(type="text", text=json.dumps(state.workspace_json, indent=2))]
            return [TextContent(type="text", text=json.dumps({"error": "No workspace data. Is the Studio plugin connected?"}))]

        elif name == "studio_status":
            connected = state.workspace_json is not None
            age = time.time() - state.workspace_time if state.workspace_time else 0
            return [TextContent(type="text", text=json.dumps({
                "connected": connected,
                "last_update_seconds_ago": round(age, 1),
                "has_pending_command": state.pending_command is not None,
            }))]

        elif name == "studio_run_lua":
            code = arguments.get("code", "")
            timeout = arguments.get("timeout", 10)
            state.command_id += 1
            cid = state.command_id
            state.pending_command = {"id": cid, "code": code}
            state.command_result = None

        elif name == "studio_select_object":
            name_arg = arguments.get("name", "")
            state.command_id += 1
            cid = state.command_id
            code = f'local obj = game:FindFirstChild("{name_arg}") or workspace:FindFirstChild("{name_arg}"); if obj then game:GetService("Selection"):Set({{obj}}); return "Selected: " .. obj:GetFullName() else return "Not found: {name_arg}" end'
            state.pending_command = {"id": cid, "code": code}
            state.command_result = None

    # Wait for result if a command was queued
    if name in ("studio_run_lua", "studio_select_object"):
        deadline = time.time() + timeout
        while time.time() < deadline:
            async with _state_lock:
                if state.command_result and state.command_result.get("id") == cid:
                    result = state.command_result.pop("result", "No result")
                    return [TextContent(type="text", text=str(result))]
            await asyncio.sleep(0.1)
        return [TextContent(type="text", text=json.dumps({"error": "Command timed out. Is Studio listening?"}))]

    return [TextContent(type="text", text=json.dumps({"error": f"Unknown tool: {name}"}))]


# ── HTTP Server (Studio Plugin ↔ Bridge) ─────────────────────────

from aiohttp import web

async def handle_post_workspace(request: web.Request) -> web.Response:
    """Studio plugin POSTs workspace snapshot here."""
    try:
        data = await request.json()
        async with _state_lock:
            state.workspace_json = data
            state.workspace_time = time.time()
        return web.json_response({"status": "ok"})
    except Exception as e:
        return web.json_response({"status": "error", "error": str(e)}, status=400)


async def handle_get_command(request: web.Request) -> web.Response:
    """Studio plugin polls this endpoint for pending AI commands."""
    async with _state_lock:
        if state.pending_command:
            cmd = state.pending_command
            state.pending_command = None
            return web.json_response(cmd)
    return web.json_response({"status": "no_command"})


async def handle_post_result(request: web.Request) -> web.Response:
    """Studio plugin POSTs command results here."""
    try:
        data = await request.json()
        async with _state_lock:
            state.command_result = data
        return web.json_response({"status": "ok"})
    except Exception as e:
        return web.json_response({"status": "error", "error": str(e)}, status=400)


async def handle_status(request: web.Request) -> web.Response:
    """Health check."""
    return web.json_response({"status": "running", "port": 9877})


async def handle_get_workspace(request: web.Request) -> web.Response:
    """AI queries this to get the latest workspace snapshot."""
    async with _state_lock:
        if state.workspace_json:
            return web.json_response(state.workspace_json)
        return web.json_response({"error": "No workspace data yet"}, status=404)


async def handle_post_command(request: web.Request) -> web.Response:
    """AI posts a command for Studio to execute."""
    try:
        data = await request.json()
        code = data.get("code", "")
        if not code:
            return web.json_response({"error": "code required"}, status=400)
        state.command_id += 1
        cid = state.command_id
        state.pending_command = {"id": cid, "code": code}
        state.command_result = None
        return web.json_response({"id": cid, "status": "queued"})
    except Exception as e:
        return web.json_response({"error": str(e)}, status=400)


async def handle_get_result(request: web.Request) -> web.Response:
    """AI polls this for the result of a queued command."""
    try:
        cid = int(request.query.get("id", "0"))
    except ValueError:
        return web.json_response({"error": "id required"}, status=400)

    async with _state_lock:
        if state.command_result and state.command_result.get("id") == cid:
            result = state.command_result
            state.command_result = None
            return web.json_response(result)
    return web.json_response({"status": "waiting"})


# ── Main ──────────────────────────────────────────────────────────

async def run_http_server():
    """Run the HTTP API server for Studio plugin communication."""
    app = web.Application()
    app.router.add_post("/workspace", handle_post_workspace)
    app.router.add_get("/workspace", handle_get_workspace)
    app.router.add_get("/command", handle_get_command)
    app.router.add_post("/command", handle_post_command)
    app.router.add_post("/result", handle_post_result)
    app.router.add_get("/result", handle_get_result)
    app.router.add_get("/status", handle_status)

    runner = web.AppRunner(app)
    await runner.setup()
    site = web.TCPSite(runner, "localhost", 9877)
    await site.start()
    print(f"[Studio MCP] HTTP bridge listening on http://localhost:9877", file=sys.stderr)
    print(f"[Studio MCP] Studio plugin should POST to /workspace, GET /command, POST /result", file=sys.stderr)


async def main():
    # Start HTTP server in background
    http_task = asyncio.create_task(run_http_server())

    # Start MCP stdio server if stdin is available (skip if running standalone)
    try:
        async with stdio_server() as (read_stream, write_stream):
            await mcp.run(
                read_stream,
                write_stream,
                InitializationOptions(
                    server_name="studio-mcp",
                    server_version="1.0.0",
                    capabilities=ServerCapabilities(),
                ),
            )
    except (OSError, Exception) as e:
        print(f"[Studio MCP] MCP stdio unavailable (HTTP-only mode): {e}", file=sys.stderr)
        # Keep running in HTTP-only mode
        await http_task


if __name__ == "__main__":
    asyncio.run(main())
