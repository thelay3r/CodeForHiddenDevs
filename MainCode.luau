--Services
local UserInputService = game:GetService("UserInputService")
local TweenService = game:GetService("TweenService")
local Lighting = game:GetService("Lighting")


--Player Components
local Player = game.Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
--


local KeyCode = Enum.KeyCode.Q -- KeyBind

local Assets = script:WaitForChild("Assets") -- Assets Folder

local CameraShaker = require(script.CameraShaker) -- OpenSource ShakeModule
local Camera = workspace.CurrentCamera -- Main Camera

local debounce = false -- CoolDown on Button


local ColorCorrection = Lighting.ColorCorrection

local Rightoffset = 10 -- Offset on CFrame
local LookOffset = 5 --  Offset on CFrame


--Gui Components 
local PlayerGUI = Player.PlayerGui
local Hud = PlayerGUI.Hud
local Eyes = Hud.Eyes
--

--Settings For humanoid
local NormalWalkSpeed = 16
local NormalJumpPower = 50
--

--Setup CameraShake
local CameraModule = CameraShaker.new(Enum.RenderPriority.Camera.Value +1,function(Cframe)
	Camera.CFrame *= Cframe
end)
CameraModule:Start()
--


--Change transparency 
local function OpenEyes()
	local _Time = 1
	local EyesTween = TweenService:Create(Eyes,TweenInfo.new(_Time,Enum.EasingStyle.Sine),
		{
			BackgroundTransparency = 0
		})
	EyesTween:Play()
	
end

--Reset ColorCorrection to default
local function ResetSetColorCorrection()

	local TweenTime = 1
	local CorrectionTween = TweenService:Create(ColorCorrection,TweenInfo.new(TweenTime,Enum.EasingStyle.Sine)
		,{
			Saturation = 0;
			TintColor = Color3.fromRGB(255, 255, 255)
		})
	CorrectionTween:Play()

end


--Set ColorCorrection
local function SetColorCorrection()
	
	local TweenTime = 1
	local CorrectionTween = TweenService:Create(ColorCorrection,TweenInfo.new(TweenTime,Enum.EasingStyle.Sine)
		,{
			Saturation = 1;
			TintColor = Color3.fromRGB(233, 213, 255)
		})
	CorrectionTween:Play()
	
end
--Set transparency to background
local function CloseEyes()
	local _Time = 1
	local EyesTween = TweenService:Create(Eyes,TweenInfo.new(_Time,Enum.EasingStyle.Sine),
		{
			BackgroundTransparency =1
		})
	EyesTween:Play()

end

--Enable/Disable vfx 
local function ChangeVFXStatus(object : BasePart,status : boolean)
	
	for _,v in pairs(object:GetDescendants()) do
		if v:IsA("ParticleEmitter") then
			v.Enabled = status
		end
		if v:IsA("Beam") then
			v.Enabled = status
		end
	end
	
end

--Method on create Rock
local function CreateRock()
	local Rock = Instance.new("Part",workspace)
	Rock.Size = Vector3.one *(math.random(10,25)/10)
	Rock.Anchored = true
	Rock.CanCollide = false
	
	
	return Rock
end

--Main Method on spawn rocks
local function SimulationRock(_CFrame : CFrame,_time : number)
	
	local RockRightOffset = 5
	
	for i=1,60*_time do
		
		for x=-1,1,2 do
			
			local NewCFrame = _CFrame * CFrame.Angles(0,math.rad(-90),0) -- Normalize CFrame
			
			--RayCast
			local cast = workspace:Raycast(NewCFrame.Position + NewCFrame.LookVector * i,Vector3.new(0,-5,0))
			if not cast then continue end
			--
			
			local Part = CreateRock() -- spawn rock
			

			
			
			Part.Material = cast.Material -- GetMaterial from cast instance
			Part.Color = cast.Instance.Color -- GetColor from cast instance
			
			--Normalize CFrame after cast, and do random angles
			Part.CFrame = (CFrame.new(cast.Position,cast.Position + cast.Normal) * CFrame.Angles(math.rad(90),0,0)) + NewCFrame.RightVector * (RockRightOffset * x)
			Part.CFrame *= CFrame.Angles(math.rad(math.random(-30,30)),math.rad(math.random(-30,30)),math.rad(math.random(-30,30)))
			--
			
			--Spawn Animation on Rocks
			Part.Position -= Vector3.new(0,3,0)
			TweenService:Create(Part,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.InOut),
				{
					Position = Part.Position + Vector3.new(0,3,0)
				}):Play()
			task.delay(3,function()
				TweenService:Create(Part,TweenInfo.new(.3,Enum.EasingStyle.Sine),
					{
						Size = Vector3.zero
					}):Play()
				task.wait(.3)
				Part:Destroy()
			end)
			--
			
		end
		task.wait(1/60) 
	end
	
end

--Reset Humanoid Settings to default
local function ResetHumanoidToDefault(Humanoid : Humanoid)

	Humanoid.WalkSpeed = NormalWalkSpeed
	Humanoid.JumpPower = NormalJumpPower

end

--Set humanoid settings
local function ChangeHumanoid(Humanoid : Humanoid)
	
	Humanoid.WalkSpeed = 0
	Humanoid.JumpPower = 0
	
end


--Main input system
UserInputService.InputBegan:Connect(function(input,event)
	if (input.KeyCode ~= KeyCode) or (event) or (debounce) then return end -- Check player input
	debounce = true -- set debounce on true
	
	local RootPart = Character.PrimaryPart -- Character RootPart
	
	--Clone some assets
	local Blue = Assets.Blue:Clone()
	local Red = Assets.Red:Clone()
	local Purple = Assets.Purple:Clone()
	-- 
	
	--Humanoid Setup
	local Humanoid : Humanoid = Character:FindFirstChildOfClass("Humanoid")
	Humanoid.UseJumpPower = true
	ChangeHumanoid(Humanoid)
	--
	
	--Spawn Blue & Red and Normalize CFrame`s
	Blue.CFrame = RootPart.CFrame + (RootPart.CFrame.RightVector * -Rightoffset) + (RootPart.CFrame.LookVector * LookOffset)
	Red.CFrame = ((RootPart.CFrame + RootPart.CFrame.RightVector * Rightoffset) + (RootPart.CFrame.LookVector * LookOffset)) * CFrame.Angles(0,math.pi,0)

	--Set parent to workspace
	Blue.Parent = workspace
	--CameraShake
	CameraModule:ShakeOnce(5,50,0,.5)
	task.wait(1/2) -- wait for impact
	Red.Parent = workspace
	CameraModule:ShakeOnce(5,50,0,.5)

	--Enable VFX
	ChangeVFXStatus(Blue,true)
	ChangeVFXStatus(Red,true)
	--
	
	task.wait(1/2)
	--Main CFrame
	local EndCFrame = RootPart.CFrame + RootPart.CFrame.LookVector * LookOffset
	
	--Create TweenService for smooth anims
	local BlueTween = TweenService:Create(Blue,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
		{
			CFrame = EndCFrame
		})
	local RedTween = TweenService:Create(Red,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.InOut),
		{
			CFrame = EndCFrame * CFrame.Angles(0,math.pi,0)
		})
	
	BlueTween:Play()
	RedTween:Play()
	--
	
	--When Tween Completed destroy Blue & Red
	BlueTween.Completed:Once(function()
		ChangeVFXStatus(Blue,false)
		Blue:Destroy()
		ChangeVFXStatus(Red,false)
		Red:Destroy()
	end)

	
	task.wait(2)
	
	--Spawn Purple 
	Purple.CFrame = EndCFrame * CFrame.Angles(0,math.rad(90),0) -- Normalize CFrame
	Purple.Parent = workspace
	CameraModule:ShakeOnce(10,75,0,.5)
	
	--Set HUD
	OpenEyes()
	SetColorCorrection()
	--
	task.wait(1)
	--Rock Simalutaion
	task.spawn(SimulationRock,Purple.CFrame,2)

	--Start PurpleTween
	local PurpleTween = TweenService:Create(Purple,TweenInfo.new(2,Enum.EasingStyle.Sine,Enum.EasingDirection.In),
		{
			CFrame = (EndCFrame  + RootPart.CFrame.LookVector * 150) * CFrame.Angles(0,math.rad(90),0)
		})
	PurpleTween:Play()
	CameraModule:ShakeOnce(4,35,0,2)
	
	--When PurpleTween Completed, reset all to default & destroy purple
	PurpleTween.Completed:Once(function()
		ChangeVFXStatus(Purple,false)
		CloseEyes()
		ResetSetColorCorrection()
		Purple:Destroy()
		
		ResetHumanoidToDefault(Humanoid)
		
		debounce = false 
	end)
	
end)

--[[

| Thansk for reading |

Made By ->

████████╗██╗░░██╗███████╗██╗░░░░░░█████╗░██╗░░░██╗██████╗░██████╗░
╚══██╔══╝██║░░██║██╔════╝██║░░░░░██╔══██╗╚██╗░██╔╝╚════██╗██╔══██╗
░░░██║░░░███████║█████╗░░██║░░░░░███████║░╚████╔╝░░█████╔╝██████╔╝
░░░██║░░░██╔══██║██╔══╝░░██║░░░░░██╔══██║░░╚██╔╝░░░╚═══██╗██╔══██╗
░░░██║░░░██║░░██║███████╗███████╗██║░░██║░░░██║░░░██████╔╝██║░░██║
░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝

]]