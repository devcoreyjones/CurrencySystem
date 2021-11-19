--Resource Extractor/Coin PickupSystem by DevSenju
local module = {}
--Services
local DataStoreService = game:GetService("DataStoreService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
--Modules
local ProfileService = require(game.ServerScriptService.Database.ProfileService)
--Variables
local cachedProfiles = {}
local ProfileTemplate = {
	["Name"] = "Default",
	["LoginAmount"] = 0,
	["LastLoginTime"] = 0,
	["Coins"] = 0,
	["Gems"] = 0
}
--ProfileStore loading
local ProfileStore = ProfileService.GetProfileStore(
	"PlayerData",
	ProfileTemplate
)

--Uncomment these lines to allow saving.
--if game:GetService("RunService"):IsStudio() == true then
	--print("Studio, run mock")
	ProfileStore = ProfileStore.Mock
--end

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Be careful editing beyond this point
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

--[[
PlayerAdded(player)
Args:
	player: Player Instance (player who joined the game)
Functionality:
	Attempts to load the ProfileStore profile associated with the joining player's UserID.
]]
local function PlayerAdded(player)
	local profile = ProfileStore:LoadProfileAsync("Player_" .. player.UserId)
	if profile ~= nil then
		if player:IsDescendantOf(Players) == true then
			cachedProfiles[player] = profile
			-- A profile has been successfully loaded:
			profile:AddUserId(player.UserId)
			profile:Reconcile()
			profile:ListenToRelease(function()
				cachedProfiles[player] = nil
				-- The profile could've been loaded on another Roblox server:
				player:Kick("Data loaded on another server.")
			end)
			print("Player data loaded.")
			--DoSomethingWithALoadedProfile(player, profile)
		else
			-- Player left before the profile loaded:
			cachedProfiles[player] = nil
			profile:Release()
		end

	else
		player:Kick("Data failed to load properly. Please rejoin.")
	end
end

--[[
If players were already in-game before this module could run, perform the PlayerAdded function on them.
]]
for _, player in ipairs(Players:GetPlayers()) do
	task.spawn(PlayerAdded, player)
end

Players.PlayerAdded:Connect(PlayerAdded)

--[[
When a player leaves, release their profile. For the deployment version of this, comment out the WipeProfileAsync call.
]]
Players.PlayerRemoving:Connect(function(player)
	local profile = cachedProfiles[player]
	if profile ~= nil then
		profile:Release()
		ProfileStore:WipeProfileAsync("Player_" .. player.UserId)
	end
end)


--[[
EditUserData(Player,Data,NewValue)
Args:
	Player: Player Instance (player who joined the game)
	Data: string (index to be edited)
	NewValue: Data's value type (new value for Data index)
Functionality:
	Attempts to change the given Data index of a Player's data to the given 
	NewValue.
]]
function module:EditUserData(Player,Data,NewValue)
	print("starting edituserchardata")
	local find = module:GetUserData(Player,"All")
	if find and typeof(find[Data]) == typeof(NewValue) then
		find[Data] = NewValue
		print("Data changed")	
	end
end

--[[
GetUserData(Player,Category)
Args:
	Player: Player Instance (player whose data needs to be found)
	Category: string (index to be found)
Functionality:
	Attempts to find and return the dictionary located at index Category. If the Category is "All", it
	returns all Player data.
Returns:
    Dictionary (player data to be used)
    or
    bool (false to signify the function did not find the correct data)
]]
function module:GetUserData(Player,Category)
	print("starting getuserdata")
	if cachedProfiles[Player] ~= nil then
		if Category == "All" then
			print("returned all")
			return cachedProfiles[Player].Data
		elseif cachedProfiles[Player].Data[Category] ~= nil then
			print("returned "..Player.Name.." "..Category)
			return cachedProfiles[Player].Data[Category]
		else 
			warn("Unknown command for GetUserData.")
			return false
		end
	else
		warn("No player data...")
		return false
	end
end

--[[
GetPlayerProfile(Player)
Args:
	Player: Player Instance (player whose profile needs to be found)
Functionality:
	Attempts to find and return the profile associated with the given player.
Returns:
	Profile (profile Object)
]]
function module:GetPlayerProfile(Player)
	local profile = cachedProfiles[Player]
	if profile and profile:IsActive() == true then
		return profile
	else
		return nil
	end
end

--[[
GetPlayerProfileAsync(Player)
Args:
	Player: Player Instance (player whose profile needs to be found)
Functionality:
	Attempts to continously find and return the profile associated with the given player.
	If the profile does not exist, the code will keep requesting it until it does exist or 
	the player leaves the game.
Returns:
	Profile (profile Object)
]]
function module:GetPlayerProfileAsync(Player)
	local profile = cachedProfiles[Player]
	while profile == nil and Player:IsDescendantOf(Players) == true do
		task.wait()
		profile = cachedProfiles[Player]
	end
	return profile
end

return module
