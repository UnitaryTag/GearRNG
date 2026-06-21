-- MenuCameraController.client.lua
-- LocalScript — fixed parallax camera framing the HeroTree and character.
-- Matches Blender MainMenuCamera composition: close, intimate, golden hour.
-- Mouse movement creates a subtle parallax offset (inverted).
-- TweenToPlayPosition for transitioning into gameplay.
--
-- Blender reference (2026-06-21):
--   MainMenuCamera: position (0.8, -4.5, 1.5), 35mm lens, looking at chest level.
--   Character at SIT_POSITION (-4.5, 0.2, 2) facing 135° toward tree at origin.

local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")

local MenuCameraController = {}

-- ── Configuration ────────────────────────────────────────────
-- Camera placed ~6 studs from character, front-right, slightly elevated.
-- Matches Blender's intimate 35mm framing (vs old 18-stud establishing shot).
local CAM = {
	BasePos = Vector3.new(-2.8, 2.4, 5.8),
	LookAt = Vector3.new(-4.5, 2.2, 2.0),
	MaxOffsetX = 3.5,
	MaxOffsetY = 1.5,
	LerpSpeed = 4,
	FieldOfView = 60,
	-- Play-transition target: tighter, lower angle
	PlayPos = Vector3.new(-2.8, 2.0, 4.8),
	PlayLookAt = Vector3.new(-4.5, 2.0, 1.8),
	PlayFov = 55,
}

-- ── State ─────────────────────────────────────────────────────
local camera = workspace.CurrentCamera
local currentOffset = Vector3.new(0, 0, 0)
local targetOffset = Vector3.new(0, 0, 0)
local isActive = false
local screenCenter = Vector2.new()

-- ── Helpers ──────────────────────────────────────────────────
local function clampOffset(offset)
	return Vector3.new(
		math.clamp(offset.X, -CAM.MaxOffsetX, CAM.MaxOffsetX),
		math.clamp(offset.Y, -CAM.MaxOffsetY, CAM.MaxOffsetY),
		0
	)
end

local function updateCameraCFrame()
	local camPos = CAM.BasePos + currentOffset
	camera.CFrame = CFrame.lookAt(camPos, CAM.LookAt)
end

-- ── Input ─────────────────────────────────────────────────────
-- Invert mouse direction: moving mouse right → camera slides left
local function onInputChanged(input, gameProcessed)
	if not isActive or gameProcessed then return end
	if input.UserInputType == Enum.UserInputType.MouseMovement then
		local mousePos = UserInputService:GetMouseLocation()
		local dx = (mousePos.X / screenCenter.X) - 1  -- -1..1
		local dy = (mousePos.Y / screenCenter.Y) - 1  -- -1..1
		targetOffset = clampOffset(Vector3.new(
			-dx * CAM.MaxOffsetX,  -- inverted X
			-dy * CAM.MaxOffsetY,  -- inverted Y
			0
		))
	end
end

-- ── Render Loop ───────────────────────────────────────────────
local function onRenderStep(deltaTime)
	if not isActive then return end

	-- Force-reassert camera control every frame
	camera.CameraType = Enum.CameraType.Scriptable

	-- Smooth lerp current offset toward target
	local lerpFactor = 1 - math.exp(-CAM.LerpSpeed * deltaTime)
	currentOffset = currentOffset:Lerp(targetOffset, lerpFactor)

	updateCameraCFrame()
end

-- ── Public API ───────────────────────────────────────────────
function MenuCameraController:start()
	if isActive then return end
	isActive = true

	camera.CameraType = Enum.CameraType.Scriptable
	camera.FieldOfView = CAM.FieldOfView

	-- Compute screen center once
	screenCenter = camera.ViewportSize / 2

	-- Position camera immediately
	currentOffset = Vector3.new(0, 0, 0)
	targetOffset = Vector3.new(0, 0, 0)
	updateCameraCFrame()

	UserInputService.InputChanged:Connect(onInputChanged)
	RunService:BindToRenderStep("MenuCamera", Enum.RenderPriority.Camera.Value, onRenderStep)

	-- Fade FOV in
	TweenService:Create(
		camera,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ FieldOfView = CAM.FieldOfView }
	):Play()

	print("[MenuCameraController] Parallax camera started.")
end

function MenuCameraController:stop()
	isActive = false
	RunService:UnbindFromRenderStep("MenuCamera")
	camera.CameraType = Enum.CameraType.Custom
	print("[MenuCameraController] Camera stopped.")
end

function MenuCameraController:isActive()
	return isActive
end

-- Tween to a closer, lower cinematic angle (e.g., on Play click)
function MenuCameraController:tweenToPlayPosition(duration)
	duration = duration or 2.0
	TweenService:Create(camera, TweenInfo.new(duration, Enum.EasingStyle.Quad, Enum.EasingDirection.InOut), {
		FieldOfView = CAM.PlayFov,
		CFrame = CFrame.lookAt(CAM.PlayPos, CAM.PlayLookAt),
	}):Play()
	print("[MenuCameraController] Tweening to play position.")
end

return MenuCameraController
