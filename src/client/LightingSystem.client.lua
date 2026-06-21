-- LightingSystem.client.lua
-- ModuleScript — dynamic day/night lighting cycle with smooth transitions.
-- Adapted from Realistic Dynamic Lighting V1.1 by Maiq_S.
--
-- Usage:
--   local LightingSystem = require(script.LightingSystem)   -- from sibling
--   LightingSystem.setTime(18)                              -- jump to golden hour
--
-- Requires post-processing children under Lighting (Bloom, Blur, etc.).
-- The system creates them automatically if missing.

local Lighting = game:GetService("Lighting")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")

-- ── Configuration ──────────────────────────────────────────────
local TWEEN_DURATION = 5    -- seconds for crossfade between presets
local CYCLE_MULTIPLIER = 1  -- 1 = real-time (24h cycle), 60 = 24min cycle

-- ── Lighting Presets ───────────────────────────────────────────
-- Each preset is a table of {InstanceName = {Property = Value}}.
-- "Lighting" key maps directly to the Lighting service.
-- "Clouds" key maps to Terrain.Clouds (created by Roblox).
-- All other keys are Lighting children (BloomEffect, Atmosphere, etc.).

local PRESETS = {}

PRESETS.Sunrise = {
	Lighting = {
		ClockTime = 7,
		Ambient = Color3.fromRGB(160, 140, 120),
		OutdoorAmbient = Color3.fromRGB(200, 170, 140),
		Brightness = 2.5,
		ExposureCompensation = 0.2,
		FogColor = Color3.fromRGB(220, 200, 170),
		FogStart = 0,
		FogEnd = 600,
		EnvironmentDiffuseScale = 0.8,
		EnvironmentSpecularScale = 0.6,
	},
	Atmosphere = {
		Density = 0.28,
		Offset = 0.15,
		Color = Color3.fromRGB(255, 210, 150),
		Glare = 0.2,
		Haze = 1.0,
		Decay = Color3.fromRGB(200, 160, 100),
	},
	Bloom = {
		Intensity = 0.35,
		Size = 18,
		Threshold = 0.85,
	},
	ColorCorrection = {
		Brightness = 0.05,
		Contrast = 0.05,
		Saturation = -0.05,
		TintColor = Color3.fromRGB(255, 240, 220),
	},
	SunRays = {
		Intensity = 0.15,
		Spread = 0.6,
	},
	DepthOfField = {
		FarIntensity = 0.05,
		NearIntensity = 0,
	},
	Blur = {
		Size = 0,
	},
	Clouds = {
		Cover = 0.25,
		Density = 0.35,
		Color = Color3.fromRGB(255, 230, 200),
	},
}

PRESETS.Day = {
	Lighting = {
		ClockTime = 12,
		Ambient = Color3.fromRGB(140, 145, 155),
		OutdoorAmbient = Color3.fromRGB(180, 185, 195),
		Brightness = 3.5,
		ExposureCompensation = 0.5,
		FogColor = Color3.fromRGB(190, 200, 220),
		FogStart = 0,
		FogEnd = 2000,
		EnvironmentDiffuseScale = 0.9,
		EnvironmentSpecularScale = 0.8,
	},
	Atmosphere = {
		Density = 0.22,
		Offset = 0.12,
		Color = Color3.fromRGB(200, 210, 230),
		Glare = 0.25,
		Haze = 0.6,
		Decay = Color3.fromRGB(180, 190, 210),
	},
	Bloom = {
		Intensity = 0.15,
		Size = 12,
		Threshold = 0.9,
	},
	ColorCorrection = {
		Brightness = 0.02,
		Contrast = 0.03,
		Saturation = 0.02,
		TintColor = Color3.fromRGB(255, 252, 248),
	},
	SunRays = {
		Intensity = 0.08,
		Spread = 0.5,
	},
	DepthOfField = {
		FarIntensity = 0.02,
		NearIntensity = 0,
	},
	Blur = {
		Size = 0,
	},
	Clouds = {
		Cover = 0.15,
		Density = 0.2,
		Color = Color3.fromRGB(255, 252, 245),
	},
}

PRESETS.AfternoonGoldenHour = {
	Lighting = {
		ClockTime = 17.75,
		Ambient = Color3.fromRGB(170, 130, 90),
		OutdoorAmbient = Color3.fromRGB(230, 160, 100),
		Brightness = 2.8,
		ExposureCompensation = 0.3,
		FogColor = Color3.fromRGB(240, 180, 100),
		FogStart = 0,
		FogEnd = 400,
		EnvironmentDiffuseScale = 0.85,
		EnvironmentSpecularScale = 0.75,
	},
	Atmosphere = {
		Density = 0.32,
		Offset = 0.18,
		Color = Color3.fromRGB(255, 170, 80),
		Glare = 0.35,
		Haze = 1.2,
		Decay = Color3.fromRGB(240, 150, 60),
	},
	Bloom = {
		Intensity = 0.5,
		Size = 24,
		Threshold = 0.7,
	},
	ColorCorrection = {
		Brightness = 0.03,
		Contrast = 0.08,
		Saturation = 0.1,
		TintColor = Color3.fromRGB(255, 220, 170),
	},
	SunRays = {
		Intensity = 0.25,
		Spread = 0.7,
	},
	DepthOfField = {
		FarIntensity = 0.08,
		NearIntensity = 0,
	},
	Blur = {
		Size = 0,
	},
	Clouds = {
		Cover = 0.2,
		Density = 0.3,
		Color = Color3.fromRGB(255, 200, 130),
	},
}

PRESETS.Sunset = {
	Lighting = {
		ClockTime = 19.25,
		Ambient = Color3.fromRGB(130, 80, 60),
		OutdoorAmbient = Color3.fromRGB(200, 100, 50),
		Brightness = 2.0,
		ExposureCompensation = 0.1,
		FogColor = Color3.fromRGB(220, 120, 40),
		FogStart = 0,
		FogEnd = 250,
		EnvironmentDiffuseScale = 0.75,
		EnvironmentSpecularScale = 0.65,
	},
	Atmosphere = {
		Density = 0.38,
		Offset = 0.22,
		Color = Color3.fromRGB(255, 100, 20),
		Glare = 0.45,
		Haze = 1.6,
		Decay = Color3.fromRGB(220, 80, 10),
	},
	Bloom = {
		Intensity = 0.65,
		Size = 32,
		Threshold = 0.6,
	},
	ColorCorrection = {
		Brightness = -0.02,
		Contrast = 0.12,
		Saturation = 0.15,
		TintColor = Color3.fromRGB(255, 180, 100),
	},
	SunRays = {
		Intensity = 0.3,
		Spread = 0.8,
	},
	DepthOfField = {
		FarIntensity = 0.12,
		NearIntensity = 0,
	},
	Blur = {
		Size = 0,
	},
	Clouds = {
		Cover = 0.18,
		Density = 0.28,
		Color = Color3.fromRGB(255, 140, 60),
	},
}

PRESETS.Twilight = {
	Lighting = {
		ClockTime = 21.5,
		Ambient = Color3.fromRGB(40, 45, 70),
		OutdoorAmbient = Color3.fromRGB(50, 55, 90),
		Brightness = 1.0,
		ExposureCompensation = -0.5,
		FogColor = Color3.fromRGB(30, 35, 60),
		FogStart = 0,
		FogEnd = 300,
		EnvironmentDiffuseScale = 0.5,
		EnvironmentSpecularScale = 0.3,
	},
	Atmosphere = {
		Density = 0.3,
		Offset = 0.2,
		Color = Color3.fromRGB(80, 60, 140),
		Glare = 0.15,
		Haze = 1.0,
		Decay = Color3.fromRGB(40, 30, 80),
	},
	Bloom = {
		Intensity = 0.2,
		Size = 14,
		Threshold = 0.8,
	},
	ColorCorrection = {
		Brightness = -0.1,
		Contrast = 0.1,
		Saturation = -0.05,
		TintColor = Color3.fromRGB(200, 200, 240),
	},
	SunRays = {
		Intensity = 0.05,
		Spread = 0.4,
	},
	DepthOfField = {
		FarIntensity = 0.1,
		NearIntensity = 0,
	},
	Blur = {
		Size = 0,
	},
	Clouds = {
		Cover = 0.3,
		Density = 0.4,
		Color = Color3.fromRGB(40, 45, 80),
	},
}

PRESETS.Night = {
	Lighting = {
		ClockTime = 0.5,
		Ambient = Color3.fromRGB(15, 18, 35),
		OutdoorAmbient = Color3.fromRGB(20, 22, 40),
		Brightness = 0.4,
		ExposureCompensation = -1.5,
		FogColor = Color3.fromRGB(8, 10, 20),
		FogStart = 0,
		FogEnd = 200,
		EnvironmentDiffuseScale = 0.2,
		EnvironmentSpecularScale = 0.1,
	},
	Atmosphere = {
		Density = 0.25,
		Offset = 0.18,
		Color = Color3.fromRGB(30, 35, 70),
		Glare = 0.05,
		Haze = 0.4,
		Decay = Color3.fromRGB(15, 18, 35),
	},
	Bloom = {
		Intensity = 0.05,
		Size = 8,
		Threshold = 0.95,
	},
	ColorCorrection = {
		Brightness = -0.2,
		Contrast = 0.2,
		Saturation = -0.15,
		TintColor = Color3.fromRGB(180, 190, 230),
	},
	SunRays = {
		Intensity = 0,
		Spread = 0.3,
	},
	DepthOfField = {
		FarIntensity = 0.15,
		NearIntensity = 0,
	},
	Blur = {
		Size = 0,
	},
	Clouds = {
		Cover = 0.4,
		Density = 0.5,
		Color = Color3.fromRGB(15, 18, 35),
	},
}

-- ── Effect Bootstrapping ───────────────────────────────────────
-- Defaults used when creating missing post-processing children.
local EFFECT_DEFAULTS = {
	Bloom = { ClassName = "BloomEffect", Intensity = 0, Size = 24, Threshold = 0.9 },
	Blur = { ClassName = "BlurEffect", Size = 0 },
	ColorCorrection = {
		ClassName = "ColorCorrectionEffect",
		Brightness = 0, Contrast = 0, Saturation = 0,
		TintColor = Color3.fromRGB(255, 255, 255),
	},
	DepthOfField = {
		ClassName = "DepthOfFieldEffect",
		FarIntensity = 0, NearIntensity = 0,
	},
	SunRays = { ClassName = "SunRaysEffect", Intensity = 0, Spread = 0.5 },
	Atmosphere = {
		ClassName = "Atmosphere",
		Density = 0.3, Offset = 0.15,
		Color = Color3.fromRGB(200, 200, 200),
		Glare = 0.25, Haze = 1.0,
		Decay = Color3.fromRGB(128, 128, 128),
	},
}

local function ensureEffects()
	for name, defaults in pairs(EFFECT_DEFAULTS) do
		if not Lighting:FindFirstChild(name) then
			local effect = Instance.new(defaults.ClassName)
			effect.Name = name
			-- Apply neutral defaults so the effect exists before first tween
			for prop, value in pairs(defaults) do
				if prop ~= "ClassName" and pcall(function() return effect[prop] end) then
					effect[prop] = value
				end
			end
			effect.Parent = Lighting
		end
	end
end

-- ── Tween Application ──────────────────────────────────────────
local function applyPreset(config)
	local tweenInfo = TweenInfo.new(
		TWEEN_DURATION,
		Enum.EasingStyle.Quad,
		Enum.EasingDirection.Out
	)

	for objectName, properties in pairs(config) do
		local instance

		if objectName == "Lighting" then
			instance = Lighting
		elseif objectName == "Clouds" then
			local terrain = workspace:FindFirstChild("Terrain")
			if terrain then
				instance = terrain:FindFirstChild("Clouds")
			end
		else
			instance = Lighting:FindFirstChild(objectName)
		end

		if instance then
			for propName, propValue in pairs(properties) do
				-- Skip ClockTime — we control that directly on the cycle
				if propName ~= "ClockTime" then
					local success = pcall(function()
						local tween = TweenService:Create(instance, tweenInfo, {
							[propName] = propValue,
						})
						tween:Play()
					end)
					if not success then
						-- Direct set as fallback for non-tweenable types
						pcall(function()
							instance[propName] = propValue
						end)
					end
				end
			end
		end
	end
end

-- ── Time → Preset Mapping ─────────────────────────────────────
local function getPresetForTime(clockTime: number)
	if clockTime >= 6 and clockTime <= 8 then
		return PRESETS.Sunrise
	elseif clockTime > 8 and clockTime <= 17 then
		return PRESETS.Day
	elseif clockTime > 17 and clockTime <= 18.5 then
		return PRESETS.AfternoonGoldenHour
	elseif clockTime > 18.5 and clockTime <= 20 then
		return PRESETS.Sunset
	elseif clockTime > 20 and clockTime <= 23 then
		return PRESETS.Twilight
	else
		return PRESETS.Night -- 23:00 to 06:00
	end
end

-- ── Core Cycle ─────────────────────────────────────────────────
local cycleEnabled = true
local lastAppliedPreset = nil

local function onClockTimeChanged()
	local newPreset = getPresetForTime(Lighting.ClockTime)
	if newPreset ~= lastAppliedPreset then
		lastAppliedPreset = newPreset
		applyPreset(newPreset)
	end
end

local function startCycle()
	ensureEffects()

	-- React to ClockTime changes (manual or automatic)
	Lighting:GetPropertyChangedSignal("ClockTime"):Connect(onClockTimeChanged)

	-- Trigger initial apply — bump ClockTime so the signal fires
	local saved = Lighting.ClockTime
	Lighting.ClockTime = (saved + 1) % 24
	Lighting.ClockTime = saved
	-- onClockTimeChanged will fire on next heartbeat

	-- Advance clock over time
	local lastTick = os.clock()
	RunService.Heartbeat:Connect(function()
		if not cycleEnabled then return end
		local now = os.clock()
		local dt = now - lastTick
		lastTick = now

		-- Real seconds → in-game hours:
		-- At 1x: one real day = one in-game day → 24 hrs / 86400 sec = 0.000278 hr/s
		local gameHoursPerRealSecond = (24 / 86400) * CYCLE_MULTIPLIER
		local newTime = (Lighting.ClockTime + dt * gameHoursPerRealSecond) % 24
		Lighting.ClockTime = newTime
	end)

	print("[LightingSystem] Day/night cycle started (x" .. CYCLE_MULTIPLIER .. " speed)")
end

-- ── Public API ─────────────────────────────────────────────────
local LightingSystem = {}

function LightingSystem.setCycleSpeed(multiplier: number)
	CYCLE_MULTIPLIER = multiplier
end

function LightingSystem.pause()
	cycleEnabled = false
end

function LightingSystem.resume()
	cycleEnabled = true
end

function LightingSystem.setTime(clockTime: number)
	assert(type(clockTime) == "number", "ClockTime must be a number")
	assert(clockTime >= 0 and clockTime < 24, "ClockTime must be 0–23.999")
	Lighting.ClockTime = clockTime
	lastAppliedPreset = nil  -- force re-apply
	onClockTimeChanged()
end

function LightingSystem.getCurrentPresetName()
	return lastAppliedPreset and lastAppliedPreset.Name or "none"
end

function LightingSystem.disable()
	cycleEnabled = false
end

-- ── Auto-start ─────────────────────────────────────────────────
startCycle()

return LightingSystem
