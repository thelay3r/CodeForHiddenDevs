local TweenService = game:GetService("TweenService")

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Assets = ReplicatedStorage:WaitForChild("Assets")

local AuraLifeTime = 3 -- AuraLife Time

local BiezeModule = require(script.Parent.BiezeModule) -- module for bezier curve
local CameraShake = require(script.CameraShaker) -- Open Source Camera Shake Module

--Get the player camera
local PlayerCamera = workspace.CurrentCamera

--Setup Shake Module
local _CameraShake = CameraShake.new(Enum.RenderPriority.Camera.Value+1,function(_Cframe)
	PlayerCamera.CFrame *= _Cframe
end)
_CameraShake:Start()

local Replication = {}

local Cache = {}

local UtilitiesModule do -- an local environment to control VFX movement, etc
	
	function MoveSpell(object: BasePart, finishPosition: Vector3, Velocity: number)
		
		local Time = ((object.Position - finishPosition).Magnitude + 10)/Velocity
		local FrameRate = 60 -- set to 60 so we can animate vfx movement each frame (considering the selected client fps is 60)
		local Frames = Time*FrameRate
		
		local StartPosition: Vector3 = object.Position
		local MiddlePosition: Vector3 = (StartPosition + finishPosition)/2 + Vector3.new(math.random(-10,10),math.random(10,20),math.random(-10,10))
		
		for i=0,Frames do  -- loop to animate bezier curve
			local t=i/Frames
			
			local LerpProduct = BiezeModule.quadraticBieze(StartPosition,MiddlePosition,finishPosition,t)
			object.Position = LerpProduct
			task.wait(1/FrameRate)
		end
		
	end
	
	function CalculatePosition(object: BasePart,Position: Vector3) --Calculate the position of the object
		
		local Params = RaycastParams.new()
		Params.FilterType = Enum.RaycastFilterType.Exclude
		Params.FilterDescendantsInstances = {object}
		--Default Raycast Params
		
		--Fire Raycast
		local cast = workspace:Raycast(Position,Vector3.new(0,-5,0),Params)
		if not cast then object.Position = Position return object end
		
		--Calculate ResultCframe to position
		local ResultCFrame: CFrame = CFrame.new(cast.Position,cast.Position+cast.Normal) * CFrame.Angles(math.rad(-90),0,0)

		
		return ResultCFrame
	end
	
	
	--Random Vector function
	function RandomVector(min,max)
		min *= 10
		max *= 10
		return Vector3.new(math.random(min,max)/10,math.random(min,max)/10,math.random(min,max)/10)
	end
	
	--SpawnRock at CFrame or without CFrame
	function SpawnRock(SpawnCFrame: CFrame): BasePart
		
		local Rock = Instance.new("Part",workspace)
		Rock.Size = RandomVector(2,4)
		--Anchor rock
		Rock.Anchored = true
		-- do it massles
		Rock.Massless = true
		
		if not SpawnCFrame then return end
		Rock.CFrame = SpawnCFrame
		
		return Rock
	end
	
	--Function when sound be play without anchor like part or smth
	function PlaySoundWithoutAnchor(Sound:Sound,OriginCFrame: CFrame)
		
		--Spawn Anchor Part
		local SoundPart = SpawnRock(OriginCFrame)
		SoundPart.Transparency = 1
		SoundPart.CanCollide = false
		
		--Set sound Parent
		Sound.Parent = SoundPart
		--Play Sound
		Sound:Play()
		--When Sound end destroy part and sound
		Sound.Ended:Once(function()
			Sound:Destroy()
			SoundPart:Destroy()
		end)
		
	end
	
	--Function for make rocks
	function MakeCrater(config: {})
		
		--Get Basics values
		local CenterCFrame = config.CFrame
		local Radius = config.Radius
		local RockCount = config.RockCount
		
		--raycast params
		local CastParams = RaycastParams.new()
		CastParams.FilterType = Enum.RaycastFilterType.Include
		CastParams.FilterDescendantsInstances = {workspace.Map}
		
		--Play sound
		PlaySoundWithoutAnchor(script.Rock_Impact:Clone(),CenterCFrame)
		PlaySoundWithoutAnchor(script.Rock_Impact2:Clone(),CenterCFrame)
		
		_CameraShake:ShakeOnce(5,25,0,.3)
		
		--cycle for rocks
		for i=0,360,360/((RockCount) or 4) do
			
			--get the origin cframe, at the radius distance from the center cframe
			local OriginCFrame = CenterCFrame * CFrame.Angles(0,math.rad(i),0) * CFrame.new(0,0,-Radius)
			
			--fire raycast
			local cast = workspace:Raycast(OriginCFrame.Position + Vector3.new(0,5,0),Vector3.new(0,-10,0),CastParams)
			if not cast then continue end
			--if not cast then we continue the loop, cuz we dont want to make rock if raycast didnt hit anything
			--and it`s dont work without cast
			
			--get the position of the hit
			local RockCFrame = CFrame.new(cast.Position,cast.Position + cast.Normal) * CFrame.Angles(math.rad(90),0,0)
			--normalize the cframe
			local FinaleCFrame = RockCFrame * CFrame.Angles(math.rad(math.random(-40,40)),math.rad(math.random(-40,40)),math.rad(math.random(-40,40)))
			--spawn rock at the position of the hit + random offset
			
			--if we have in config FlyRock value, then we spawn rock with velocity
			if config.FlyRock then
				
				--spawn rock`s
				local FlyRock: BasePart = SpawnRock(FinaleCFrame)
				FlyRock.Material = cast.Material
				FlyRock.Color = cast.Instance.Color
				FlyRock.Anchored = false
				FlyRock.CanCollide = false
				FlyRock.Size/=2
				
				--spawn velocity
				local BodyVelocity = Instance.new("BodyVelocity",FlyRock)
				BodyVelocity.Velocity = RandomVector(-25,25)
				BodyVelocity.Velocity = Vector3.new(BodyVelocity.Velocity.X,math.abs(BodyVelocity.Velocity.Y) * 2,BodyVelocity.Velocity.Z)
				BodyVelocity.P = math.huge
				
				--destroy velocity after 0.3 sec
				task.delay(.3,function()
					BodyVelocity:Destroy()
					task.wait(1)
					FlyRock:Destroy()
				end)
			end
			
			--Base rock`s spawn
			local Rock: BasePart = SpawnRock(FinaleCFrame - Vector3.new(0,4,0))
			--set Material
			Rock.Material = cast.Material
			--set color
			Rock.Color = cast.Instance.Color
			
			--TweenService for position
			TweenService:Create(Rock,TweenInfo.new(.3,Enum.EasingStyle.Back,Enum.EasingDirection.Out),
				{
					CFrame = FinaleCFrame - Vector3.new(0,1,0)
				}):Play()
			
			--destroy rock`s after they lifetime + itteration
			task.delay(config.LifeTime + i/360,function()
				--Tween for animation destroy rocks
				local EndTween = TweenService:Create(Rock,TweenInfo.new(1,Enum.EasingStyle.Sine),
					{
						Size = Vector3.zero;
					})
				EndTween:Play()
				
				EndTween.Completed:Once(function()
					Rock:Destroy()
				end)
			end)
		end
		
	end
	
end

local EffectModule do -- an local environment to control VFX
	
	local EffectCallbacks = { -- a table of functions that will be called on the VFX
		["ParticleEmitter"] = function(self: ParticleEmitter,properties: {})
			self:Emit(self:GetAttribute("EmitCount") or 1)
			self.Enabled = properties.Enabled
		end,
		
		
		["Beam"] = function(self: Beam, properties: {})
			self.Enabled = true
			
			if not properties.Disable then return end
			
			local FrameRate = 60
			local Frames = properties.Time*FrameRate
			
			task.spawn(function()
				for i=1,Frames do
					local t = i/Frames
					self.Transparency = NumberSequence.new(self.Transparency.Keypoints[1].Value + t)
					task.wait(1/FrameRate)
				end
			end)

			
		end,

		["Trail"] = function(self: Trail, properties: {})
			self.Enabled = true
		end,
		["PointLight"] = function(self: PointLight, properties: {})
			
			local Twen = TweenService:Create(self,TweenInfo.new((properties.Time) or (.3),Enum.EasingStyle.Sine),
				{
					Brightness = properties.Brightness;
				})
			Twen:Play()
			
		end,
	}
	
	function PlayObjectsVFX(Object: BasePart,properties: {}) -- to play all the VFX in the object
		local Descendants = Object:GetDescendants()
		
		for _,v in pairs(Descendants) do
			if EffectCallbacks[v.ClassName] then
			   EffectCallbacks[v.ClassName](v,properties)
			end
		end
	end
	
end

function Replication:ReplicateGUI(Caster: Player, HealAmmount: number)

	--get the character
	local Character: Model = Caster.Character
	--clone Gui
	local HealGUI: BillboardGui = script.Heal:Clone()
	
	--TweenInfo presets
	local TweenInfoIn = TweenInfo.new(.5,Enum.EasingStyle.Exponential,Enum.EasingDirection.InOut)
	local TweenInfoOut = TweenInfo.new(.75,Enum.EasingStyle.Exponential,Enum.EasingDirection.Out)

	--Play Sound
	PlaySoundWithoutAnchor(script.healed:Clone(),Character.PrimaryPart.CFrame)
	--Set Parent
	HealGUI.Parent = Character.Head
	
	--TweenService for animate
	TweenService:Create(HealGUI,TweenInfoIn,
		{
			SizeOffset = Vector2.new(math.random(-20,20)/10,math.random(10,30)/10)

		}):Play()
	
	--destroy gui after .4 second`s
	task.delay(.4,function()
		local Tween = TweenService:Create(HealGUI,TweenInfoOut,
			{
				SizeOffset = Vector2.new(HealGUI.SizeOffset.X + math.random(-5,5),math.random(-4,-3))

			})
		Tween:Play()
		Tween.Completed:Once(function()
			HealGUI:Destroy()
		end)

	end)
end

function Replication:ReplicateSpell(Caster: Player, mousePosition: Vector3)

	local Character: Model = Caster.Character -- default stuff to find primary part
	assert(Character, "Character doesnt exist")
	
	local RootPart: BasePart = Character.PrimaryPart
	assert(RootPart, "RootPart doesnt exist")
	
	--offset for mouse
	local Offset = Vector3.new(0,1,0)
	local newMousePosition = mousePosition+Offset
	
	--Clone the basic VFX
	local StarVFX: BasePart  = Assets:WaitForChild("Star"):Clone()
	StarVFX.Parent = workspace
	StarVFX.CFrame = RootPart.CFrame + Vector3.new(0,5,0)
	
	local StartedVFX: BasePart = Assets:WaitForChild("Started"):Clone()
	StartedVFX.Parent = workspace
	StartedVFX.CFrame = StarVFX.CFrame
	

	
	local Aura: BasePart = Assets:WaitForChild("Aura"):Clone()
	
	--Play VFX`S
	PlayObjectsVFX(StartedVFX,
		{
			Enabled = true;	
		})
	--Move our projectile to mousePosition with Lerp
	MoveSpell(StarVFX,newMousePosition,30)
	
	--Set vfx to the position of mouse
	Aura.Parent = workspace
	Aura.CFrame = (CalculatePosition(Aura,newMousePosition) + Aura.CFrame.UpVector * 7) --* CFrame.Angles(math.pi,0,0)
	
	--Play SFX
	PlaySoundWithoutAnchor(script.HealAura:Clone(),Aura.CFrame)
	
	--Make some Rock`s
	MakeCrater(
		{
			CFrame = CFrame.new(newMousePosition);
			Radius = 10;
			RockCount = 25;
			LifeTime = 3;
			FlyRock = true;
		})
	MakeCrater(
		{
			CFrame = CFrame.new(newMousePosition);
			Radius = 15;
			RockCount = 6;
			LifeTime = 2;
			FlyRock = true;
		})
	--Disalbe VFX
	PlayObjectsVFX(StarVFX,
		{
			Enabled = false;
			Brightness = 0;
			Time = .3;
		})
	--Enable VFX
	PlayObjectsVFX(Aura,
		{
			Brightness = 3;
			Time = .3;
			Enabled = true;
		})
	
	--Destroy vfx
	task.delay(AuraLifeTime,function()
		PlayObjectsVFX(Aura,
			{
				Brightness = 0;
				Time = .3;
				Enabled = false;
				Disable = true;
			})
		
		task.wait(1)
		Aura:Destroy()
		StartedVFX:Destroy()
		StarVFX:Destroy()
	end)
	
	
	
end

return Replication
