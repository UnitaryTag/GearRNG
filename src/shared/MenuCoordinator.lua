-- MenuCoordinator.lua (Shared Module, run on client)
-- Orchestrates all client-side menu systems.
-- Listens for server state changes and activates/deactivates subsystems accordingly.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local MenuCoordinator = {}
MenuCoordinator.__index = MenuCoordinator

-- ── Constructor ──────────────────────────────────────────────
function MenuCoordinator.new(dependencies)
	local self = setmetatable({}, MenuCoordinator)

	self.MenuCharacterPoser = dependencies.MenuCharacterPoser
	self.MenuCameraController = dependencies.MenuCameraController
	self.MenuUIBuilder = dependencies.MenuUIBuilder
	self.GrassWindSystem = dependencies.GrassWindSystem

	self._isActive = false
	self._gui = nil

	return self
end

-- ── Activate All Menu Systems ────────────────────────────────
function MenuCoordinator:activate()
	if self._isActive then return end
	self._isActive = true

	print("[MenuCoordinator] Activating menu systems...")

	-- 1. Position the player character under the tree
	if self.MenuCharacterPoser then
		self.MenuCharacterPoser:poseLocalPlayer()
	end

	-- 2. Start the orbital camera
	if self.MenuCameraController then
		self.MenuCameraController:start()
	end

	-- 3. Start grass wind animation
	if self.GrassWindSystem then
		self.GrassWindSystem:start()
	end

	-- 4. Build and show the UI
	if self.MenuUIBuilder then
		self._gui = self.MenuUIBuilder:build()
	end

	print("[MenuCoordinator] All menu systems active.")
end

-- ── Deactivate All Menu Systems ──────────────────────────────
function MenuCoordinator:deactivate()
	if not self._isActive then return end
	self._isActive = false

	print("[MenuCoordinator] Deactivating menu systems...")

	if self.MenuCameraController then
		self.MenuCameraController:stop()
	end

	if self.GrassWindSystem then
		self.GrassWindSystem:stop()
	end

	-- Destroy UI
	if self._gui then
		self._gui:Destroy()
		self._gui = nil
	end
end

-- ── Wait For Menu Ready ──────────────────────────────────────
function MenuCoordinator:waitForReady()
	local remotes = ReplicatedStorage:WaitForChild("MenuRemotes", 10)
	if not remotes then
		warn("[MenuCoordinator] MenuRemotes not found!")
		return false
	end

	local requestState = remotes:WaitForChild("RequestMenuState", 5)
	if not requestState then
		warn("[MenuCoordinator] RequestMenuState not found!")
		return false
	end

	-- Ask server for current state
	local ok, result = pcall(function()
		return requestState:InvokeServer()
	end)

	if ok and result and result.state == "MenuReady" then
		print("[MenuCoordinator] Server reports menu ready — activating!")
		self:activate()
		return true
	elseif ok and result and result.state == "Loading" then
		-- Wait for state change event
		print("[MenuCoordinator] Menu still loading, waiting for state change...")
		local stateEvent = remotes:WaitForChild("MenuStateChanged", 10)
		if stateEvent then
			local connection
			connection = stateEvent.OnClientEvent:Connect(function(oldState, newState)
				if newState == "MenuReady" then
					connection:Disconnect()
					print("[MenuCoordinator] Menu is now ready!")
					self:activate()
				end
			end)
			return true
		end
	else
		warn("[MenuCoordinator] Failed to get menu state: " .. tostring(ok))
	end

	return false
end

return MenuCoordinator
