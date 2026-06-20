-- MenuSceneBuilder.server.lua
-- Places the HeroTree, grass tufts, rocks, and other props in the 3D menu world.
-- Assets are expected in ReplicatedStorage.Assets.

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local ServerStorage = game:GetService("ServerStorage")

local MenuSceneBuilder = {}

-- Configuration for scene elements
local CONFIG = {
	TreePosition = Vector3.new(0, 0, 0),
	GroundSize = 100, -- studs radius of the grassy area
	GrassCount = 60,
	RockCount = 8,
	ParticleCount = 15, -- floating ambient particles
}

-- ── Helpers ──────────────────────────────────────────────────
local function placeAsset(assetName, position, rotation, parent)
	local asset = ReplicatedStorage.Assets:FindFirstChild(assetName)
	if not asset then
		warn("[MenuSceneBuilder] Asset not found: " .. assetName)
		return nil
	end

	local clone = asset:Clone()
	clone:PivotTo(CFrame.new(position) * CFrame.Angles(rotation or 0, 0, 0))
	clone.Parent = parent or workspace
	return clone
end

local function randomPositionInCircle(center, radius)
	local angle = math.random() * math.pi * 2
	local dist = math.sqrt(math.random()) * radius
	return center + Vector3.new(
		math.cos(angle) * dist,
		0,
		math.sin(angle) * dist
	)
end

-- ── Ground Plane ─────────────────────────────────────────────
function MenuSceneBuilder:buildGround()
	local ground = Instance.new("Part")
	ground.Name = "MenuGround"
	ground.Size = Vector3.new(CONFIG.GroundSize * 2, 0.5, CONFIG.GroundSize * 2)
	ground.Position = Vector3.new(0, -0.25, 0)
	ground.Anchored = true
	ground.BrickColor = BrickColor.new("Earth green")
	ground.Material = Enum.Material.Grass
	ground.Parent = workspace

	print("[MenuSceneBuilder] Ground plane created.")
	return ground
end

-- ── Hero Tree ────────────────────────────────────────────────
-- Placed as 6 Z-band pieces (split for Roblox <20k tri limit)
-- All pieces share the same Blender origin → align at TreePosition
local TREE_PIECES = {
	"Tree_Trunk_Lower",
	"Tree_Trunk_Mid",
	"Tree_Trunk_Upper",
	"Tree_Trunk_Upper.001",
	"Tree_Trunk_Canopy",
	"Tree_Leaves",
}

function MenuSceneBuilder:placeHeroTree()
	local treeFolder = Instance.new("Folder")
	treeFolder.Name = "HeroTree"
	treeFolder.Parent = workspace

	for _, pieceName in ipairs(TREE_PIECES) do
		local piece = placeAsset(pieceName, CONFIG.TreePosition, nil, treeFolder)
		if piece then
			piece.Name = pieceName
			-- Apply colors lost during FBX import
			local isLeaves = (pieceName == "Tree_Leaves")
			for _, child in piece:GetDescendants() do
				if child:IsA("MeshPart") then
					if isLeaves then
						child.Color = Color3.fromRGB(60, 140, 50)
						child.Material = Enum.Material.Grass
					else
						child.Color = Color3.fromRGB(90, 65, 40)
						child.Material = Enum.Material.Wood
					end
				end
			end
		end
	end

	print("[MenuSceneBuilder] HeroTree placed (" .. #TREE_PIECES .. " pieces) at " .. tostring(CONFIG.TreePosition))
	return treeFolder
end

-- ── Grass Tufts ──────────────────────────────────────────────
function MenuSceneBuilder:scatterGrass(center)
	for i = 1, CONFIG.GrassCount do
		local pos = randomPositionInCircle(center, CONFIG.GroundSize * 0.8)
		-- Don't place grass too close to the tree
		if (pos - center).Magnitude > 5 then
			local grass = placeAsset("GrassTuft", pos, math.rad(math.random(0, 360)), workspace)
			if grass then
				grass.Name = "Grass_" .. i
				-- Randomize scale for variety
				local s = 0.8 + math.random() * 0.6
				grass:ScaleTo(s)
			end
		end
	end
	print("[MenuSceneBuilder] " .. CONFIG.GrassCount .. " grass tufts scattered.")
end

-- ── Rocks ────────────────────────────────────────────────────
function MenuSceneBuilder:scatterRocks(center)
	-- Generate simple rocks from parts if no rock asset exists
	for i = 1, CONFIG.RockCount do
		local pos = randomPositionInCircle(center, CONFIG.GroundSize * 0.7)
		if (pos - center).Magnitude > 8 then
			local rock = Instance.new("Part")
			rock.Name = "Rock_" .. i
			rock.Size = Vector3.new(
				1 + math.random() * 2,
				0.5 + math.random() * 1.5,
				1 + math.random() * 2
			)
			rock.Position = pos + Vector3.new(0, rock.Size.Y / 2, 0)
			rock.Anchored = true
			rock.BrickColor = BrickColor.new("Dark stone grey")
			rock.Material = Enum.Material.Slate
			rock.Parent = workspace
		end
	end
	print("[MenuSceneBuilder] " .. CONFIG.RockCount .. " rocks placed.")
end

-- ── Ambient Particles ────────────────────────────────────────
function MenuSceneBuilder:createAmbientParticles()
	local attachments = {}
	for i = 1, CONFIG.ParticleCount do
		local attach = Instance.new("Attachment")
		attach.Name = "ParticlePoint_" .. i
		attach.Position = Vector3.new(
			math.random(-30, 30),
			math.random(1, 15),
			math.random(-30, 30)
		)
		attach.Parent = workspace.Terrain

		local emitter = Instance.new("ParticleEmitter")
		emitter.Texture = "rbxassetid://0" -- Use a generic sparkle/dust texture
		emitter.Rate = 0.5
		emitter.Lifetime = NumberRange.new(4, 8)
		emitter.Speed = NumberRange.new(0.2, 0.8)
		emitter.Size = NumberSequence.new(0.1)
		emitter.Transparency = NumberSequence.new({NumberSequenceKeypoint.new(0, 0.5), NumberSequenceKeypoint.new(1, 1)})
		emitter.Color = ColorSequence.new(Color3.fromRGB(255, 220, 150))
		emitter.LightEmission = 0.3
		emitter.SpreadAngle = Vector2.new(180, 180)
		emitter.Parent = attach

		table.insert(attachments, attach)
	end
	print("[MenuSceneBuilder] " .. CONFIG.ParticleCount .. " ambient particle emitters created.")
	return attachments
end

-- ── Cleanup ────────────────────────────────────────────────
function MenuSceneBuilder:cleanupDefaults()
	-- Remove Studio's default Baseplate and hide SpawnLocation
	local bp = workspace:FindFirstChild("Baseplate")
	if bp then bp:Destroy() end
	local spawn = workspace:FindFirstChild("SpawnLocation")
	if spawn then spawn.Transparency = 1; spawn.CanCollide = false end
end

-- ── Main Build ───────────────────────────────────────────────
function MenuSceneBuilder:buildAll()
	print("[MenuSceneBuilder] Building menu scene...")

	self:cleanupDefaults()
	self:buildGround()
	self:placeHeroTree()
	self:scatterGrass(CONFIG.TreePosition)
	self:scatterRocks(CONFIG.TreePosition)
	self:createAmbientParticles()

	-- ── Invisible Walls (keep player in the scene) ──────────
	local wallSize = CONFIG.GroundSize
	local wallHeight = 20
	for _, neg in ipairs({-1, 1}) do
		for _, axis in ipairs({"X", "Z"}) do
			local wall = Instance.new("Part")
			wall.Name = "Boundary_" .. axis .. (neg == 1 and "Pos" or "Neg")
			wall.Size = axis == "X" and Vector3.new(1, wallHeight, wallSize * 2)
				or Vector3.new(wallSize * 2, wallHeight, 1)
			wall.Position = axis == "X" and Vector3.new(neg * wallSize, wallHeight / 2, 0)
				or Vector3.new(0, wallHeight / 2, neg * wallSize)
			wall.Anchored = true
			wall.Transparency = 1
			wall.CanCollide = true
			wall.Parent = workspace
		end
	end

	print("[MenuSceneBuilder] Menu scene build complete!")
end

return MenuSceneBuilder
