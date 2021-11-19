--Resource Extractor/Coin PickupSystem by DevSenju
if script:GetAttribute("DebugMode") == true then debugmode = true else debugmode = false end
--Player Variables
local Players = game:GetService("Players")
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
--Services
local ContextActionService = game:GetService("ContextActionService")
local CollectionService = game:GetService("CollectionService")
local ContextActionService = game:GetService("ContextActionService")

--Modules
local ClickObject = require(game.ReplicatedStorage.ClientModules.ClickHandler)
local NMrequire = require(game:GetService("ReplicatedStorage"):WaitForChild("Nevermore"))
local ClientModules = game:GetService("ReplicatedStorage"):WaitForChild("ClientModules")
local Effects = require(ClientModules:WaitForChild("Effects"))
local TimeSyncService = NMrequire("TimeSyncService")
NMrequire("TimeSyncService"):Init()
syncedClock = TimeSyncService:WaitForSyncedClock()
--Events
local Events = game:GetService("ReplicatedStorage"):WaitForChild("Events",30)
local FX = Events:WaitForChild("Effects",30)
--Object holder
local Objects = {}
--Other variables
local FREEZE_ACTION  = "freezeMovement"
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Be careful editing beyond this point
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Helper Functions

--Function that creates a new ClickObject for every click detector found inside of a Coin Stack.
--[[
SetUpCoinStack(obj)
Args:
	UI: holder GUI (total currency pickup)
	saved: int (time of pickup)
Functionality:
	startTimeout beings a countdown from the given time. Once time is up, the function will check if the current timeout
	on that iteration of the function is still valid. If so, it destroys the current total pickup counter.
]]
local function SetUpCoinStack(obj)
	local ClickDetector = obj:FindFirstChild("GetPlayerClick")
	if ClickDetector then
		local clickConnection = ClickObject.new(ClickDetector)
		clickConnection:Begin()
		table.insert(Objects,clickConnection)
	end
end
--This code connects all existing CoinStack click detectors.
local CoinStacks = CollectionService:GetTagged("CoinStack")
for i,v in pairs(CoinStacks) do
	SetUpCoinStack(v)
end

--Connect newly created Coin Stacks' ClickDetector
local newCoinStackDetected = CollectionService:GetInstanceAddedSignal("CoinStack"):Connect(function(object)
	SetUpCoinStack(object)
end)

--Connect server events to Effect creation
FX.OnClientEvent:Connect(function(...)
	local args = {...}
	if debugmode == true then print("Start Effects FireClient:"..args[1].Name,", ",args[2]) end
	Effects[args[2]](...)
end)

--Binadble event that freezes or unfreezes player controls.
Events.Controls.Event:Connect(function(state)
	if state == "Enable" then
		ContextActionService:UnbindAction(FREEZE_ACTION)
	elseif state == "Disable" then
		ContextActionService:BindAction(
			FREEZE_ACTION,
			function()
				return Enum.ContextActionResult.Sink
			end,
			false,
			unpack(Enum.PlayerActions:GetEnumItems())
		)
	end
end)