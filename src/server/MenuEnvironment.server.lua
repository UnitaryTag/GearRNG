-- MenuEnvironment.server.lua
-- Configures the 3D menu scene: lighting, sky, atmosphere, and global ambiance.
-- Runs once on server startup before players join.
-- Uses current Roblox API (removed deprecated Lighting properties).

local Lighting = game:GetService("Lighting")
local SoundService = game:GetService("SoundService")

local MenuEnvironment = {}

function MenuEnvironment:setup()
	-- ── Time ────────────────────────────────────────────────
	-- Golden sunrise — hopeful, warm morning light
	Lighting.ClockTime = 5.5

	-- ── Global Illumination ─────────────────────────────────
	Lighting.Brightness = 4.0
	Lighting.ExposureCompensation = 1.5  -- +3 stops, doubles effective brightness
	Lighting.OutdoorAmbient = Color3.fromRGB(200, 180, 150)
	Lighting.Ambient = Color3.fromRGB(80, 70, 60)
	Lighting.EnvironmentDiffuseScale = 0.3  -- dynamic sky-derived fill

	-- ── Atmosphere ──────────────────────────────────────────
	Lighting.FogStart = 80
	Lighting.FogEnd = 500
	Lighting.FogColor = Color3.fromRGB(240, 210, 170)

	-- Light haze for cinematic depth
	local atmo = Instance.new("Atmosphere")
	atmo.Density = 0.15
	atmo.Parent = Lighting

	-- ── Post-Processing ─────────────────────────────────────
	-- Bloom — subtle glow for magical loot vibe
	Lighting.Bloom.Intensity = 0.4
	Lighting.Bloom.Size = 24
	Lighting.Bloom.Threshold = 0.9

	-- Sun Rays
	Lighting.SunRays.Intensity = 0.15

	-- Depth of Field — cinematic focus
	Lighting.DepthOfField.Enabled = true
	Lighting.DepthOfField.FarIntensity = 0.15
	Lighting.DepthOfField.FocusDistance = 30
	Lighting.DepthOfField.InFocusRadius = 20
	Lighting.DepthOfField.NearIntensity = 0.5

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
