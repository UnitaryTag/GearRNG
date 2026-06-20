-- MenuCharacterPoser.client.lua
-- LocalScript — poses the player's character leaning back against the HeroTree.
-- Uses Motor6D C0 offsets for a relaxed seated-against-tree pose.
-- Plan spec:
--   Position (-4.5, 1.8, 2), facing tree, slight backward lean
--   LowerTorso tilted back 10°, UpperTorso 15°
--   Left leg extended, right leg bent
--   Left arm on grass, right arm on knee
--   Head tilted 8° up

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MenuCharacterPoser = {}

-- ── Configuration ────────────────────────────────────────────
local SIT_POSITION = Vector3.new(-4.5, 0.2, 2)

-- ── R15 Motor6D Posing ───────────────────────────────────────
-- Each: {partName, motorName, C0 offset}
-- Sitting with back against tree, legs out, arms relaxed.

local R15_TREE_POSE = {
	-- ── Torso lean back (into tree) ──
	-- LowerTorso tilts back ~10°
	{"LowerTorso", "Root",        CFrame.Angles(0, 0, 0)},
	{"LowerTorso", "Right Hip",   CFrame.new(0.5, -0.15, -0.15) * CFrame.Angles(0, 0, math.rad(-12))},
	{"LowerTorso", "Left Hip",    CFrame.new(-0.5, -0.15, -0.15) * CFrame.Angles(0, 0, math.rad(12))},
	-- UpperTorso tilts back ~15° (cumulative with LowerTorso lean)
	{"UpperTorso", "Waist",       CFrame.new(0, 0.3, 0) * CFrame.Angles(math.rad(-12), 0, 0)},

	-- ── Legs ──
	-- Left leg: extended forward, slightly bent
	{"LeftUpperLeg", "LeftLowerLeg", CFrame.new(0, -1.2, 0.4) * CFrame.Angles(math.rad(30), 0, 0)},
	-- Right leg: bent at knee, foot closer
	{"RightUpperLeg", "RightLowerLeg", CFrame.new(0, -0.9, -0.5) * CFrame.Angles(math.rad(75), 0, 0)},

	-- ── Arms ──
	-- Left arm: hand on grass behind/side for support
	{"LeftUpperArm", "LeftLowerArm", CFrame.new(0, -0.6, 0.35) * CFrame.Angles(math.rad(-70), 0, math.rad(15))},
	-- Right arm: hand resting on right knee
	{"RightUpperArm", "RightLowerArm", CFrame.new(0, -0.6, 0.35) * CFrame.Angles(math.rad(-50), 0, math.rad(-10))},

	-- ── Head: tilted up slightly, relaxed ──
	{"UpperTorso", "Head", CFrame.new(0, 0.8, 0) * CFrame.Angles(math.rad(-6), 0, 0)},
}

-- ── R6 Motor6D Posing (fallback) ─────────────────────────────
local R6_TREE_POSE = {
	-- Torso lean
	{"Torso", "Right Hip",  CFrame.new(0.5, -0.15, -0.15) * CFrame.Angles(0, 0, math.rad(-8))},
	{"Torso", "Left Hip",   CFrame.new(-0.5, -0.15, -0.15) * CFrame.Angles(0, 0, math.rad(8))},
	-- Legs
	{"Left Leg", "LeftLowerLeg",  CFrame.new(0, -1.2, 0.4) * CFrame.Angles(math.rad(30), 0, 0)},
	{"Right Leg", "RightLowerLeg", CFrame.new(0, -0.9, -0.5) * CFrame.Angles(math.rad(75), 0, 0)},
	-- Arms
	{"Left Arm", "LeftLowerArm",  CFrame.new(0, -0.6, 0.35) * CFrame.Angles(math.rad(-70), 0, math.rad(15))},
	{"Right Arm", "RightLowerArm", CFrame.new(0, -0.6, 0.35) * CFrame.Angles(math.rad(-50), 0, math.rad(-10))},
}

-- ── Motor6D lookup ───────────────────────────────────────────
local function findMotor(character, partName, motorName)
	local part = character:FindFirstChild(partName, true)
	if part then
		for _, child in ipairs(part:GetChildren()) do
			if child:IsA("Motor6D") and child.Name == motorName then
				return child
			end
		end
	end
	return nil
end

local function isR15(character)
	return character:FindFirstChild("LowerTorso") ~= nil
end

-- ── Apply Pose ─────────────────────────────────────────────────
function MenuCharacterPoser:applyTreePose(character)
	local poseTable = isR15(character) and R15_TREE_POSE or R6_TREE_POSE
	local applied = 0

	for _, entry in ipairs(poseTable) do
		local partName, motorName, c0 = entry[1], entry[2], entry[3]
		local motor = findMotor(character, partName, motorName)
		if motor then
			motor.C0 = c0
			applied = applied + 1
		end
	end

	print("[MenuCharacterPoser] Tree pose applied: "
		.. applied .. "/" .. #poseTable .. " motors set (" ..
		(isR15(character) and "R15" or "R6") .. ").")
	return applied
end

-- ── Position Character ───────────────────────────────────────
function MenuCharacterPoser:moveToTree(character)
	local rootPart = character:FindFirstChild("HumanoidRootPart")
	if not rootPart then
		warn("[MenuCharacterPoser] No HumanoidRootPart!")
		return false
	end

	-- Disable movement & physics
	local humanoid = character:FindFirstChildOfClass("Humanoid")
	if humanoid then
		humanoid.WalkSpeed = 0
		humanoid.JumpPower = 0
		humanoid.AutoRotate = false
	end

	-- Face toward tree (+X) — character at (-4.5, _, 2) looking toward (0,0,0)
	local targetCFrame = CFrame.new(SIT_POSITION) * CFrame.Angles(0, math.rad(135), 0)
	local tween = TweenService:Create(
		rootPart,
		TweenInfo.new(1.5, Enum.EasingStyle.Quad, Enum.EasingDirection.Out),
		{ CFrame = targetCFrame }
	)
	tween:Play()
	tween.Completed:Wait()

	-- Anchor in place
	humanoid.PlatformStand = true

	print("[MenuCharacterPoser] Character moved to tree.")
	return true
end

-- ── Main ─────────────────────────────────────────────────────
function MenuCharacterPoser:poseLocalPlayer()
	local player = Players.LocalPlayer
	local character = player.Character or player.CharacterAdded:Wait()
	if not character then
		warn("[MenuCharacterPoser] No character found!")
		return
	end

	task.wait(0.5)
	self:moveToTree(character)
	task.wait(0.1)
	self:applyTreePose(character)

	-- Re-apply on respawn
	player.CharacterAdded:Connect(function(newChar)
		task.wait(0.5)
		self:moveToTree(newChar)
		task.wait(0.1)
		self:applyTreePose(newChar)
		local h = newChar:FindFirstChildOfClass("Humanoid")
		if h then h.PlatformStand = true end
	end)
end

return MenuCharacterPoser
