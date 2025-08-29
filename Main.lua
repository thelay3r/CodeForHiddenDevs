--[[
MADE BY -

\* ╔╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╗ */
\* ╟┼┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┼╢ */
\* ╟┤                                                ├╢ */
\* ╟┤ __       ______   __    __    __    ____       ├╢ */
\* ╟┤/\ \     /\  _  \ /\ \  /\ \ /'__`\ /\  _`\     ├╢ */
\* ╟┤\ \ \    \ \ \L\ \\ `\`\\/'//\_\L\ \\ \ \L\ \   ├╢ */
\* ╟┤ \ \ \  __\ \  __ \`\ `\ /' \/_/_\_<_\ \ ,  /   ├╢ */
\* ╟┤  \ \ \L\ \\ \ \/\ \ `\ \ \   /\ \L\ \\ \ \\ \  ├╢ */
\* ╟┤   \ \____/ \ \_\ \_\  \ \_\  \ \____/ \ \_\ \_\├╢ */
\* ╟┤    \/___/   \/_/\/_/   \/_/   \/___/   \/_/\/ /├╢ */
\* ╟┤                                                ├╢ */
\* ╟┼┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┼╢ */
\* ╚╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╝ */

]]

-- Spell casting system with visual effects, physics, and camera shake
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")
local ContentProvider = game:GetService("ContentProvider")
local Lighting = game:GetService("Lighting")


-- All game assets are stored here
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")
local Anims = ReplicatedStorage:WaitForChild("Anims")

-- Camera effects module for realistic shake
local CameraShake = require(Modules:WaitForChild("CameraShaker"))

-- Configuration for easy adjustments
local Config = {
	KeyBind = Enum.KeyCode.Q,
	MaxDistance = 150,
	CoolDown = false;
	CoolDownTime = 1;
	HeightOffset = Vector3.new(0,29,0),
	ExplosionAngle = CFrame.Angles(math.pi, 0, 0),
	RockSettings = {
		MinSize = 30,
		MaxSize = 60,
		VelocityRange = {
			X = {-120, 120},
			Y = {50, 240},
			Z = {-120, 120}
		}
	};
	FovConfig = 
		{
			Default = 70;
			Explosion = 110;
		}
}

-- Player character setup
local Player = Players.LocalPlayer
--Wait for Character, im used default Player.Character and CharacterAdded event for evaded nil character
local Character = Player.Character or Player.CharacterAdded:Wait()
--[[
	im used WaitForChild 'humanoid', because sometimes player dont have humanoid when script started 
	because player may have have bad internet or smth
	and script will be errored because of nil humanoid
]]
local Humanoid = Character:WaitForChild("Humanoid")
--Same as above
local RootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart
--Get player Camera from Workspace
local PlayerCamera = Workspace.CurrentCamera

--Getting player GUI
local PlayerGUI = Player.PlayerGui
--Wait for Vignette gui
local Vignette = PlayerGUI:WaitForChild("Vignette")

--Wait for color correction folder, for additional impact
local ExplosionTemplate = Lighting:WaitForChild("ExplosionCC")

--[[
	Stores all active event connections, to avoid memory leaks
	below I disable all Connections when Humanoid died 
]]
local ActiveConnections = {}

--[[
	Store all humanoid animations, to avoid memory leaks
	To avoid loading the animation every time, I'll simply retrieve it from the cache
	This approach improves performance by reusing already loaded animations
]]
local AnimationCache = {}

local DustCount = 0
--[[
	Counter for Gui, to avoid 'math.random' because random can give same results
	
	(like math.random(1,3))
	-> 1
	-> 3
	-> 1
	-> 1
]]



-- Setup raycasting parameters once, to avoid repeating the code (DRY - don't repeat yourself)
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.FilterDescendantsInstances = {Workspace.Ignore, Character}

-- Initialize camera shake effect
--The function gives CFrame, im multiplying Camera.CFrame by Module CFrame
local Shaker = CameraShake.new(Enum.RenderPriority.Camera.Value+1, function(cf)
	PlayerCamera.CFrame *= cf
end)
--Launch the module for camera shake
Shaker:Start()

--[[
	Pre load animations, im use ContentProvider for preloading animations to avoide
	Anim laging and delays when player cast spells
]]
ContentProvider:PreloadAsync({Anims.Cast})

-- Creates randomly sized rocks for natural look
local function CreateRandomRock(material, color)
	--Using Instance class for creating part
	local rock = Instance.new("Part")
	--Set rock parent to ignore folder
	--[[
		im getting random size for each axis, to make the setup more flexible
		for changeing size of rock, you need to change X Y Z in config
	]]
	local sizeX = math.random(Config.RockSettings.MinSize, Config.RockSettings.MaxSize)/10
	local sizeY = math.random(Config.RockSettings.MinSize, Config.RockSettings.MaxSize)/10
	local sizeZ = math.random(Config.RockSettings.MinSize, Config.RockSettings.MaxSize)/10
	--Set Size to rock from 3x variables
	rock.Size = Vector3.new(sizeX, sizeY, sizeZ)
	--Set material and color for rock if it doesn`t exist then use default roblox Material
	rock.Material = material or Enum.Material.Rock
	rock.Color = color or Color3.new(0.5, 0.5, 0.5)
	--Set Booleans for part
	rock.Anchored = true
	rock.CanCollide = false
	rock.Parent = workspace.Ignore
	return rock
end

-- Calculates where spell should land based on mouse position
local function CalculateTargetPosition()
	--Get mouse position
	local mousePos = Player:GetMouse().Hit.Position
	--[[
		Default roblox GetMouse it works very poorly
		then im create custom function to get player mouse corectrly
		To get mouse position i use this:
	
		set direction:  get unit from this (mouse position - RootPart.Position) * Config.MaxDistance
		and then raycast from RootPart to that direction
		
		if ray hits something, return that position, 
		otherwise return max distance away 
		(RootPart.Position + direction(Unit))
	]]
	local direction = (mousePos - RootPart.Position).Unit * Config.MaxDistance 
	local rayResult = Workspace:Raycast(RootPart.Position, direction, RayParams)
	--If ray hits something, return that position, otherwise return max distance away
	return rayResult and rayResult.Position or (RootPart.Position + direction)
end

-- Makes rocks fly away from impact point
local function LaunchRocks(position, hitData, duration)
	--Create Rock
	local rock = CreateRandomRock(hitData.Material, hitData.Instance.Color)
	--[[
		Set Physics properties for rock
	]]
	rock.Position = position
	rock.Anchored = false
	rock.Massless = true

	rock.Size /=2

	--[[
		Multiplying Cframe by random angles to make rocks rotation in different directions
	]]
	rock.CFrame = rock.CFrame * CFrame.Angles(
		math.rad(math.random(-80, 80)),
		math.rad(math.random(-80, 80)),
		math.rad(math.random(-80, 80))
	)

	--[[
		Add BodyVelocity to rock to make it fly
		and getting random velocity for rocks from Config
	]]
	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = Vector3.new(
		math.random(Config.RockSettings.VelocityRange.X[1], Config.RockSettings.VelocityRange.X[2]),
		math.random(Config.RockSettings.VelocityRange.Y[1], Config.RockSettings.VelocityRange.Y[2]),
		math.random(Config.RockSettings.VelocityRange.Z[1], Config.RockSettings.VelocityRange.Z[2])
	)
	--[[
		I set parent for bodyVelocity to rock after set all properties
	
	]]
	velocity.Parent = rock

	--[[
		Using task.delay for destroying velocity after duration
	]]
	task.delay(duration, function()
		velocity:Destroy()
	end)
end



-- Creates circular crater effect at target position
local function GenerateCrater(centerPos, rockCount, radius, lifetime)
	-- get step from dividing 360 by rock count
	local angleStep = 360 / rockCount
	
	--Start from 0 angle and rotate by step for each rock
	for angle = 0, 360, angleStep do
		-- set rayOrigin to centerPos + 25 studs in Y axis
		local rayOrigin = centerPos + Vector3.new(0, 25, 0)
		-- set rayDirection to 100 studs in Y axis
		local rayDirection = Vector3.new(0, -100, 0)
		-- Raycast from rayOrigin to rayDirection, if ray hits something, then create rock at hit position
		local hit = Workspace:Raycast(rayOrigin, rayDirection, RayParams)
		if not hit then print("Returne") continue end

		--[[
			Create rock at hit position
			im put material and color from cast result, to make it look more beautiful
		]]
		local rock = CreateRandomRock(hit.Material, hit.Instance.Color)
		--I get distance from radius and add random offset to it (randomizer)
		local distance = math.random(radius/1.2, radius)
		--Set rock CFrame on caluculated CFrame
		rock.CFrame = CFrame.new(hit.Position) * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, distance)

		--[[
			Im adding some rotation to rock to like it some tilted	
		]]
		rock.CFrame = rock.CFrame * CFrame.Angles(
			math.rad(math.random(-25, 25)),
			math.rad(math.random(-10, 10)),
			0
		)

		-- Launch fly rocks after
		LaunchRocks(hit.Position, hit, 0.4)

		--[[
			im use delay for destroy rocks after lifetime
			And im using TweenService to make it smooth
		]]
		task.delay(lifetime, function()
			TweenService:Create(rock, TweenInfo.new(lifetime), {
				Transparency = 1,
				Size = Vector3.zero
			}):Play()
		end)
	end
end

-- Triggers all visual effects in an object
local function ActivateEffects(object)
	if not object:IsA("BasePart") then return end
	--Get all ParticleEmitter and emit them
	for _,effect in pairs(object:GetDescendants()) do
		if effect:IsA("ParticleEmitter") then
			effect:Emit(effect:GetAttribute("EmitCount") or 1)
		end
	end
end


--[[
	-> CopY Sound function <-
	
	im using this function to clone sound from Sounds folder and play it
	and destroy it after completed
]]
-- Copy Sound by name from Sounds folder
local function CopySound(SoundName,Played: boolean)
	--Find Sound in Sounds folder
	local Sound: Sound = Sounds:FindFirstChild(SoundName)
	if not Sound then return end
	--Clone sound
	local ClonnedSound = Sound:Clone()
	--Set parent to Character
	ClonnedSound.Parent = Character.PrimaryPart
	--Check on Player and Sound
	if not Played then return ClonnedSound end
	-- if Player true then we played sound and destroy it on completed
	ClonnedSound:Play()
	--[[
		Why im use Once? it will run only one time and cleanup, or we have other way to place it in ActiveConnections, 
		but thats way not readable
	]]
	ClonnedSound.Ended:Once(function()
		--Destroy sound
		ClonnedSound:Destroy()
	end)
end

-- Create Dust effect on GUI
local function CreateDust()
	local Dust = Vignette:FindFirstChild("Dust")
	
	--Incremeant Dust counter
	DustCount +=1
	--Check if dust count is over 2, reset it
	if DustCount >= 2  then
		DustCount = 1
	end
	--Change Image texture to next one
	Dust.Image = Dust[DustCount].Texture

	--[[
		Im use TweenService to make smooth transition from 0 to 1
		also im use Once when Tween Completed to cleanup connection and reset ImageTransparency with Texture
	]]
	--Setup Tween 
	local DustTween = TweenService:Create(Dust,TweenInfo.new(.7,Enum.EasingStyle.Sine),
		{
			ImageTransparency = 1
		})
	--Start Tween
	DustTween:Play()
	--When Tween completed reset Dust GUI
	DustTween.Completed:Once(function()
		Dust.Image = ""
		Dust.ImageTransparency = 0
	end)
	
end

--[[
	Create Correction on Explosion
	
	im using this to make correction on explosion
	and using TweenService to make it smooth,
	im using Once to cleanup connection and destroy correction
]]
local function CreateCorrection()

	--Clone CC folder
	local CcFolder = ExplosionTemplate:Clone()
	--Add it to Lighting
	for _,v in pairs(CcFolder:GetChildren()) do
		v.Parent = Lighting
		--Case for Blur
		if v:IsA("BlurEffect") then
			--Reseting Blur
			local CCTween = TweenService:Create(v,TweenInfo.new(.5,Enum.EasingStyle.Sine),
				{
					Size = 0
				})
			CCTween:Play()
			--Destroy when tween completed
			CCTween.Completed:Once(function()
				v:Destroy()
			end)
		end
		--Case for CC
		if v:IsA("ColorCorrectionEffect") then
			--Reseting CC
			local CCTween = TweenService:Create(v,TweenInfo.new(.5,Enum.EasingStyle.Sine),
				{
					Brightness = 0;
					Contrast = 0;
					Saturation = 0;
				})
			CCTween:Play()
			--Destroy when tween completed
			CCTween.Completed:Once(function()
				v:Destroy()
			end)
		end
	end

end

--[[
	Create FOV Tween
	
	I use this to make smooth transition of FOV
	and using Once to cleanup connection and create another Tween for returning to default fov
]]
local function ChangeFOV()
	--Tween for smooth change Fov
	local CameraTween = TweenService:Create(PlayerCamera,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
		{
			FieldOfView = Config.FovConfig.Explosion
		})
	CameraTween:Play()
	--When tween completed reset camera to default fov
	CameraTween.Completed:Once(function()
		TweenService:Create(PlayerCamera,TweenInfo.new(.3,Enum.EasingStyle.Sine),
			{
				FieldOfView = Config.FovConfig.Default
			}):Play()
	end)
	
end

--Play Animantion
local function PlayAnimation()
	
	--Get Animator from humanoid
	local Animator: Animator = Humanoid:FindFirstChildOfClass("Animator")
	--Load animation to Humanoid Animator
	local track = AnimationCache["Cast"] or Animator:LoadAnimation(Anims:FindFirstChild("Cast"))
	AnimationCache["Cast"] = track
	--Play animation
	AnimationCache["Cast"]:Play()
	--Set Looped to false if animation is looped
	AnimationCache["Cast"].Looped = false
end

-- Handles the spell casting sequence
local function CastSpell()
	--Find mouse position
	local targetPos = CalculateTargetPosition()
	if not targetPos then return end

	-- Create main explosion effect
	local explosion = Assets.Explosion:Clone()
	explosion.Parent = Workspace.Ignore
	explosion:PivotTo(CFrame.new(targetPos) * Config.ExplosionAngle + Config.HeightOffset)

	-- Animate character upward
	RootPart.Anchored = true

	--Tween for lift character
	TweenService:Create(RootPart, TweenInfo.new(0.5), {
		CFrame = RootPart.CFrame + Vector3.new(0, 50, 0)
	}):Play()
	
	--Play Sound
	CopySound("AirWosh",true)
	--Play Animation
	PlayAnimation()
	-- Sequence of spell effects
	task.delay(0.6, function()
		RootPart.Anchored = false
		Shaker:ShakeOnce(5, 50, 0, 0.3)

		-- Trigger different effect parts
		ActivateEffects(explosion.Dummy)
		task.wait(0.1)
		ActivateEffects(explosion.Impact)
		--Play Sound
		CopySound("Explosion",true)
		
		--Start some Functions
		CreateDust()
		CreateCorrection()
		ChangeFOV()
		-- Create crater effects
		GenerateCrater(targetPos, 35, 30, 1)
		GenerateCrater(targetPos, 25, 20, 1.5)
	end)
end



-- Setup input listener for spell casting
ActiveConnections.InputBegan = UserInputService.InputBegan:Connect(function(input,event)
	--Check on key code and if it event(game processed)
	if input.KeyCode == Config.KeyBind and not event then
		-- check on cooldown
		if Config.CoolDown then return end
		--set cooldown flag on true
		Config.CoolDown = true
		--cast speel
		CastSpell()
		--delay for set flag to false
		task.delay(Config.CoolDownTime,function()
			Config.CoolDown = false
		end)
	end
end)

-- Cleanup when character dies
Humanoid.Died:Once(function()
	for _,conn in pairs(ActiveConnections) do
		conn:Disconnect()
	end
	for name,v: AnimationTrack in pairs(AnimationCache) do
		v:Stop()
		AnimationCache[name] = nil
	end
	
	--[[
		Why im use table.clear? for cleanUp tables on full without memory leak`s
	]]
	table.clear(ActiveConnections)
	table.clear(AnimationCache)
end)

--[[
MADE BY -

\* ╔╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╤╗ */
\* ╟┼┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┴┼╢ */
\* ╟┤                                                ├╢ */
\* ╟┤ __       ______   __    __    __    ____       ├╢ */
\* ╟┤/\ \     /\  _  \ /\ \  /\ \ /'__`\ /\  _`\     ├╢ */
\* ╟┤\ \ \    \ \ \L\ \\ `\`\\/'//\_\L\ \\ \ \L\ \   ├╢ */
\* ╟┤ \ \ \  __\ \  __ \`\ `\ /' \/_/_\_<_\ \ ,  /   ├╢ */
\* ╟┤  \ \ \L\ \\ \ \/\ \ `\ \ \   /\ \L\ \\ \ \\ \  ├╢ */
\* ╟┤   \ \____/ \ \_\ \_\  \ \_\  \ \____/ \ \_\ \_\├╢ */
\* ╟┤    \/___/   \/_/\/_/   \/_/   \/___/   \/_/\/ /├╢ */
\* ╟┤                                                ├╢ */
\* ╟┼┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┬┼╢ */
\* ╚╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╧╝ */


]]