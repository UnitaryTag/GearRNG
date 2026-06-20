import urllib.request, json, time

def cmd(code):
    req = urllib.request.Request('http://localhost:9877/command')
    req.add_header('Content-Type', 'application/json')
    resp = urllib.request.urlopen(req, data=json.dumps({'code': code}).encode(), timeout=5)
    r = json.loads(resp.read())
    cid = r.get('id')
    for i in range(20):
        time.sleep(0.3)
        req = urllib.request.Request('http://localhost:9877/result?id=' + str(cid))
        resp = urllib.request.urlopen(req, timeout=3)
        rr = json.loads(resp.read())
        if 'result' in rr: return rr['result']
    return 'timeout'

# Check player's backpack for brainrot tools
print(cmd("""
local ps = game:GetService("Players")
local all = ps:GetPlayers()
if #all == 0 then return "No players in game" end
local plr = all[1]
local bp = plr:FindFirstChild("Backpack")
if not bp then return "No Backpack found" end
local tools = {}
for _, c in ipairs(bp:GetChildren()) do
    if c:IsA("Tool") then
        local bid = c:GetAttribute("BrainrotId")
        table.insert(tools, c.Name .. "(BrainrotId=" .. tostring(bid) .. ")")
    end
end
local char = plr.Character
local ctools = {}
if char then
    for _, c in ipairs(char:GetChildren()) do
        if c:IsA("Tool") then
            local bid = c:GetAttribute("BrainrotId")
            table.insert(ctools, c.Name .. "(BrainrotId=" .. tostring(bid) .. ")")
        end
    end
end
return "Backpack(" .. #bp:GetChildren() .. "): " .. table.concat(tools, ", ") .. " | Character tools: " .. table.concat(ctools, ", ")
"""))
