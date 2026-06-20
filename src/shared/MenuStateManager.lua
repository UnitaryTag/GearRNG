-- MenuStateManager.lua (Shared Module)
-- State machine for the main menu flow.
-- Used by both server (for state authority) and client (for UI transitions).
-- States: Loading → MenuReady → Playing → (back to MenuReady)

local MenuStateManager = {}
MenuStateManager.__index = MenuStateManager

-- ── State Enum ───────────────────────────────────────────────
local MenuState = {
	Loading = "Loading",
	MenuReady = "MenuReady",
	Playing = "Playing",
}

MenuStateManager.State = MenuState

-- ── Constructor ──────────────────────────────────────────────
function MenuStateManager.new()
	local self = setmetatable({}, MenuStateManager)

	self._currentState = MenuState.Loading
	self._listeners = {}
	self._stateData = {} -- Arbitrary data per state

	return self
end

-- ── State Access ─────────────────────────────────────────────
function MenuStateManager:getState()
	return self._currentState
end

function MenuStateManager:getStateData()
	return self._stateData[self._currentState] or {}
end

function MenuStateManager:setStateData(key, value)
	if not self._stateData[self._currentState] then
		self._stateData[self._currentState] = {}
	end
	self._stateData[self._currentState][key] = value
end

-- ── State Transitions ────────────────────────────────────────
function MenuStateManager:transitionTo(newState)
	if newState == self._currentState then
		return
	end

	local oldState = self._currentState
	self._currentState = newState

	-- Notify listeners
	for _, listener in ipairs(self._listeners) do
		task.spawn(listener, oldState, newState)
	end

	print("[MenuStateManager] State: " .. oldState .. " → " .. newState)
end

function MenuStateManager:onStateChanged(callback)
	table.insert(self._listeners, callback)
	return #self._listeners -- Return index for unsubscribing
end

function MenuStateManager:removeListener(index)
	self._listeners[index] = nil
end

-- ── Convenience Checks ───────────────────────────────────────
function MenuStateManager:isLoading()
	return self._currentState == MenuState.Loading
end

function MenuStateManager:isMenuReady()
	return self._currentState == MenuState.MenuReady
end

function MenuStateManager:isPlaying()
	return self._currentState == MenuState.Playing
end

function MenuStateManager:markReady()
	self:transitionTo(MenuState.MenuReady)
end

function MenuStateManager:markPlaying()
	self:transitionTo(MenuState.Playing)
end

function MenuStateManager:markLoading()
	self:transitionTo(MenuState.Loading)
end

return MenuStateManager
