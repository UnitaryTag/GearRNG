-- MenuEnvironment.server.lua
-- Configures the 3D menu scene: lighting, sky, atmosphere, and global ambiance.
-- Runs once on server startup before players join.

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local MenuEnvironment = {}

function MenuEnvironment:setup()
	-- ── Time & Sky ──────────────────────────────────────────
	-- Warm golden-hour sunset lighting — dramatic, diablo-esque
	Lighting.ClockTime = 18.5 -- ~6:30 PM golden hour
	Lighting.GeographicLatitude = 35

	-- Disable dynamic clouds for a stylized look
	Lighting.OutdoorAmbient = Color3.fromRGB(80, 60, 50)
	Lighting.OutdoorDiffuse = Color3.fromRGB(200, 180, 140)
	Lighting.Ambient = Color3.fromRGB(60, 50, 55)

	-- ── Atmosphere ──────────────────────────────────────────
	Lighting.FogStart = 50
	Lighting.FogEnd = 300
	Lighting.FogColor = Color3.fromRGB(180, 140, 100)

	-- ── Post-Processing ─────────────────────────────────────
	Lighting.Brightness = 2.5
	Lighting.Contrast = 0.55
	Lighting.Saturation = 0.35
	Lighting.ExposureCompensation = 0.3

	-- ── Bloom (subtle glow for magical loot vibe) ──────────
	Lighting.Bloom.Intensity = 0.4
	Lighting.Bloom.Size = 24
	Lighting.Bloom.Threshold = 0.9

	-- ── Sun Rays ───────────────────────────────────────────
	Lighting.SunRays.Intensity = 0.15
	Lighting.SunRays.Spread = 0.5

	-- ── Depth of Field ─────────────────────────────────────
	Lighting.DepthOfField.Enabled = true
	Lighting.DepthOfField.FarIntensity = 0.15
	Lighting.DepthOfField.FocusDistance = 30
	Lighting.DepthOfField.InFocusRadius = 20
	Lighting.DepthOfField.NearIntensity = 0.5

	-- ── Color Correction ───────────────────────────────────
	-- Slight warm tint for fantasy atmosphere
	Lighting.ColorShift_TintColor = Color3.fromRGB(255, 230, 200)
	Lighting.ColorShift_TintAmount = 0.15

	-- ── Ambient Music ──────────────────────────────────────
	local menuAmbience = Instance.new("Sound")
	menuAmbience.Name = "MenuAmbience"
	menuAmbience.SoundId = "rbxassetid://0" -- Placeholder — replace with ambient track
	menuAmbience.Looped = true
	menuAmbience.Volume = 0.3
	menuAmbience.Parent = SoundService

	print("[MenuEnvironment] Scene lighting and atmosphere configured.")
end

return MenuEnvironment
