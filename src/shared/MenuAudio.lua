-- MenuAudio.lua (Shared Module)
-- Audio manager for the main menu — ambient loops, UI one-shot SFX.
-- Usable on both server (ambient music) and client (UI hover/click sounds).
--
-- Sound ID reference (rbxassetid format):
--   Hover:  rbxassetid://9112726340  (UI hover blip)
--   Click:  rbxassetid://9112724273  (UI click)
--   Ambience: rbxassetid://0         (placeholder — replace with wind/tree ambience)

local MenuAudio = {}
MenuAudio.__index = MenuAudio

-- ── Sound ID Constants ────────────────────────────────────────
-- TODO: replace with your own uploaded asset IDs
MenuAudio.SoundIds = {
	Hover = "rbxassetid://9112726340",
	Click = "rbxassetid://9112724273",
	Ambient = "rbxassetid://0", -- wind-through-trees loop
	PlayButton = "rbxassetid://0", -- triumphant fanfare for PLAY
}

-- ── Constructor ───────────────────────────────────────────────
function MenuAudio.new()
	local self = setmetatable({}, MenuAudio)
	self._sounds = {}
	self._lastHoverTime = 0
	self._hoverCooldown = 0.08 -- seconds between hover sounds
	return self
end

-- ── Ambient (looping, server-side) ────────────────────────────
function MenuAudio:playAmbient(soundId)
	soundId = soundId or MenuAudio.SoundIds.Ambient
	local sound = Instance.new("Sound")
	sound.Name = "AmbientTrack"
	sound.SoundId = soundId
	sound.Looped = true
	sound.Volume = 0.25
	sound.Parent = workspace
	table.insert(self._sounds, sound)
	sound:Play()
	return sound
end

-- ── One-Shot (self-destructing) ───────────────────────────────
function MenuAudio:playOneShot(soundId, volume, parent)
	volume = volume or 0.5
	parent = parent or workspace

	local sound = Instance.new("Sound")
	sound.Name = "OneShot"
	sound.SoundId = soundId
	sound.Volume = volume
	sound.Parent = parent
	sound:Play()

	sound.Ended:Connect(function()
		sound:Destroy()
	end)
	return sound
end

-- ── UI Sound Helpers (client-side, with hover cooldown) ───────
function MenuAudio:playUIHover()
	local now = tick()
	if now - self._lastHoverTime < self._hoverCooldown then return end
	self._lastHoverTime = now

	-- Parent to SoundService so it plays even if UI parent is destroyed
	self:playOneShot(MenuAudio.SoundIds.Hover, 0.3, game:GetService("SoundService"))
end

function MenuAudio:playUIClick()
	self:playOneShot(MenuAudio.SoundIds.Click, 0.5, game:GetService("SoundService"))
end

function MenuAudio:playUIPlayButton()
	self:playOneShot(MenuAudio.SoundIds.PlayButton, 0.7, game:GetService("SoundService"))
end

-- ── Fade In (for ambient tracks) ──────────────────────────────
function MenuAudio:fadeIn(sound, duration)
	duration = duration or 2
	sound.Volume = 0
	sound:Play()
	local startTime = tick()
	task.spawn(function()
		while tick() - startTime < duration and sound.Parent do
			sound.Volume = math.min(0.25, (tick() - startTime) / duration * 0.25)
			task.wait(0.05)
		end
	end)
end

-- ── Stop All ──────────────────────────────────────────────────
function MenuAudio:stopAll()
	for _, sound in ipairs(self._sounds) do
		if sound.Parent then
			sound:Stop()
			sound:Destroy()
		end
	end
	self._sounds = {}
end

return MenuAudio
