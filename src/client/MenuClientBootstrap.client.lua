-- MenuClientBootstrap.client.lua
-- LocalScript — entry point for all client-side menu systems.
-- Waits for server to signal menu readiness, then activates the full menu.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

-- Require client modules
local MenuCharacterPoser = require(script.MenuCharacterPoser)
local MenuCameraController = require(script.MenuCameraController)
local MenuUIBuilder = require(script.MenuUIBuilder)
local GrassWindSystem = require(script.GrassWindSystem)
local LightingSystem = require(script.LightingSystem) -- auto-starts day/night cycle

-- Require shared modules
local MenuCoordinator = require(ReplicatedStorage.Modules.MenuCoordinator)

-- ── Boot ─────────────────────────────────────────────────────
local function boot()
	print("[MenuClientBootstrap] Starting client menu boot...")

	-- Create coordinator with all subsystems
	local coordinator = MenuCoordinator.new({
		MenuCharacterPoser = MenuCharacterPoser,
		MenuCameraController = MenuCameraController,
		MenuUIBuilder = MenuUIBuilder,
		GrassWindSystem = GrassWindSystem,
	})

	-- Wait for server to signal ready, then activate everything
	coordinator:waitForReady()

	-- Listen for transitions back to menu (e.g., after gameplay)
	local stateEvent = ReplicatedStorage:FindFirstChild("MenuRemotes")
	if stateEvent then
		stateEvent = stateEvent:FindFirstChild("MenuStateChanged")
		if stateEvent then
			stateEvent.OnClientEvent:Connect(function(oldState, newState)
				if newState == "MenuReady" and not coordinator._isActive then
					task.wait(0.5)
					coordinator:activate()
				elseif newState == "Playing" and coordinator._isActive then
					coordinator:deactivate()
				end
			end)
		end
	end

	print("[MenuClientBootstrap] Client menu boot complete.")
end

-- ── Run ──────────────────────────────────────────────────────
-- Wait for character to exist before starting
local player = Players.LocalPlayer
if player.Character then
	boot()
else
	player.CharacterAdded:Connect(function()
		boot()
	end)
end
