--Resource Extractor/Coin PickupSystem by DevSenju
if script:GetAttribute("DebugMode") == true then debugmode = true else debugmode = false end
--Server Variables
local RNG = Random.new()
--Events
local Events = game:GetService("ReplicatedStorage").Events
--Modules
local StackHandler = require(game:GetService("ServerScriptService").Database.StackHandler)
--Table to store player cooldowns
local playerClickCooldowns = {}
--Table to store total player objects that exist
local allRechargingPlayerStacks = {}
local allPlayerStacks = {}
local playerCurrentStack = {}
--
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Be careful editing beyond this point
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--[[
ProcessClickRequest(player, objecttype, objectmodel)
Args:
	player: Player instance (player who called the function)
	objecttype: string (name of type of currency stack to be processed)
	objectmodel: model (physical coin stack object)
Functionality:
	ProcessClickRequest will attempt to mine coins from a coin stack for the given player. Once a
	valid request had been recieved, it will create a StackHandler object or find the StackHandler 
	object related to that specific Coin Stack model for that specific player. If the player does 
	not leave the range of the selected stack, select a different stack, and the stack still has 
	health left, the stack will be continuously mined until any condition is not fufilled.
]]
local function ProcessClickRequest(player,objecttype,objectmodel)
	if debugmode == true then print("Start ProcessClickRequest") end
	assert(objecttype == "Coins" or objecttype == "Gems","Invalid objectttpe")
	assert((player.Character.HumanoidRootPart.Position - objectmodel.PrimaryPart.Position).magnitude < 10,"Player faraway")
	if playerClickCooldowns[player.Name] == true then
		print(player.Name.."is clicking too fast. Reject server request")
	else
		playerClickCooldowns[player.Name] = true
		if allPlayerStacks[player.Name] == nil then
			allPlayerStacks[player.Name] = {}
		end
		if allRechargingPlayerStacks[player.Name] == nil then
			allRechargingPlayerStacks[player.Name] = {}
		end
		if playerCurrentStack[player.Name] == nil then
			playerCurrentStack[player.Name] = {}
		end
		
		for i,v in pairs(allRechargingPlayerStacks[player.Name]) do
			if v == objectmodel  then
				if debugmode == true then print("Stack recharging") end
				task.wait(0.5)
				playerClickCooldowns[player.Name] = false
				return
			end
		end
		
		local foundPreviousStack = nil
		for i,v in pairs(allPlayerStacks[player.Name]) do
			if v:GetModel() == objectmodel   then
				if debugmode == true then print("Found existing stack data") end
				foundPreviousStack = v
				if foundPreviousStack.Health == 0 then
					if debugmode == true then print("Dead stack data") end
					foundPreviousStack:Destroy()
					foundPreviousStack = nil
				else
					if debugmode == true then print("Living stack data") end
					if foundPreviousStack == playerCurrentStack[player.Name] then
						if debugmode == true then print("Clicked same stack, exit") end
							task.wait(0.5)
							playerClickCooldowns[player.Name] = false
						return
					end
					break
				end
				
			else
			end
		end
		if foundPreviousStack == nil then
			if debugmode == true then print("Create new stack data") end
			foundPreviousStack = StackHandler.new(player,objectmodel,{["Amount"] = 20,["Currencies"] = {"Gem","Coin"}})
			table.insert(allPlayerStacks[player.Name],foundPreviousStack)
		else
		end
		playerCurrentStack[player.Name] = foundPreviousStack
		if debugmode == true then print("ProcessClickRequest passed for player "..player.Name) end
		task.spawn(function()
			while playerCurrentStack[player.Name] == foundPreviousStack and (player.Character.HumanoidRootPart.Position - playerCurrentStack[player.Name]:GetModel().PrimaryPart.Position).magnitude < 10 do
				local remainingHealth = playerCurrentStack[player.Name]:Mine()
				if remainingHealth == 0 then
					local model = foundPreviousStack:GetModel()
					table.insert(allRechargingPlayerStacks[player.Name],model)
					if debugmode == true then print("Start Stack HP Recharge "..player.Name) end
					Events.Effects:FireClient(player,player,"SelectThisStack","Off",model)
					task.delay(11.5, function() 
						for i,v in pairs (allRechargingPlayerStacks[player.Name]) do
							if v ==	model then
								table.remove(allRechargingPlayerStacks[player.Name],i)
								Events.Effects:FireClient(player,player,"RestoreStack",model)
								break
							end
						end
					end)
					break
				end
				wait(1)
				if playerCurrentStack[player.Name] == foundPreviousStack then
					if debugmode == true then print("Same stack for mining: "..player.Name) end
				else 
					if debugmode == true then print("Mining stack swap: "..player.Name) end
				end
			end
			if (player.Character.HumanoidRootPart.Position - playerCurrentStack[player.Name]:GetModel().PrimaryPart.Position).magnitude > 10 and playerCurrentStack[player.Name] == foundPreviousStack then
				Events.Effects:FireClient(player,player,"SelectThisStack","Off",playerCurrentStack[player.Name]:GetModel())
				playerCurrentStack[player.Name] = {}
			end
		end)
		if debugmode == true then print("Sent Effects FireClient signal to "..player.Name) end
		task.wait(0.5)
		playerClickCooldowns[player.Name] = false
	end
end

Events.processClickRequest.OnServerEvent:Connect(ProcessClickRequest)