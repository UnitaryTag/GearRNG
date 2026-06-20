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

print(cmd("""
local rs = game:GetService("ReplicatedStorage")
local cui = rs:FindFirstChild("ClientUI")
if cui then
    local out = {}
    for _, c in ipairs(cui:GetChildren()) do
        table.insert(out, c.Name .. "(" .. c.ClassName .. ")")
    end
    return "ClientUI has " .. #cui:GetChildren() .. " items: " .. table.concat(out, ", ")
else
    return "ClientUI folder NOT in ReplicatedStorage"
end
"""))
