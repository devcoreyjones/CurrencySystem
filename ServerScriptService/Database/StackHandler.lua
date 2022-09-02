--Resource Extractor/Coin PickupSystem by DevSenju
--Metatable Declaration
local StackHandler = {}
StackHandler.__index = StackHandler
local StackHandler_mt = {__index = StackHandler}
--Event Variables
local Events = game:GetService("ReplicatedStorage").Events
--Modules
local DB = game:GetService("ServerScriptService"):WaitForChild("Database")
local ItemList = require(DB:WaitForChild("ItemList"))
local plrData = require(DB:WaitForChild("plrDataManager"))
--Variables
local StackID = Random.new()
local RNG = Random.new()
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Be careful editing beyond this point
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

--[[
generateLootPool(lootinformation)
Args:
	lootinformation: dictionary (dictionary containing loot information)
Functionality:
	Takes in a table containing the loot information and uses it to generate the loot pool for a Coin Stack.
Returns:
    table (index 1 is a table containing the drop order of the items, index 2 contains a dictionary of the total amount of items droped for each currency)
]]
function generateLootPool(lootinformation)  -- 20,...,"Coin" --make sure coin is last
	local holdTotals = {}
	local holdObjs = {}
	for i,v in pairs (lootinformation["Currencies"]) do
		holdTotals[v] = 0
	end
	for i,v in pairs (holdTotals) do
		print(i,v)
	end
	for i = 1,lootinformation["Amount"] do
		local choice = RNG:NextInteger(1,100)
		for i,v in pairs(lootinformation["Currencies"]) do
			if choice < ItemList[v]["DropRate"] then
				table.insert(holdObjs,v)
				holdTotals[v] += 6
			end
		end
	end
	return {holdObjs,holdTotals}
end

--[[
StackHandler.new(player, object, lootinformation)
Args:
	player: Player instance (player who called the function)
	object: model (physical coin stack object)
	lootinformation: dictionary (contains an Amount index which is the total amount of
	objets in the loot pool and a Currencies index which lists all possible currencies
	minable from the coin stack)
Functionality:
	Creates a new StackHandler object for a Coin Stack. It stores a reference to the coin stack model,
	a random StackID, the health of the stack, generates the LootPool, and splits the LootPool up into 
	four seperate tables.
Returns:
    self (new Object of class StackHandler)
]]
function StackHandler.new(player,object,lootinformation)
	local self = {}
	self.Player = player
	self.Model = object
	self.StackID = StackID:NextInteger(1,100000)
	self.Health = 100
	self.AmountOfPools = 4
	self.ProcessedPools = 0
	self.LootPool = generateLootPool(lootinformation)
	self.AllLoot = {}
	self.movehere = math.floor((#self.LootPool[1]-(#self.LootPool[1] * 0.3))/4)
	for i = 1,4 do
		table.insert(self.AllLoot,{})
		if i == 4 then
			table.move(self.LootPool[1],(self.movehere*(i-1))+1,#self.LootPool[1],1,self.AllLoot[i])
		else
			table.move(self.LootPool[1],(self.movehere*(i-1))+1,self.movehere*i,1,self.AllLoot[i])
		end
	end
	return setmetatable(self, StackHandler);
end

--[[
StackHandler:GetModel()
Functionality:
	Returns the value referenced by the object's Model variable
Returns:
    model (object's Model variable)
]]
function StackHandler:GetModel()
	return self.Model
end

--[[
StackHandler:Mine()
Functionality:
	Mines a coin stack by processing one of its loot pools. This adds the contents of that loot pool to the player's data 
	shows an effect on the player's	client, and reduces the stack health for that player.
Returns:
    Health (number that represents the stack's health for that player)
]]
function StackHandler:Mine()
	self.ProcessedPools += 1
	for i,v in pairs(self.AllLoot[self.ProcessedPools]) do
		print("Add "..v.."s to player")
		plrData:EditUserData(self.Player,v.."s",plrData:GetUserData(self.Player,v.."s") + 1)
	end
	self.Health -= 25
	Events.Effects:FireClient(self.Player,self.Player,"DropObjects",self.AllLoot[self.ProcessedPools],"Coins",self.Model,self.Health)
	return self.Health
end

--[[
StackHandler:Destroy()
Functionality:
	Sets the self object to nil.
]]
function StackHandler:Destroy()
	table.clear(self)
	setmetatable(self, nil)
end

return StackHandler
