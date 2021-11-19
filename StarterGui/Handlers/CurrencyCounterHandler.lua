--Resource Extractor/Coin Currency GUI Handler by DevSenju
--[[
HOW TO ADD NEW RESORUCES' GUI ON THE SCREEN AND ON THE PLAYER'S HEAD
	1) Add the model of the currency to ReplicatedStorage.Assets. Make sure the model contains a Billboard GUI with an ImageLabel
	   and is tagged with ONLY 1 CollectionService tag containing the name of the currency type. I recommend using the Instance Tagging plugin
	   by Sweetheartichoke for this.
	2) Copy and Paste a currency counter UI in StarterGui and rename it currencyName.."Counter" (e.g. SteelCounter). 
	   Be sure to replace any object names inside the new UI containing the previous currency's name with the new currency's name.
	   (e.g. SteelPickupObjects, SteelCoinAmount, SteelCoinLabel)
	3) Add an entry UI_HOLDER, PICKUP_OBJECTS_FOLDERS, TWEEN_REFS, FINAL_UI_HEIGHT, and TRACKERS. Here are the entry templates.
	   UI_HOLDER - [currencyName.."UI"] = Player.PlayerGui.currencyNameCounter.Background;
	   PICKUP_OBJECTS_FOLDERS - [currencyName.."UI"] = Player.PlayerGui.currencyNameCounter.Background.currencyNamePickupObjects;
	   TWEEN_REFS -
	   [currencyName.."UI"] = {
	   		["moneytweenref"] = {UI_HOLDER[currencyName.."UI"].currencyNameAmount.Total.TweenRef,UI_HOLDER[currencyName.."UI"].currencyAmount,"  anything"};
			["moneycolor"] = {UI_HOLDER[currencyName.."UI"].currencyNameAmount.MoneyColor,UI_HOLDER[currencyName.."UI"].currencyAmount};
			["refToTween"] = nil;
	   };
	   FINAL_UI_HEIGHT - ["currencyName"] = Vector3.new(X,Y,Z);
	   TRACKERS - ["currencyName"] = {}
	Watch out for warnings in the output!
]]


if script:GetAttribute("DebugMode") == true then debugmode = true else debugmode = false end
--Player Variables
local Player = game:GetService("Players").LocalPlayer
--Services
local TweenService = game:GetService("TweenService")
local CollectionService = game:GetService("CollectionService")
--GUI Variables
local UI_HOLDER = {
	["CoinUI"] = Player.PlayerGui.CoinCounter.Background;
	["GemUI"] = Player.PlayerGui.GemCounter.Background;
--  ["ExampleUI"] = Player.PlayerGui.ExampleCounter.Background;
}

local PICKUP_OBJECTS_FOLDERS = {
	["CoinUI"] = Player.PlayerGui.CoinCounter.Background.CoinPickupObjects;
	["GemUI"] = Player.PlayerGui.GemCounter.Background.GemPickupObjects;
--  ["ExampleUI"] = Player.PlayerGui.ExampleCounter.Background.ExamplePickupObjects;
}
local TWEEN_REFS = {
	["CoinUI"] = {
		["moneytweenref"] = {UI_HOLDER["CoinUI"].CoinAmount.Total.TweenRef,UI_HOLDER["CoinUI"].CoinAmount,"  ??"};
		["moneycolor"] = {UI_HOLDER["CoinUI"].CoinAmount.MoneyColor,UI_HOLDER["CoinUI"].CoinAmount};
		["refToTween"] = nil;
	};
	["GemUI"] = {
		["moneytweenref"] = {UI_HOLDER["GemUI"].GemAmount.Total.TweenRef,UI_HOLDER["GemUI"].GemAmount,"  ??"};
		["moneycolor"] = {UI_HOLDER["GemUI"].GemAmount.MoneyColor,UI_HOLDER["GemUI"].GemAmount};
		["refToTween"] = nil;
	};
	--[[
	["ExampleUI"] = {
		["moneytweenref"] = {UI_HOLDER["ExampleUI"].ExampleAmount.Total.TweenRef,UI_HOLDER["ExampleUI"].ExampleAmount,"  ??"};
		["moneycolor"] = {UI_HOLDER["ExampleUI"].ExampleAmount.MoneyColor,UI_HOLDER["ExampleUI"].ExampleAmount};
		["refToTween"] = nil;
	};
	--]]
}
--Other Variables
local GAINED_CURRENCY_COLOR = Color3.fromRGB(44, 255, 86)
local LOST_CURRENCY_COLOR = Color3.fromRGB(255, 65, 68)
local INTIAL_UI_HEIGHT = Vector3.new(0,1.2,0)
local FINAL_UI_HEIGHT  = {
	["Coin"] = Vector3.new(0,3,0);
	["Gem"] = Vector3.new(0,5,0);
--  ["Example"] = Vector3.new(0,6,0);
}
local TRACKERS = {
	["Coin"] = {};
	["Gem"]  = {};
--  ["Example"] = {};
}
--Other variables
local RNG = Random.new()

--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Be careful editing beyond this point
--!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!
--Update UI functions

--[[
Connects a Changed event to the currency text. When a given TweenRef is changed, the text on currency GUI will update to its value.
Connects a Changed event to currency color. When MoneyColor is changed, the color on currency GUI will update to its value.
For currency text tweening, there is an extra argument included in the TWEEN_REFS dictionary which describes what to concat 
to the end of the currency amount.
]]

for x,y in pairs(TWEEN_REFS)  do
	for i,v in pairs(y) do
		if type(v) == "table" then
			v[1].Changed:Connect(function(moving)
				if typeof(moving) == "number" then  --currency value then
					v[2].Text = moving..v[3]
				elseif typeof(moving) == "Color3" then
					v[2].TextColor3 = moving
				end
			end)
		end
	end
end



--[[
startTimeout(UI,saved)
Args:
	UI: holder GUI (total currency pickup)
	saved: int (time of pickup)
Functionality:
	startTimeout beings a countdown from the given time. Once time is up, the function will check if the current timeout
	on that iteration of the function is still valid. If so, it destroys the current total pickup counter.
]]

function startTimeout(UI,saved,tag)
	task.delay(3,function()
		if TRACKERS[tag] == saved then
			if debugmode == true then print("ShowCurrencyChangePlayer UI timeout") end
			UI.Name = "ToBeRemoved" 
			local transparencyTweenInfo = TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false)
			local transparencyTween = TweenService:Create(UI.PickupAmount,transparencyTweenInfo,{TextTransparency = 1,TextStrokeTransparency = 1})
			transparencyTween:Play()
			transparencyTween.Completed:Wait()
			UI:Destroy()
		else
			if debugmode == true then print("ShowCurrencyChangePlayer UI refresh") end
		end
	end)
end

--[[
playCurrencyTween(UI,studsoffset,transparencyTweenInfo,positionTweenInfo)
Args:
	UI: holder GUI (total currency pickup)
	studsoffset: Vector3 (the final location of the UI before timing out)
	transparencyTweenInfo: TweenInfo (UI transparency tween's properties)
	positionTweenInfo: TweenInfo (UI position tween's properties)
	isCheck: bool (is the current UI object new or did it exist already?)
Functionality:
	playCurrencyTween creates and plays the tweens on the total currency pickup that change its position and
	text trasparency. If the timer was already running (isCheck == true), reset the UI position to singal the
	timer resetting. It returns the time the tweens were run at.
]]
function playTotalCurrencyTween(UI,studsoffset,transparencyTweenInfo,positionTweenInfo,isCheck)
	local transparencyTween = TweenService:Create(UI.PickupAmount,transparencyTweenInfo,{TextTransparency = 0,TextStrokeTransparency = 0})
	local positionTween = TweenService:Create(UI,positionTweenInfo,{StudsOffset = studsoffset})
	if isCheck == true then
		UI.StudsOffset  = INTIAL_UI_HEIGHT
	end
	transparencyTween:Play()
	positionTween:Play()
	local saved = tick()
	return saved
end

--[[
ShowCurrencyChangePlayer(tag,diff)
Args:
	tag: string (name of object type)
	diff: int (amount to display)
Functionality:
	ShowCurrencyChangePlayer will create a Billboard GUI on the Player's Head that shows the total pickup amount of a currency set on a timer. 
	Once the timer runs out, the UI will fade away. The timer can be reset by picking up another instance of the same currency type.
	The only 2 supported currencies right now are Gems and Coins. The else statement will run for any outside currencies
	added. 
]]

function ShowCurrencyChangePlayer(tag,diff)
	local transparencyTweenInfo = TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false)
	local positionTweenInfo = TweenInfo.new(2,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false)
	local check = Player.Character.Head:FindFirstChild("ShowTotal"..tag.."Pickup")
	if check == nil then
		if debugmode == true then print("Start ShowCurrencyChangePlayer") end
		local findtemplate = game.ReplicatedStorage.Assets.UI:FindFirstChild("ShowTotal"..tag.."Pickup")
		if findtemplate then
			local template = findtemplate:Clone()
			if diff > 0 then
				template.PickupAmount.Text = "+"..diff
			else
				template.PickupAmount.TextColor3 = LOST_CURRENCY_COLOR
				template.PickupAmount.Text = diff
			end
			template.Parent = Player.Character.Head
			template.Adornee = Player.Character.Head
			local saved = playTotalCurrencyTween(template,FINAL_UI_HEIGHT[tag],transparencyTweenInfo,positionTweenInfo,false)
			TRACKERS[tag] = saved
			startTimeout(template,saved,tag)
		else
			warn("CurrencyCounterHandler could not find ShowTotal"..tag.."Pickup UI. Is it in the ReplicatedStorage.Assets.UI?")
			return
		end		
	else
		local spliced = string.gsub(check.PickupAmount.Text, "%D", "")
		check.PickupAmount.Text = "+"..(diff + spliced)
		local saved = playTotalCurrencyTween(check,FINAL_UI_HEIGHT[tag],transparencyTweenInfo,positionTweenInfo,true)
		TRACKERS[tag] = saved
		startTimeout(check,saved,tag)
	end
end

--[[
ShowCurrencyChangeUI(tag,diff)
Args:
	tag: string (name of object type)
	diff: int (amount to display)
Functionality:
	ShowCurrencyChangeUI will create a TextLabel GUI on the correspoding curreny GUI that shows the pickup amount of single piece of currency. 
	The only 2 supported currencies right now are Gems and Coins. The else statement will run for any outside currencies
	added. 
]]
function ShowCurrencyChangeUI(tag, diff)
	local template = game.ReplicatedStorage.Assets.UI.CoinNotification:Clone()
	if UI_HOLDER[tag] == nil then
		warn("ShowCurrencyChangeUI did not find "..tag.."'s UI. Is it in the UI_HOLDER table and StarterGui?")
		template:Destroy()
		return
	end
	template.Parent = PICKUP_OBJECTS_FOLDERS[tag]
	if diff > 0 then
		if debugmode == true then print("Start ShowCurrencyChangeUI +") end
		template.Text = "+"..diff
		local choices = {Enum.TextXAlignment.Left,Enum.TextXAlignment.Right,Enum.TextXAlignment.Center}
		local randomXAlignment = RNG:NextInteger(1,3)
		template.TextXAlignment = choices[randomXAlignment]
		local transparencyTweenInfo = TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,true)
		local positionTweenInfo = TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false)
		local transparencyTween = TweenService:Create(template,transparencyTweenInfo,{TextTransparency = 0,TextStrokeTransparency = 0})
		local positionTween = TweenService:Create(template,positionTweenInfo,{Position = UDim2.new(0.416,0,-2,0)})
		transparencyTween:Play()
		positionTween:Play()
		task.wait(1)
		template:Destroy()
	elseif diff < 0 then
		if debugmode == true then print("Start ShowCurrencyChangeUI -") end
		template.Text = diff
		template.TextColor3 = Color3.fromRGB(255, 65, 68)
		local choices = {Enum.TextXAlignment.Left,Enum.TextXAlignment.Right,Enum.TextXAlignment.Center}
		local randomXAlignment = RNG:NextInteger(1,3)
		template.TextXAlignment = choices[randomXAlignment]
		local transparencyTweenInfo = TweenInfo.new(0.3,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,true)
		local positionTweenInfo = TweenInfo.new(0.5,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false)
		local transparencyTween = TweenService:Create(template,transparencyTweenInfo,{TextTransparency = 0,TextStrokeTransparency = 0})
		local positionTween = TweenService:Create(template,positionTweenInfo,{Position = UDim2.new(0.416,0,2,0)})
		transparencyTween:Play()
		positionTween:Play()
		task.wait(1)
		template:Destroy()
	end
end

--[[
For loop that connects Changed events to each UI's Total IntValue. When changed, it will tween the total amount of coins up or down depending on
the new value's relation to the current value.
]]
for i,v in pairs(UI_HOLDER) do
	local total = v:FindFirstChild("Total",true)
	if total then
		total.Changed:Connect(function(val)
			if debugmode == true then print("Start Coin Amount Tween") end
			local show
			local colortween = TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false)
			local moneytween = TweenInfo.new(1,Enum.EasingStyle.Quad,Enum.EasingDirection.Out,0,false)
			local ryotween = TweenService:Create(TWEEN_REFS[i]["moneytweenref"][1], moneytween, {Value = val})
			local mycolor
			local backcolor
			local spliced = string.gsub(TWEEN_REFS[i]["moneytweenref"][2].Text, "%D", "")
			if val > tonumber(spliced) then
				mycolor = TweenService:Create(TWEEN_REFS[i]["moneycolor"][1],colortween,{Value = Color3.fromRGB(44, 255, 86)})
				backcolor = TweenService:Create(TWEEN_REFS[i]["moneycolor"][1],colortween,{Value = Color3.fromRGB(255, 255, 255)})		
			elseif val < tonumber(spliced) then
				mycolor = TweenService:Create(TWEEN_REFS[i]["moneycolor"][1],colortween,{Value = Color3.fromRGB(255, 48, 48)})
				backcolor = TweenService:Create(TWEEN_REFS[i]["moneycolor"][1],colortween,{Value = Color3.fromRGB(255, 255, 255)})	
			end
			print(TWEEN_REFS[i]["refToTween"])
			if TWEEN_REFS[i]["refToTween"] and TWEEN_REFS[i]["refToTween"].PlaybackState == Enum.PlaybackState.Playing then
				if debugmode == true then print("Coin Amount Previous Tween detected, pause it") end
				TWEEN_REFS[i]["refToTween"]:Pause()
			end
			TWEEN_REFS[i]["refToTween"] = mycolor
			mycolor:Play()
			ryotween:Play()
			ryotween.Completed:Wait()
			--print(refToTween.PlaybackState, mycolor.PlaybackState)
			if mycolor and (mycolor.PlaybackState == Enum.PlaybackState.Paused or mycolor.PlaybackState == Enum.PlaybackState.Cancelled ) then
				if debugmode == true then print("Coin Amount mycolor pause detected, end event") end
			else
				TWEEN_REFS[i]["refToTween"] = nil
				backcolor:Play()
			end
		end)
	else
		warn("Unable to find Total IntValue inside of "..v.Parent.Name".")
		return
	end
end

--[[
Bindable Event connection that updates the UIs on the Player and Player GUI whenever it is fired (a currency is collected)
]]
game.ReplicatedStorage.Events.IncrementCurrencyAmount.Event:Connect(function(obj,val)
	local onlytag = CollectionService:GetTags(obj)[1]
	if #CollectionService:GetTags(obj) > 2 then
		warn("Currency objects should only be tagged with the name of the currency. If you want more, edit this Connection.")
		return
	end
	TWEEN_REFS[onlytag.."UI"]["moneytweenref"][2].Total.Value += val
	ShowCurrencyChangePlayer(onlytag,val)
	ShowCurrencyChangeUI(onlytag.."UI",val)
end)
