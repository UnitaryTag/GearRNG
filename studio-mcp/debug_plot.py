#!/usr/bin/env python3
"""
Studio MCP HTTP Client — runs Lua in Studio via HTTP and gets results back.
No MCP stdio needed — works with the existing bridge on port 9877.
"""

import requests
import json
import time
import sys

BRIDGE = "http://localhost:9877"

def run_lua(code: str, timeout: float = 8.0) -> str:
    """Queue Lua code in Studio and wait for the result."""
    # Queue the command
    resp = requests.post(f"{BRIDGE}/command", json={"code": code}, timeout=5)
    data = resp.json()
    cid = data.get("id")
    if not cid:
        return f"Error: {data}"

    # Poll for result
    deadline = time.time() + timeout
    while time.time() < deadline:
        resp = requests.get(f"{BRIDGE}/result", params={"id": cid}, timeout=5)
        data = resp.json()
        if "result" in data:
            return data["result"]
        if data.get("status") != "waiting":
            time.sleep(0.1)
            continue
        time.sleep(0.1)

    return "Error: Command timed out (Studio not responding)"

def get_workspace():
    """Get the latest workspace snapshot."""
    resp = requests.get(f"{BRIDGE}/workspace", timeout=5)
    return resp.json()

def status():
    """Check bridge status."""
    resp = requests.get(f"{BRIDGE}/status", timeout=5)
    return resp.json()

if __name__ == "__main__":
    if len(sys.argv) > 1:
        code = " ".join(sys.argv[1:])
        print(run_lua(code))
    else:
        s = status()
        ws = get_workspace()
        print(f"Bridge: {s}")
        print(f"Workspace: {ws.get('TotalDescendants', 0)} descendants")
