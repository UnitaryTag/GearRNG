#!/usr/bin/env python3
"""Deep workspace analysis via Studio MCP bridge."""
import urllib.request, json, time

def cmd(code, timeout=10):
    req = urllib.request.Request("http://localhost:9877/command")
    req.add_header("Content-Type", "application/json")
    resp = urllib.request.urlopen(req, data=json.dumps({"code": code}).encode(), timeout=5)
    result = json.loads(resp.read())
    cid = result.get("id")
    for i in range(timeout * 2):
        time.sleep(0.5)
        req = urllib.request.Request(f"http://localhost:9877/result?id={cid}")
        resp = urllib.request.urlopen(req, timeout=3)
        r = json.loads(resp.read())
        if "result" in r:
            return r["result"]
    return "timeout"

def explore(name, code):
    print(f"\n{'='*60}")
    print(f"  {name}")
    print(f"{'='*60}")
    print(cmd(code))

# ── Zones ──
explore("ZONES", """
local z = workspace.Zones
local out = {}
for _, child in ipairs(z:GetChildren()) do
    local parts = {}
    for _, p in ipairs(child:GetChildren()) do
        if p:IsA("BasePart") then
            table.insert(parts, p.Name)
        end
    end
    table.insert(out, child.Name .. " (" .. child.ClassName .. "): " .. #child:GetChildren() .. " children, parts: " .. table.concat(parts, ", "))
end
return table.concat(out, "\\n")
""")

# ── Map ──
explore("MAP", """
local m = workspace.Map
local out = {}
for _, child in ipairs(m:GetChildren()) do
    local info = child.Name .. " (" .. child.ClassName .. ")"
    if child:IsA("BasePart") then
        info = info .. string.format(" at(%d,%d,%d) size(%d,%d,%d) mat=%s", child.Position.X, child.Position.Y, child.Position.Z, child.Size.X, child.Size.Y, child.Size.Z, child.Material.Name)
    elseif child:IsA("Model") or child:IsA("Folder") then
        info = info .. ": " .. #child:GetChildren() .. " children"
    end
    table.insert(out, info)
end
return table.concat(out, "\\n")
""")

# ── Shops ──
explore("SHOPS", """
local s = workspace.Shops
local out = {}
for _, child in ipairs(s:GetChildren()) do
    local names = {}
    for _, c in ipairs(child:GetChildren()) do
        table.insert(names, c.Name .. "(" .. c.ClassName .. ")")
    end
    table.insert(out, child.Name .. " (" .. child.ClassName .. ") children=[" .. table.concat(names, ", ") .. "]")
end
return table.concat(out, "\\n")
""")

# ── Plots ──
explore("PLOTS", """
local p = workspace.Plots
local out = {}
for _, child in ipairs(p:GetChildren()) do
    local names = {}
    for _, c in ipairs(child:GetChildren()) do
        table.insert(names, c.Name .. "(" .. c.ClassName .. ")")
    end
    table.insert(out, child.Name .. " (" .. child.ClassName .. ") children=[" .. table.concat(names, ", ") .. "]")
end
if #out == 0 then return "(empty)" end
return table.concat(out, "\\n")
""")

# ── LimitedBuy ──
explore("LIMITEDBUY", """
local lb = workspace.LimitedBuy
local out = {}
for _, child in ipairs(lb:GetChildren()) do
    local names = {}
    for _, c in ipairs(child:GetChildren()) do
        table.insert(names, c.Name .. "(" .. c.ClassName .. ")")
    end
    table.insert(out, child.Name .. " (" .. child.ClassName .. ") children=[" .. table.concat(names, ", ") .. "]")
end
return table.concat(out, "\\n")
""")

# ── Next_Zone ──
explore("NEXT_ZONE", """
local nz = workspace.Next_Zone
local out = {}
for _, child in ipairs(nz:GetChildren()) do
    if child:IsA("BasePart") then
        table.insert(out, string.format("%s (%s) at(%d,%d,%d) size(%d,%d,%d)", child.Name, child.ClassName, child.Position.X, child.Position.Y, child.Position.Z, child.Size.X, child.Size.Y, child.Size.Z))
    else
        table.insert(out, child.Name .. " (" .. child.ClassName .. "): " .. #child:GetChildren() .. " children")
    end
end
return table.concat(out, "\\n")
""")

# ── Border ──
explore("BORDER", """
local b = workspace.Border
local out = {}
for _, child in ipairs(b:GetChildren()) do
    if child:IsA("BasePart") then
        table.insert(out, string.format("%s (%s) at(%d,%d,%d) size(%d,%d,%d)", child.Name, child.ClassName, child.Position.X, child.Position.Y, child.Position.Z, child.Size.X, child.Size.Y, child.Size.Z))
    else
        table.insert(out, child.Name .. " (" .. child.ClassName .. "): " .. #child:GetChildren() .. " children")
    end
end
return table.concat(out, "\\n")
""")

# ── DailyRewards ──
explore("DAILYREWARDS", """
local dr = workspace.DailyRewards
local out = {}
for _, child in ipairs(dr:GetChildren()) do
    if child:IsA("BasePart") then
        table.insert(out, string.format("%s (%s) at(%d,%d,%d)", child.Name, child.ClassName, child.Position.X, child.Position.Y, child.Position.Z))
    else
        table.insert(out, child.Name .. " (" .. child.ClassName .. "): " .. #child:GetChildren() .. " children")
    end
end
return table.concat(out, "\\n")
""")

# ── UI Summary ──
explore("UI (ReplicatedStorage)", """
local rs = game:GetService("ReplicatedStorage")
local out = {}
local function listUI(parent, indent)
    for _, child in ipairs(parent:GetChildren()) do
        if child.Name:find("UI") or child.Name:find("Gui") or child:IsA("ScreenGui") or child:IsA("SurfaceGui") or child:IsA("BillboardGui") then
            table.insert(out, indent .. child.Name .. " (" .. child.ClassName .. ")")
        end
        if child:IsA("Folder") or child:IsA("Model") then
            listUI(child, indent .. "  ")
        end
    end
end
listUI(rs, "")
if #out == 0 then return "(no UI found in ReplicatedStorage)" end
return table.concat(out, "\\n")
""")

# ── ServerStorage assets ──
explore("SERVER STORAGE (Brainrots & Assets)", """
local ss = game:GetService("ServerStorage")
local out = {}
for _, child in ipairs(ss:GetChildren()) do
    table.insert(out, child.Name .. " (" .. child.ClassName .. "): " .. #child:GetChildren() .. " children")
end
return table.concat(out, "\\n")
""")

print("\n\n✅ Analysis complete!")
