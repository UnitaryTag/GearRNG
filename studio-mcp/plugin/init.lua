-- Roblox Studio MCP Plugin v2 (lightweight snapshot)
-- =====================================================
-- Communicates with the Python bridge server via HTTP.
-- Polls for AI commands, executes them, reports workspace state.
--
-- Install: Place this in your Studio Plugins folder, or
-- run as a LocalScript in Studio's command bar for testing.

local BRIDGE_URL = "http://localhost:9877"
local WORKSPACE_POLL_INTERVAL = 5  -- seconds between workspace snapshots
local COMMAND_POLL_INTERVAL = 0.2  -- seconds between command checks

local HttpService = game:GetService("HttpService")
local Selection = game:GetService("Selection")
local RunService = game:GetService("RunService")

-- Only run in Studio
if not RunService:IsStudio() then
	return
end

-- ── Workspace Snapshot ───────────────────────────────────────────

local function getWorkspaceSnapshot()
	local totalSerialized = 0
	local MAX_TOTAL = 500  -- Hard cap on total objects serialized

	local function serializeObject(obj, depth, maxDepth)
		totalSerialized = totalSerialized + 1
		if totalSerialized > MAX_TOTAL then
			return nil  -- Stop serializing, snapshot full
		end
		if depth > maxDepth then
			return {Name = obj.Name, ClassName = obj.ClassName, _truncated = true}
		end

		local data: any = {
			Name = obj.Name,
			ClassName = obj.ClassName,
		}

		if obj:IsA("BasePart") then
			data.Position = {math.round(obj.Position.X), math.round(obj.Position.Y), math.round(obj.Position.Z)}
			data.Size = {math.round(obj.Size.X), math.round(obj.Size.Y), math.round(obj.Size.Z)}
		end

		-- Children — limit to 20 per level to keep snapshots small
		local success, children = pcall(function() return obj:GetChildren() end)
		if success and children then
			local childData = {}
			local count = 0
			for _, child in children do
				if count >= 20 then break end
				local serialized = serializeObject(child, depth + 1, maxDepth)
				if serialized then
					table.insert(childData, serialized)
					count = count + 1
				end
			end
			if #childData > 0 then
				data.Children = childData
			end
			if #children > 20 then
				data._moreChildren = #children - 20
			end
		end

		return data
	end

	-- Workspace: shallow detail (depth 2)
	local wsData = serializeObject(game.Workspace, 0, 2)

	-- Other services: name + child count only (no recursive detail)
	local serviceList = {}
	for _, svcName in ipairs({
		"ReplicatedStorage", "ReplicatedFirst", "ServerScriptService",
		"ServerStorage", "StarterPlayer", "StarterGui",
		"Lighting", "SoundService",
	}) do
		local svc = game:GetService(svcName)
		local success, children = pcall(function() return svc:GetChildren() end)
		local childCount = success and #children or 0
		table.insert(serviceList, {Name = svcName, ClassName = svc.ClassName, ChildCount = childCount})
	end

	return {
		Workspace = wsData,
		Services = serviceList,
		TotalDescendants = #game:GetDescendants(),
	}
end

-- ── HTTP Communication ──────────────────────────────────────────

local function postJSON(endpoint, data)
	local success, result = pcall(function()
		local body = HttpService:JSONEncode(data)
		local response = HttpService:PostAsync(
			BRIDGE_URL .. endpoint,
			body,
			Enum.HttpContentType.ApplicationJson,
			false
		)
		return HttpService:JSONDecode(response)
	end)
	if not success then
		warn("[StudioMCP] HTTP error:", result)
		return nil
	end
	return result
end

local function getJSON(endpoint)
	local success, result = pcall(function()
		local response = HttpService:GetAsync(BRIDGE_URL .. endpoint)
		return HttpService:JSONDecode(response)
	end)
	if not success then
		return nil
	end
	return result
end

-- ── Command Execution ───────────────────────────────────────────

local function executeCommand(code)
	local fn, err = loadstring(code)
	if not fn then
		return "Syntax error: " .. tostring(err)
	end

	local success, result = pcall(fn)
	if success then
		if result == nil then
			return "Command executed (no return value)"
		else
			return tostring(result)
		end
	else
		return "Error: " .. tostring(result)
	end
end

-- ── Main Loop ───────────────────────────────────────────────────

local workspaceTimer = 0
local failCount = 0
local MAX_FAIL_BACKOFF = 5  -- seconds between retries when bridge is down

print("[StudioMCP] v2 Plugin loaded, bridge: " .. BRIDGE_URL)

-- Verify bridge is reachable
local status = getJSON("/status")
if status then
	print("[StudioMCP] Bridge connected:", HttpService:JSONEncode(status))
else
	warn("[StudioMCP] Bridge not reachable at " .. BRIDGE_URL .. ". Start bridge.py first.")
end

while true do
	local ok, err = pcall(function()
		-- Poll for AI commands (skip if bridge was failing)
		if failCount < 3 then
			local cmd = getJSON("/command")
			if cmd and cmd.code then
				failCount = 0
				print("[StudioMCP] Executing command #" .. tostring(cmd.id))
				local result = executeCommand(cmd.code)
				postJSON("/result", {id = cmd.id, result = result})
				print("[StudioMCP] Result: " .. result)
			end
		end

		-- Send workspace snapshot periodically (skip if bridge failing)
		workspaceTimer = workspaceTimer + COMMAND_POLL_INTERVAL
		if workspaceTimer >= WORKSPACE_POLL_INTERVAL and failCount < 3 then
			workspaceTimer = 0
			local snapshot = getWorkspaceSnapshot()
			if snapshot then
				local json = HttpService:JSONEncode(snapshot)
				if #json < 900000 then  -- stay under 1MB limit
					postJSON("/workspace", snapshot)
				end
			end
		end
	end)

	if not ok then
		failCount = failCount + 1
		local backoff = math.min(failCount, MAX_FAIL_BACKOFF)
		warn("[StudioMCP] Loop error (fail #" .. failCount .. "), backing off " .. backoff .. "s:", err)
		task.wait(backoff)
	else
		failCount = math.max(0, failCount - 1)
		task.wait(COMMAND_POLL_INTERVAL)
	end
end
