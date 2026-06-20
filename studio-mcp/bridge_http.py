#!/usr/bin/env python3
"""Minimal HTTP bridge for Studio MCP plugin — no MCP stdio dependency."""
import asyncio, json, sys, time
from aiohttp import web

state = {
    "workspace_json": None,
    "workspace_time": 0,
    "pending_command": None,
    "command_result": None,
    "command_id": 0,
}

_lock = asyncio.Lock()

async def post_workspace(request):
    try:
        data = await request.json()
        async with _lock:
            state["workspace_json"] = data
            state["workspace_time"] = time.time()
        return web.json_response({"status": "ok"})
    except Exception as e:
        return web.json_response({"status": "error", "error": str(e)}, status=400)

async def get_command(request):
    async with _lock:
        if state["pending_command"]:
            cmd = state["pending_command"]
            state["pending_command"] = None
            return web.json_response(cmd)
    return web.json_response({"status": "no_command"})

async def post_result(request):
    try:
        data = await request.json()
        async with _lock:
            state["command_result"] = data
        return web.json_response({"status": "ok"})
    except Exception as e:
        return web.json_response({"status": "error", "error": str(e)}, status=400)

async def get_result(request):
    try:
        cid = int(request.query.get("id", "0"))
    except ValueError:
        return web.json_response({"error": "id required"}, status=400)
    async with _lock:
        if state["command_result"] and state["command_result"].get("id") == cid:
            result = state["command_result"]
            state["command_result"] = None
            return web.json_response(result)
    return web.json_response({"status": "waiting"})

async def post_command(request):
    try:
        data = await request.json()
        code = data.get("code", "")
        if not code:
            return web.json_response({"error": "code required"}, status=400)
        state["command_id"] += 1
        cid = state["command_id"]
        state["pending_command"] = {"id": cid, "code": code}
        state["command_result"] = None
        return web.json_response({"id": cid, "status": "queued"})
    except Exception as e:
        return web.json_response({"error": str(e)}, status=400)

async def get_workspace(request):
    async with _lock:
        if state["workspace_json"]:
            return web.json_response(state["workspace_json"])
    return web.json_response({"error": "No workspace data yet"}, status=404)

async def get_status(request):
    return web.json_response({"status": "running", "port": 9877})

app = web.Application()
app.router.add_post("/workspace", post_workspace)
app.router.add_get("/workspace", get_workspace)
app.router.add_get("/command", get_command)
app.router.add_post("/command", post_command)
app.router.add_post("/result", post_result)
app.router.add_get("/result", get_result)
app.router.add_get("/status", get_status)

print("[Studio MCP] HTTP bridge starting on http://localhost:9877", file=sys.stderr)
web.run_app(app, host="localhost", port=9877, print=None)
