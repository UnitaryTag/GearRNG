-- MenuCharacterPoser.client.lua
-- LocalScript — poses the player's character in the Blender seated pose.
-- Uses Motor6D C0 offsets for a symmetric seated position with hands
-- on ground behind, legs extended forward, slight backward lean.
-- 15-joint R15 rig, verified against Blender armature bone list 2026-06-21.
--
-- Motor6D naming convention (Roblox default): Motor6D.Name = Part1.Name.
-- Motor6D is a child of Part0. findMotor searches Part0's children.
--
-- Plan:
--   Position (-4.5, 0.2, 2), facing 135° toward tree
--   LowerTorso on ground, UpperTorso tilted back ~8°
--   Legs extended forward (hips 90° X), knees slightly bowed (±18° Z)
--   Arms raised up and back (shoulders 68° Z), hands flat behind body
--   Head tilted up ~6°

local Players = game:GetService("Players")
local TweenService = game:GetService("TweenService")

local MenuCharacterPoser = {}

-- ── Configuration ────────────────────────────────────────────
local SIT_POSITION = Vector3.new(-4.5, 0.2, 2)

-- ── R15 Motor6D Posing ───────────────────────────────────────
-- Each: {part0Name, motorName, C0 offset}
-- 15 symmetric joints matching the Blender seated pose.

local R15_TREE_POSE = {
	-- ── Root: HumanoidRootPart → LowerTorso ──
	{"HumanoidRootPart", "LowerTorso",
		CFrame.Angles(math.rad(8), 0, 0)},

	-- ── Hips: LowerTorso → UpperLegs (legs forward, seated) ──
	-- Blender: UpperLeg.L dir (-0.90, 0.17, 0.39) Roblox → extended forward-left.
	-- 90° X rotation to swing legs from standing (down) to seated (forward).
	{"LowerTorso", "LeftUpperLeg",
		CFrame.new(-0.5, -0.15, -0.15) * CFrame.Angles(math.rad(90), 0, math.rad(-10))},
	{"LowerTorso", "RightUpperLeg",
		CFrame.new(0.5, -0.15, -0.15) * CFrame.Angles(math.rad(90), 0, math.rad(10))},

	-- ── Waist: LowerTorso → UpperTorso (slight backward lean) ──
	-- Blender: torso ~0.4 studs above hips, tilted back ~8°.
	{"LowerTorso", "UpperTorso",
		CFrame.new(0, 0.4, 0) * CFrame.Angles(math.rad(-8), 0, 0)},

	-- ── Knees: UpperLeg → LowerLeg (anatomical joint, forward extension from hip rotation) ──
	-- The 90° X hip rotation swings the leg from vertical to horizontal.
	-- Knee is at the bottom of UpperLeg (~1 stud). ±18° Z for outward bow.
	{"LeftUpperLeg", "LeftLowerLeg",
		CFrame.new(0, -1.0, 0) * CFrame.Angles(0, 0, math.rad(-18))},
	{"RightUpperLeg", "RightLowerLeg",
		CFrame.new(0, -1.0, 0) * CFrame.Angles(0, 0, math.rad(18))},

	-- ── Ankles: LowerLeg → Foot (anatomical joint, foot flat from ankle rotation) ──
	-- Ankle is at the bottom of LowerLeg (~1 stud). -90° X flattens foot to ground.
	{"LeftLowerLeg", "LeftFoot",
		CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(-90), 0, 0)},
	{"RightLowerLeg", "RightFoot",
		CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(-90), 0, 0)},

	-- ── Shoulders: UpperTorso → UpperArm (arms raised up, hands behind body) ──
	-- Blender: shoulder ~1.35 up, ~0.19 behind torso. Arm points nearly straight up.
	{"UpperTorso", "LeftUpperArm",
		CFrame.new(-1.0, 1.35, -0.19) * CFrame.Angles(math.rad(12), 0, math.rad(68))},
	{"UpperTorso", "RightUpperArm",
		CFrame.new(1.0, 1.35, -0.19) * CFrame.Angles(math.rad(12), 0, math.rad(-68))},

	-- ── Elbows: UpperArm → LowerArm (anatomical joint, forearm angles from shoulder rotation) ──
	-- Elbow is at the bottom of UpperArm. -30° X bends the forearm back.
	{"LeftUpperArm", "LeftLowerArm",
		CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(-30), 0, 0)},
	{"RightUpperArm", "RightLowerArm",
		CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(-30), 0, 0)},

	-- ── Wrists: LowerArm → Hand (anatomical joint, hands flat from wrist rotation) ──
	-- Wrist is at the bottom of LowerArm. -90° X flattens hand toward ground.
	{"LeftLowerArm", "LeftHand",
		CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(-90), 0, 0)},
	{"RightLowerArm", "RightHand",
		CFrame.new(0, -0.8, 0) * CFrame.Angles(math.rad(-90), 0, 0)},

	-- ── Head: UpperTorso → Head (tilted slightly up, relaxed) ──
	-- Blender: head ~1.6 studs above torso, slight backward tilt.
	{"UpperTorso", "Head",
		CFrame.new(0, 0.8, 0) * CFrame.Angles(math.rad(-6), 0, 0)},
}

-- ── R6 Motor6D Posing (fallback) ─────────────────────────────
local R6_TREE_POSE = {
	-- Torso lean
	{"Torso", "Left Hip",
		CFrame.new(-0.5, -0.15, -0.15) * CFrame.Angles(0, 0, math.rad(8))},
	{"Torso", "Right Hip",
		CFrame.new(0.5, -0.15, -0.15) * CFrame.Angles(0, 0, math.rad(-8))},
	-- Legs (extended forward)
	{"Left Hip", "Left Leg",
		CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0)},
	{"Right Hip", "Right Leg",
		CFrame.new(0, -1.0, 0) * CFrame.Angles(math.rad(90), 0, 0)},
	-- Arms (raised behind)
	{"Torso", "Left Shoulder",
		CFrame.new(-1.0, 0.6, 0) * CFrame.Angles(math.rad(12), 0, math.rad(68))},
	{"Torso", "Right Shoulder",
		CFrame.new(1.0, 0.6, 0) * CFrame.Angles(math.rad(12), 0, math.rad(-68))},
	-- Head
	{"Torso", "Head",
		CFrame.new(0, 0.8, 0) * CFrame.Angles(math.rad(-6), 0, 0)},
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

	-- Anchor in place (also prevents Animate script from fighting our pose)
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
