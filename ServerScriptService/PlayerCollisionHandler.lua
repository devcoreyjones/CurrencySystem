--Free code from the Roblox Developer Wiki: https://developer.roblox.com/en-us/articles/Player-Player-Collisions
local PhysicsService = game:GetService("PhysicsService")
local Players = game:GetService("Players")

PhysicsService:CreateCollisionGroup("CoinStacks")
PhysicsService:CreateCollisionGroup("Coins")
PhysicsService:CreateCollisionGroup("Players")

PhysicsService:CollisionGroupSetCollidable("CoinStacks", "Coins", false)
PhysicsService:CollisionGroupSetCollidable("Coins", "Coins", false)
PhysicsService:CollisionGroupSetCollidable("Players", "Coins", false)


local previousCollisionGroups = {}

local function setCollisionGroup(object)
	if object:IsA("BasePart") then
		previousCollisionGroups[object] = object.CollisionGroupId
		PhysicsService:SetPartCollisionGroup(object, "Players")
	end
end

local function setCollisionGroupRecursive(object)
	setCollisionGroup(object)

	for _, child in ipairs(object:GetChildren()) do
		setCollisionGroupRecursive(child)
	end
end

local function resetCollisionGroup(object)
	local previousCollisionGroupId = previousCollisionGroups[object]
	if not previousCollisionGroupId then return end 

	local previousCollisionGroupName = PhysicsService:GetCollisionGroupName(previousCollisionGroupId)
	if not previousCollisionGroupName then return end

	PhysicsService:SetPartCollisionGroup(object, previousCollisionGroupName)
	previousCollisionGroups[object] = nil
end

local function onCharacterAdded(character)
	setCollisionGroupRecursive(character)

	character.DescendantAdded:Connect(setCollisionGroup)
	character.DescendantRemoving:Connect(resetCollisionGroup)
end

local function onPlayerAdded(player)
	player.CharacterAdded:Connect(onCharacterAdded)
end

Players.PlayerAdded:Connect(onPlayerAdded)