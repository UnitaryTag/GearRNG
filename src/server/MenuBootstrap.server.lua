-- MenuBootstrap.server.lua
-- Entry point for the menu system. Coordinates server-side initialization:
-- 1. Configure lighting & atmosphere
-- 2. Build the 3D scene
-- 3. Wait for assets to load
-- 4. Signal clients that the menu is ready

local ServerScriptService = game:GetService("ServerScriptService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local MenuEnvironment = require(ServerScriptService.Server.MenuEnvironment)
local MenuSceneBuilder = require(ServerScriptService.Server.MenuSceneBuilder)
local MenuStateManager = require(ReplicatedStorage.Modules.MenuStateManager)
local MenuAudio = require(ReplicatedStorage.Modules.MenuAudio)


-- ── Boot Sequence ────────────────────────────────────────────
local function bootstrap()
	print("[MenuBootstrap] Starting menu boot sequence...")

	-- Create shared state manager (lives on server)
	local stateManager = MenuStateManager.new()

	-- Pass state manager to clients via a RemoteEvent
	local remotes = ReplicatedStorage:FindFirstChild("MenuRemotes")
	if not remotes then
		remotes = Instance.new("Folder")
		remotes.Name = "MenuRemotes"
		remotes.Parent = ReplicatedStorage
	end

	local stateEvent = Instance.new("RemoteEvent")
	stateEvent.Name = "MenuStateChanged"
	stateEvent.Parent = remotes

	local requestStateEvent = Instance.new("RemoteFunction")
	requestStateEvent.Name = "RequestMenuState"
	requestStateEvent.Parent = remotes

	-- Handle client state requests
	requestStateEvent.OnServerInvoke = function(player)
		return {
			state = stateManager:getState(),
			data = stateManager:getStateData(),
		}
	end

	-- Play request — client fires when player clicks PLAY
	local playRequestEvent = Instance.new("RemoteEvent")
	playRequestEvent.Name = "PlayRequest"
	playRequestEvent.Parent = remotes

	playRequestEvent.OnServerEvent:Connect(function(player)
		print("[MenuBootstrap] Play requested by " .. player.Name)
		-- Transition to Playing state (future: teleport to game world)
		stateManager:markPlaying()
	end)

	-- Broadcast state changes
	stateManager:onStateChanged(function(oldState, newState)
		stateEvent:FireAllClients(oldState, newState)
	end)

	-- Step 1: Configure environment
	MenuEnvironment.setup()

	-- Step 2: Build the scene (place tree, grass, rocks)
	MenuSceneBuilder.buildAll()

	-- Step 3: Wait a beat for everything to settle
	task.wait(0.5)

	-- Step 4: Start ambient audio
	local audio = MenuAudio.new()
	audio:playAmbient() -- Placeholder — add real track ID

	-- Step 5: Mark menu as ready
	stateManager:markReady()

	print("[MenuBootstrap] Menu boot complete! State: " .. stateManager:getState())

	-- Handle players joining after boot
	Players.PlayerAdded:Connect(function(player)
		print("[MenuBootstrap] Player joined: " .. player.Name)
		-- Player's client will request state via RequestMenuState
	end)

	-- Return the state manager so other code can use it
	return stateManager, audio
end

-- ── Run ──────────────────────────────────────────────────────
local stateManager, audio = bootstrap()

-- Export for other server modules
return {
	stateManager = stateManager,
	audio = audio,
}
