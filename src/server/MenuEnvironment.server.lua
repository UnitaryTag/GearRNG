-- MenuEnvironment.server.lua
-- Configures the 3D menu scene: lighting, sky, atmosphere, and global ambiance.
-- Runs once on server startup before players join.
-- Uses current Roblox API (removed deprecated Lighting properties).

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local MenuEnvironment = {}

function MenuEnvironment:setup()
	-- ── Time ────────────────────────────────────────────────
	-- Warm golden-hour sunset — dramatic, diablo-esque
	Lighting.ClockTime = 18.5

	-- ── Atmosphere ──────────────────────────────────────────
	-- Fog adds depth to the outdoor scene
	Lighting.FogStart = 50
	Lighting.FogEnd = 300
	Lighting.FogColor = Color3.fromRGB(180, 140, 100)

	-- Atmosphere instance for sky haze
	local atmo = Instance.new("Atmosphere")
	atmo.Parent = Lighting

	-- ── Post-Processing ─────────────────────────────────────
	Lighting.Brightness = 2.5

	-- Bloom — subtle glow for magical loot vibe
	Lighting.Bloom.Intensity = 0.4
	Lighting.Bloom.Size = 24
	Lighting.Bloom.Threshold = 0.9

	-- Sun Rays
	Lighting.SunRays.Intensity = 0.15

	-- Depth of Field — blurs distant edges, cinematic look
	Lighting.DepthOfField.Enabled = true
	Lighting.DepthOfField.FarIntensity = 0.15
	Lighting.DepthOfField.FocusDistance = 30
	Lighting.DepthOfField.InFocusRadius = 20
	Lighting.DepthOfField.NearIntensity = 0.5

	-- Color Correction — warm fantasy tint
	local cc = Instance.new("ColorCorrectionEffect")
	cc.TintColor = Color3.fromRGB(255, 230, 200)
	cc.Parent = Lighting

	-- ── Ambient Music ───────────────────────────────────────
	local menuAmbience = Instance.new("Sound")
	menuAmbience.Name = "MenuAmbience"
	menuAmbience.SoundId = "rbxassetid://0" -- Placeholder — replace with ambient track
	menuAmbience.Looped = true
	menuAmbience.Volume = 0.3
	menuAmbience.Parent = SoundService

	print("[MenuEnvironment] Scene lighting and atmosphere configured.")
end

return MenuEnvironment
