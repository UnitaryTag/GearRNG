-- GrassWindSystem.client.lua
-- LocalScript — animates grass tufts with a gentle wind sway effect.
-- Uses sine wave oscillation on the X/Z rotation of each grass tuft.
-- Runs entirely on the client for performance.

local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")

local GrassWindSystem = {}

-- ── Configuration ────────────────────────────────────────────
local WIND_CONFIG = {
	BaseFrequency = 0.6, -- Base oscillation speed
	BaseAmplitude = 0.08, -- Base sway amount (radians)
	VariationScale = 0.4, -- Random variation per tuft (0-1)
	HeightFalloff = 0.7, -- Taller grass sways more
	WaveOffset = 2.0, -- Phase offset between nearby tufts for wave effect
	ScanInterval = 2.0, -- How often to rescan for new grass (seconds)
}

-- ── State ─────────────────────────────────────────────────────
local grassTufts = {} -- {instance, baseRotation, phaseOffset, amplitude}
local isActive = false
local elapsedTime = 0
local lastScanTime = 0

-- ── Grass Detection ──────────────────────────────────────────
local function isGrassInstance(instance)
	-- Detect grass by name pattern: "Grass_" or "GrassTuft"
	if instance:IsA("BasePart") then
		local name = instance.Name
		return name:find("Grass") == 1 or name:find("GrassTuft") == 1
	end
	return false
end

local function scanForGrass()
	local newTufts = {}
	local seen = {}

	for _, obj in ipairs(Workspace:GetDescendants()) do
		if isGrassInstance(obj) and not seen[obj] then
			seen[obj] = true
			local phaseOffset = math.random() * math.pi * 2
			local amplitude = WIND_CONFIG.BaseAmplitude * (0.5 + math.random() * WIND_CONFIG.VariationScale)

			table.insert(newTufts, {
				instance = obj,
				baseRotation = obj.Orientation, -- Store original orientation
				phaseOffset = phaseOffset,
				amplitude = amplitude,
			})
		end
	end

	grassTufts = newTufts
	print("[GrassWindSystem] Found " .. #grassTufts .. " grass tufts.")
end

-- ── Animation Loop ───────────────────────────────────────────
local function onRenderStep(deltaTime)
	if not isActive then return end

	elapsedTime += deltaTime

	-- Periodic rescan for new grass
	if elapsedTime - lastScanTime > WIND_CONFIG.ScanInterval then
		lastScanTime = elapsedTime
		scanForGrass()
	end

	if #grassTufts == 0 then return end

	local baseT = elapsedTime * WIND_CONFIG.BaseFrequency

	for _, tuft in ipairs(grassTufts) do
		local instance = tuft.instance
		if instance and instance.Parent then
			local t = baseT + tuft.phaseOffset

			-- Main sway (side to side)
			local swayX = math.sin(t) * tuft.amplitude
			-- Secondary sway (front to back, half frequency)
			local swayZ = math.cos(t * 0.5) * tuft.amplitude * 0.5
			-- Height-based scaling
			local heightScale = 1 + (instance.Size.Y - 1) * WIND_CONFIG.HeightFalloff
			swayX *= heightScale
			swayZ *= heightScale

			-- Apply rotation relative to base orientation
			local base = tuft.baseRotation
			instance.Orientation = Vector3.new(
				base.X + math.deg(swayX),
				base.Y,
				base.Z + math.deg(swayZ)
			)
		end
	end
end

-- ── Public API ───────────────────────────────────────────────
function GrassWindSystem:start()
	if isActive then return end
	isActive = true
	elapsedTime = 0
	lastScanTime = -WIND_CONFIG.ScanInterval -- Force immediate scan

	-- Initial scan
	scanForGrass()

	-- Bind to render step (before camera so it's smooth)
	RunService:BindToRenderStep("GrassWind", Enum.RenderPriority.First.Value, onRenderStep)

	print("[GrassWindSystem] Wind animation started.")
end

function GrassWindSystem:stop()
	isActive = false
	RunService:UnbindFromRenderStep("GrassWind")
	grassTufts = {}
	print("[GrassWindSystem] Wind animation stopped.")
end

return GrassWindSystem
