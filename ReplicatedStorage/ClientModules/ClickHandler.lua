--Resource Extractor/Coin Currency Click Class Handler by DevSenju
--Metatable Declaration
local ClickHandler = {}
ClickHandler.__index = ClickHandler
local ClickHandler_mt = {__index = ClickHandler}
--Player Variables
local Player = game:GetService("Players").LocalPlayer
--Services
local CollectionService = game:GetService("CollectionService")
local ClientModules = game:GetService("ReplicatedStorage"):WaitForChild("ClientModules")
--Event Variables
local Events = game:GetService("ReplicatedStorage"):WaitForChild("Events",30)
local processClickRequest = Events:WaitForChild("processClickRequest",30)
--Modules
local Effects = require(ClientModules:WaitForChild("Effects"))
local Controls = require(game.Players.LocalPlayer.PlayerScripts:WaitForChild("PlayerModule")):GetControls()---GetControls
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Be careful editing beyond this point
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

--[[
ClickHandler.new(object)
Args:
	object: model (ClickDetector in a coin stack)
Functionality:
	Creates a new Click object for a ClickDetector/Coin Stack. It stores a reference to the coin stack model,
	the clickdetector, and a nil connection (for now.)
Returns:
    self (new Object of class ClickHandler)
]]
function ClickHandler.new(object)
	local self = {}
	self.Model = object.Parent
	self.ClickDetector = object
	self.Connection = nil
	return setmetatable(self, ClickHandler_mt);
end

--[[
ClickHandler:Begin()
Functionality:
	Attempts to setup the MouseClick event for a Click object. If it has already been setup, this function does nothing.
	If it has not been setup, it creates a MouseClick event. First, the event turns off any existing stack selection effects.
	Then, it makes the player walk over to the object's model if the player is not in range and disables player control. 
	Once the player is in range, it will fire to the server to process a stack mine on the current object and reenable
	controls if they were disabled earlier.
	Honestly this could just be in the .new function but I seperated it for clarity.
]]
function ClickHandler:Begin()
	if self.Connnection then
	else
		local connection = self.ClickDetector.MouseClick:connect(function()
			print("Click detected!")
			for i,v in pairs(CollectionService:GetTagged("Selected"))  do
				if v ~= self.Model then
					Effects["SelectThisStack"](nil,nil,"Off",v)
				end
			end
			if CollectionService:HasTag(self.Model,"Recharging") == false then
				Effects["SelectThisStack"](nil,nil,"On",self.Model)
				CollectionService:AddTag(self.Model,"Selected")
			end
			if (Player.Character.HumanoidRootPart.Position - self.Model.PrimaryPart.Position).magnitude < 5 then
				processClickRequest:FireServer("Coins",self.Model)
			else
				Events.Controls:Fire("Disable")
				local con 
				con = Player.Character.Humanoid.MoveToFinished:Connect(function(reached)  --can timeout...			
					con:Disconnect()
					con = nil
					processClickRequest:FireServer("Coins",self.Model)
					Events.Controls:Fire("Enable")
				end)
				
				Player.Character.Humanoid:MoveTo((self.Model.PrimaryPart.CFrame * CFrame.new(0,0,5)).p)
			end
		end)
		self.Connection = connection
	end
end

--[[
ClickHandler:GetConnected()
Functionality:
	Getter for the status of the object's Connection variable.
Returns:
    bool
]]
function ClickHandler:GetConnected()
	if self.Connection == nil or self.Connection.Connected == false then
		return false
	end
	return true
end

return ClickHandler
