local Effects = {}
if script:GetAttribute("DebugMode") == true then debugmode = true else debugmode = false end
--Services
local Players = game:GetService("Players")
local PhysicsService = game:GetService("PhysicsService")
local CollectionService = game:GetService("CollectionService")
local SoundEffects = game:GetService("SoundService"):WaitForChild("SoundEffects")
--Player Variables
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
--Variables
local RNG = Random.new()

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Be careful editing beyond this point
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!

--[[
ClearLayers(model, total)
Args:
	model: model (Coin Stack)
Functionality:
	Makes a set amount of Coin parts inside the model invisible. The time it takes for the coins to be turned
	invisible is based on how many coins were dropped from the coin stack. The order in which the coins are made
	invisible is based on the layers CollectionService tag table. Four gets removed first, followed by three, then
	two, then one.
]]
function ClearLayers(model,total)
	local layers = {"LayerFour","LayerThree","LayerTwo","LayerOne"}
	local totalInLayers = 0
	local waitime = 0.03
	for i,v in pairs(model:GetChildren()) do
		if CollectionService:HasTag(v,"LayerFour") == true or CollectionService:HasTag(v,"LayerThree") == true or CollectionService:HasTag(v,"LayerTwo") == true or CollectionService:HasTag(v,"LayerOne")== true then
			totalInLayers += 1
		end
	end
	local amountRemoved = 0
	local amountToBeRemoved = math.ceil(15/4)
	if ((total * 0.03)/4)/totalInLayers < 0.03 then
		waitime = 0.03
	else
		waitime = ((total * 0.03)/4)/totalInLayers
	end
	for i,v in pairs(layers) do
		for x,y in pairs(model:GetChildren()) do
			if CollectionService:HasTag(y,v) and amountRemoved <= amountToBeRemoved then
				amountRemoved += 1
				y.Transparency = 1
				CollectionService:RemoveTag(y,v)
				CollectionService:AddTag(y,string.gsub(v,"Layer",""))
				task.wait(waitime)	
			end
		end
		if amountRemoved >= amountToBeRemoved then
			break
		end
	end
	for i,v in pairs(model:GetChildren()) do
		if CollectionService:HasTag(v,"LayerOne") == true then
			break
		else
			local fx1 = model.Area.Sparkles
			local fx2 = model.Core.Attachment
			for i,v in pairs(fx2:GetChildren()) do
				v.Enabled = false
			end
			fx1.Enabled = false
		end
	end
end

--[[
RestoreModel(model)
Args:
	model: model (Coin Stack)
Functionality:
	Restores the model to a fully pre-mined state (all coins are visible and the light/glow
	effects are on).
]]
function RestoreModel(model)
	local sfx = SoundEffects.StackAppear:Clone()
	sfx.Parent = model.PrimaryPart
	sfx:Destroy()
	local sfx2 = SoundEffects.StackAppear2:Clone()
	sfx2.Parent = model.PrimaryPart
	sfx2:Destroy()
	model.PrimaryPart.Smoke.Enabled = true
	task.wait(0.5)
	local layers = {"LayerOne","LayerTwo","LayerThree","LayerFour",}
	for i,v in pairs(layers) do
		for x,y in pairs(model:GetChildren()) do
			local temp = string.gsub(v,"Layer","")
			if CollectionService:HasTag(y,temp) then
				y.Transparency = 0
				CollectionService:RemoveTag(y,temp)
				CollectionService:AddTag(y,"Layer"..temp)
			end
		end
	end
	local fx1 = model.Area.Sparkles
	local fx2 = model.Core.Attachment
	for i,v in pairs(fx2:GetChildren()) do
		v.Enabled = true
	end
	fx1.Enabled = true
	model.PrimaryPart.Smoke.Enabled = false
end

--[[
ConnectGetRadius(object)
Args:
	object: BasePart (phyiscal currency object	)
Functionality:
	Creates a loop based on the object's distance from the client Player's HumanoidRootPart. 
	While the object exists (could also check for ancestrychanged to stop the loop), if the distance
	to the HumanoidRootPart is less than 5 studs or if too much time passes, the coin is automatically
	dragged towards the HumanoidRootPart and destroyed upon getting within 1 stud of it.
]]
function ConnectGetRadius(object)
	local passedTime = 0
	local timeout = RNG:NextInteger(2,4)
	while object do
		local distance = (Player.Character.HumanoidRootPart.Position - object.Position).magnitude
		if passedTime >= timeout or distance <= 5 then
			object.BillboardGui.AlwaysOnTop = false
			print("Coin found player, moving")
			local attach1 = Instance.new("Attachment")
			attach1.Parent = object
			local attach2 = Instance.new("Attachment")
			attach2.Parent = Character.HumanoidRootPart
			local lf = Instance.new("AlignPosition")
			lf.ApplyAtCenterOfMass = true
			lf.RigidityEnabled = true
			lf.Attachment0 = attach1
			lf.Attachment1 = attach2
			lf.Parent = Character.HumanoidRootPart	 
			task.spawn(function()
				while (Player.Character.HumanoidRootPart.Position - object.Position).magnitude > 1 do
					task.wait(0.1)			
				end
				game.ReplicatedStorage.Events.IncrementCurrencyAmount:Fire(object,6)
				attach2:Destroy() object:Destroy() lf:Destroy()
				if CollectionService:HasTag(object,"Coin") == true then
					local sfx = SoundEffects.CoinGet:Clone()
					sfx.Parent = Character.HumanoidRootPart
					sfx:Destroy()
				else
					local sfx = SoundEffects.GemGet:Clone()
					sfx.Parent = Character.HumanoidRootPart
					sfx:Destroy()
				end
				
			end)
			break
		end
		passedTime += 0.1
		task.wait(0.1)
	end
end

--[[
FlareStack(...)
Args:
	... : table (contains a model at the first index)
Functionality:
	Plays a flare effect on the given model.
]]
Effects["FlareStack"] = function(...)
	if debugmode == true then print("Start FlareStack") end
	local args = {...}
	assert(typeof(args[1] == "Model"),"FlareStack needs model")
	local fx1 = args[1].Area2.Sparkles
	local fx2 = args[1].Core2.Attachment
	for i,v in pairs(fx2:GetChildren()) do
		v:Emit(1)
	end
	fx1:Emit(20)
end

--[[
DropObjects(...)
Args:
	... : table (contains...
		a Player object,
		string "DropObjects",
		table LootPool,
		string CurrencyType,
		model CoinStack, 
		and number Health)
Functionality:
	Drops a certain amount of currency from the given model. The type and amount of currency dropped
	is based on the LootPool contents.
]]
Effects["DropObjects"] = function(...)
	if debugmode == true then print("Start DropObjects") end
	local args = {...}
	Effects["FlareStack"](args[5])
	local sfx = SoundEffects.CoinShower:Clone()
	sfx.Parent = args[5].PrimaryPart
	sfx:Destroy()
	local sfx = SoundEffects.ClickedStack:Clone()
	sfx.Parent = args[5].PrimaryPart
	sfx:Destroy()
	Effects["UpdateStackHP"](args[5],args[6])
	if debugmode == true then print(#args[3]) end
	task.spawn(function() ClearLayers(args[5],#args[3]) end)
	for i,v in pairs(args[3]) do
		local object
		if v == "Coin" then
			object = game.ReplicatedStorage.Assets.Coin:Clone()
		else
			object = game.ReplicatedStorage.Assets.Gem:Clone()
		end
		PhysicsService:SetPartCollisionGroup(object,"Coins")
		object.CFrame = args[5].PrimaryPart.CFrame
		object.Parent = workspace.LocalFX
		--sfx.PlaybackSpeed = RNG:NextNumber(1,1.05)
		local BodyVelocity = Instance.new("BodyVelocity")
		BodyVelocity.Velocity = Vector3.new(math.random(-20,20),math.random(40,75),math.random(-20,20))
		BodyVelocity.MaxForce = Vector3.new(1000,1000,1000)
		BodyVelocity.Parent = object
		game.Debris:AddItem(BodyVelocity,.1)	
		task.spawn(function() task.wait(0.5) ConnectGetRadius(object) end)
		task.wait()
	end
end

--[[
UpdateStackHP(...)
Args:
	... : table (contains a model (Coin Stack) and health (number)
Functionality:
	Updates the Health UI above the stack based on the amount of health passed.
]]
Effects["UpdateStackHP"] = function(...)
	local args = {...}
	local object = args[1]
	local health = args[2]
	local myhealthbar = object.Health.BG.HPBar
	local myredhealthbar =  object.Health.BG.RedHPBar
	local percent = math.floor((health/100)*100)
	myhealthbar:TweenSize(UDim2.new((health/100), 0, 0.85, 0),"Out","Sine",0.5,true)
	local currenthealthbarPosition = myhealthbar.Position.X.Scale
	if percent >= 67 then
		myhealthbar.BackgroundColor3 = Color3.fromRGB(0,255,0)
	elseif percent >= 34 and percent < 67 then
		myhealthbar.BackgroundColor3 = Color3.fromRGB(255, 204, 0)
	elseif percent < 34 then
		myhealthbar.BackgroundColor3 = Color3.fromRGB(255, 53, 3)
	end
	task.wait(0.1)
	myredhealthbar:TweenSize(UDim2.new((health/100)-0.001,0,0.85,0),"Out","Sine",0.5,true)
	if health == 0 then
		task.spawn(function() task.wait(0.65) Effects["RechargeStackHP"](object,health) end)
	end
end

--[[
RechargeStackHP(...)
Args:
	... : table (contains a model (Coin Stack) and health (number)
Functionality:
	Recharges the Health UI above the stack for 10 seconds.
]]
Effects["RechargeStackHP"] = function(...)
	local args = {...}
	local object = args[1]
	local health = args[2]
	local myhealthbar = object.Health.BG.HPBar
	local myredhealthbar =  object.Health.BG.RedHPBar
	local percent = math.floor((health/100)*100)
	myhealthbar.BackgroundColor3 = Color3.fromRGB(17, 216, 255)
	myhealthbar:TweenSize(UDim2.new(1, 0, 0.85, 0),"Out","Sine",10,true)
	CollectionService:AddTag(object,"Recharging")
	task.wait(10) --can also just use TweenService Completed
	CollectionService:RemoveTag(object,"Recharging")
	myhealthbar.BackgroundColor3 = Color3.fromRGB(0,255,0)
	myredhealthbar:TweenSize(UDim2.new(1-0.001,0,0.85,0),"Out","Sine",0.5,true)
	
end

--[[
RestoreStack(...)
Args:
	... : table (contains...
	a Player object,
	string "RestoreStack",
	and a model (Coin Stack)
Functionality:
	Fires the RestoreStack function. Used for server calls to RestoreStack.
]]
Effects["RestoreStack"] = function(...)
	local args = {...}
	RestoreModel(args[3])
end

--[[
SelectThisStack(...)
Args:
	... : table (contains...
	a Player object,
	string "RestoreStack",
	string state,
	and a model (Coin Stack)
Functionality:
	Enables or disables the selection effect on the given model
	depending on the given state.
]]
Effects["SelectThisStack"] = function(...)
	local args = {...}
	if args[3] == "On" then
		args[4].Health.Enabled = true
		args[4].SelectedStack.TargetBeamA.Enabled = true
		args[4].SelectedStack.TargetBeamB.Enabled = true
		args[4].SelectedStack.TargetBeamC.Enabled = true
		args[4].SelectedStack.TargetBeamD.Enabled = true
	else
		args[4].Health.Enabled = false
		args[4].SelectedStack.TargetBeamA.Enabled = false
		args[4].SelectedStack.TargetBeamB.Enabled = false
		args[4].SelectedStack.TargetBeamC.Enabled = false
		args[4].SelectedStack.TargetBeamD.Enabled = false
	end
	
end

return Effects
