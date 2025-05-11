--Rbx Services
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local TweenService = game:GetService("TweenService")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")


--PlayerComponents
local Player : Player = game.Players.LocalPlayer
local Character : Model = Player.Character or Player.CharacterAdded:Wait()
--Set PrimaryPart to HumanoidRootPart cuz in R6 Default RootPart it`s Head
Character.PrimaryPart = Character:FindFirstChild("HumanoidRootPart")

local RootPart : BasePart = Character.PrimaryPart
local Torso = Character:WaitForChild("Torso")

local Humanoid : Humanoid = Character:FindFirstChildOfClass("Humanoid")
local Aniamtor : Animator = Humanoid:FindFirstChildOfClass("Animator")


local Mouse = Player:GetMouse() -- PlayerMouse



local PlayerCamera : Camera = workspace.CurrentCamera -- CurrentPlayerCamera


--Properties
local DefaultSpeed : number = 16
local UpSpeed : number = 24

local BobbingMulty : number = 10
local BobbingCFrame : CFrame = CFrame.new()

local IsRunning : boolean = false


local Rocket = ReplicatedStorage.Rocket
local offset = Vector3.new(250,0,0)

local SPEED = 600
local Itteration = 40

local Radius = 3
local KnivesCount = 20

--Folder for anims
local AnimationFolder : Folder = script.Anims

--KeyCodes
local KeyCodes = 
	{
		["Run"] = Enum.KeyCode.X;
		["RocketSpam"] = Enum.KeyCode.Q;
		["Fan of Knives"] = Enum.KeyCode.V;
	}


--Cache
local Cache = {}
local Tracks = {}



local function CheckOnAnimationTrack(TrackName) : AnimationTrack
	--return Tracks by name
	return Tracks[TrackName]
end

local function CheckOnAnimationRunning(TrackName) : boolean
	--Getting track by name
	local track = CheckOnAnimationTrack(TrackName)
	--if track then return it Play status
	if track then
		return track.IsPlaying
	end
	--if not track then return false
	return false
end


local BiezeModule = {}

local function lerp(a,b,t)
	--The Basic Lerp formula
	return a+(b-a) * t
end

function BiezeModule.elapsedTime(t)
	return 1-(1-2*t)^2
end

function BiezeModule.quadraticBieze(a,b,c,t)
	--calculate dots
	local dot1 = lerp(a,b,t)
	local dot2 = lerp(b,c,t)
	local finaledot = lerp(dot1,dot2,t)	

	return finaledot

end

local function PlayVFX(object : BasePart)
	--get all descendants from object cycle
	for _,v in pairs(object:GetDescendants()) do
		--if object(V) is "ParticleEmitter" then im Emmit this particle
		if v:IsA("ParticleEmitter") then
			v:Emit(v:GetAttribute("EmitCount"))
		end
	end

end

local function PlayAnimation(Humanoid : Humanoid)

	Cache["Run"] = RunService.Heartbeat:Connect(function()
		--Check if humanoid is moving or not
		local IsMove : boolean = Humanoid.MoveDirection.Magnitude > .01

		--if humanoid move
		if IsMove then
			--check on animation play
			if not CheckOnAnimationRunning("RunAnimation") then
				--if not then add to tracks animation track
				Tracks["RunAnimation"] = Aniamtor:LoadAnimation(AnimationFolder["Run"])
				--track play
				Tracks["RunAnimation"]:Play()
			end
		else
			-- if humanoid not move then stop animation
			if CheckOnAnimationRunning("RunAnimation") then
				Tracks["RunAnimation"]:Stop()
			end
		end

	end)

end

local function StopAnimation(Humanoid : Humanoid)
	
	if Cache["Run"] then
		--Clear Run connection
		Cache["Run"]:Disconnect()
		--chick if in cash have run animation and it running
		if CheckOnAnimationRunning("RunAnimation") then
			--get track
			local track = CheckOnAnimationTrack("RunAnimation")
			--animation stop
			track:Stop()
			--clear cache
			Tracks["RunAnimation"] = nil
		end
	end
	
end

--Functional map for abilities
local Map = 
	{
		[Enum.KeyCode.X] = function(status : boolean)
			if not status then return end

			--Check if Humanoid IsRunning
			if IsRunning then
				--SetHumanoidWalkSpeed
				Humanoid.WalkSpeed = DefaultSpeed
				StopAnimation(Humanoid)
				
			else
				--Set Humanoid WalkSpeed
				Humanoid.WalkSpeed = UpSpeed
				--add to cache heartBeat connection
				PlayAnimation(Humanoid)
				
				
			end
			--set Running boolean
			IsRunning = not IsRunning
		end,
		
		[Enum.KeyCode.Q] = function(status : boolean)
			-- if status == false then return
			if not status then return end
			
			--cycle on 10 itteration
			for i=1,10 do

				task.spawn(function()

					--Getting MousePos + offset
					local MousePos = Mouse.Hit.Position + CFrame.new(math.random(-i,i)*25,0,0).Position
					--Clone Rocket
					local FausClone = Rocket:Clone()
					--get magnitude 
					local magnitude = (Character.PrimaryPart.Position - MousePos).Magnitude

					--set parent
					FausClone.Parent = workspace
					--set anchored
					FausClone.PrimaryPart.Anchored = true

					
					local dot1 = Character.PrimaryPart.CFrame.LookVector  * -10
					local dot2 = MousePos + ((offset * Vector3.new(0,1,1)) + Vector3.new(0,25,0))

					local targetpos = BiezeModule.quadraticBieze(dot1,dot2,MousePos,1)
					local nextPos = BiezeModule.quadraticBieze(dot1,dot2,MousePos,1)

					--set Faus CFrame
					FausClone:PivotTo(CFrame.new(dot1))
					
					--Bieze properties
					local seed = math.random(0,10000)
					local freq = math.random(1,255)
					local amp = 5
					-- Bieze Math
					for i=1,Itteration do
						local t = magnitude/SPEED/Itteration
						local elapsed_time = BiezeModule.elapsedTime(t)
						
						--The Perlin noise
						local noise = Vector3.new(
							elapsed_time*amp*math.noise(0,t*freq,seed),
							elapsed_time*amp*math.noise(t*freq,0,seed),
							0)
						--Calculate targetpos
						targetpos = BiezeModule.quadraticBieze(dot1,dot2,MousePos,i/Itteration)
						nextPos = BiezeModule.quadraticBieze(dot1,dot2,MousePos,(i+1)/Itteration)
	
						local bizCFrame = CFrame.new(targetpos,nextPos)
						local pos = targetpos + bizCFrame.Rotation * noise
						--Move Rocket with TweenService
						TweenService:Create(FausClone.PrimaryPart, TweenInfo.new(t,Enum.EasingStyle.Linear),{CFrame = CFrame.new(pos,nextPos)* CFrame.Angles(math.rad(-90),0,0)}):Play()
						task.wait(.01)
					end
					--Set Rocket Transparency to 1
					for _,v in pairs(FausClone:GetDescendants()) do
						if v:IsA("BasePart") then
							v.Transparency = 1
						end
					end
					--Emit Vfx
					PlayVFX(FausClone)
				end)
				task.wait()
			end
			
		end,
		[Enum.KeyCode.V] = function(status : boolean)
			if not status then return end
			
			--Clonning vfxPart
			local vfxPart = ReplicatedStorage.VFX.VFXPart:Clone()
			--set vfxPart parent
			vfxPart.Parent = workspace
			--set vfxPart CFrame
			vfxPart:PivotTo(Character.PrimaryPart.CFrame + Character.PrimaryPart.CFrame.UpVector*-2)
			
			
			--Circle Spawn knifes cycle
			for x=1,360,360/KnivesCount do
				task.spawn(function()

					--CFrame`s
					--The First position (center)
					local centerCFrame = (Character.PrimaryPart.CFrame + Character.PrimaryPart.CFrame.UpVector * -5).Position
					--the second position middle
					local MidlePosition = ((Character.PrimaryPart.CFrame + Character.PrimaryPart.CFrame.UpVector * 1555) * CFrame.Angles(0,math.rad(x),0) * CFrame.new(0,0,-Radius)).Position
					--the end position 
					local EndPosition = (MidlePosition - Vector3.new(0,15,-x/5))
					
					--Clonned Knifes
					local FausClone = ReplicatedStorage.Fau2:Clone()
					FausClone.Parent = workspace
					FausClone:PivotTo(CFrame.new(centerCFrame,EndPosition) * CFrame.Angles(math.rad(90),0,0))
					--Biezer Math
					for i=1,Itteration do

						centerCFrame = (Character.PrimaryPart.CFrame + Character.PrimaryPart.CFrame.UpVector * -2).Position
						MidlePosition = ((Character.PrimaryPart.CFrame + Character.PrimaryPart.CFrame.UpVector * 15) * CFrame.Angles(0,math.rad(x),0) * CFrame.new(0,0,Radius + (i/15))).Position			
						EndPosition = ((Character.PrimaryPart.CFrame + Character.PrimaryPart.CFrame.UpVector * -5) * CFrame.Angles(0,math.rad(x),0) * CFrame.new(0,0,Radius + (i/5))).Position

						-- t getting from i/itteration`s
						
						local t = i/Itteration
						--future time 
						local t1 = (i+1)/Itteration
						--calcutate finale position
						local targetPos = CFrame.new(BiezeModule.quadraticBieze(centerCFrame,MidlePosition,EndPosition,t),BiezeModule.quadraticBieze(centerCFrame,MidlePosition,EndPosition,t1)) * CFrame.Angles(math.rad(-90),0,0)
						--Set Pivot to target pos and normalized rotation
						FausClone:PivotTo(targetPos * CFrame.Angles(0,math.rad(i),0))
						--wait for next itteration
						task.wait(.01)
					end
				end)

			end
			--Emit VFX
			PlayVFX(vfxPart)
		end,
	}



--Camera RunService
Cache["CameraBobbing"] = RunService.RenderStepped:Connect(function(dt)
	
	--Normalize MoveDirection
	local HumanoidMoveDirection = Humanoid.MoveDirection * Vector3.new(1,0,1) 
	--Check On Move
	local IsMove : boolean = Humanoid.MoveDirection.Magnitude > .01
	--ZDirection right/left
	local ZDirection = -math.round((HumanoidMoveDirection:Dot(PlayerCamera.CFrame.RightVector)))
	
	--Frame offset 1/60 ~ 60fps in second
	local offset = dt/(1/60)
	
	--Calulate BobbingCFrame
	BobbingCFrame = BobbingCFrame:Lerp(CFrame.Angles( 
		
		--Set X rotation from clock on sin in rad
		IsMove and math.rad(math.sin(os.clock() * BobbingMulty)/5.5) * offset,
		--Set Y rotation from clock on cos in rad
		IsMove and math.rad(math.cos(os.clock() * BobbingMulty)/5) * offset,
		--Set Z rotation from ZDirection  + offsets
		math.rad(ZDirection * 10) * offset
		),.05)
	--multy CFrame on BobbingCFrame
	PlayerCamera.CFrame *= BobbingCFrame
end)

--User Input 
Cache["UserInputBegan"] = UserInputService.InputBegan:Connect(function(input, event)
	
	for _,v in pairs(KeyCodes) do
		--Check On keycode in my dictionary
		if input.KeyCode == v then
			Map[v](true)
		end
	end
	
end)

-- User Input end
Cache["UserInputEnded"] = UserInputService.InputEnded:Connect(function(input, event)

	for _,v in pairs(KeyCodes) do
		if input.KeyCode == v then
			Map[v](false)
		end
	end

end)





--Get Joint`s
local RootJoint : Motor6D = RootPart:WaitForChild("RootJoint")
local Neck : Motor6D = Torso:WaitForChild("Neck")

--Get ZeroJoint`s
local ZeroJointC0 = RootJoint.C0
local ZeroJointNeckC0 = Neck.C1


Cache["BodyGyroSimulation"] = RunService.Heartbeat:Connect(function()
	if (not Character) then return end

	--Get Normalize MoveDirection
	local MoveDirection = -(Humanoid.MoveDirection * Vector3.new(1,0,1))
	--Get Front Direction
	local Front = MoveDirection:Dot(RootPart.CFrame.LookVector) * (Humanoid.WalkSpeed/2)
	--Get Right Direction
	local Right = MoveDirection:Dot(RootPart.CFrame.RightVector) * (Humanoid.WalkSpeed/2)

	--Clamped angle
	local FrontAngle = math.rad(math.clamp(Front,-30,30)) -- Clamp Front angle -30/30 
	local RightAngle = math.rad(math.clamp(Right,-10,10)) -- Clamp Right angle -10/10 
	
	--Lerp CFrame`s
	Neck.C1 = Neck.C1:Lerp(ZeroJointNeckC0 * CFrame.Angles(-FrontAngle,RightAngle/2,RightAngle * 3),.05)
	RootJoint.C0 = RootJoint.C0:Lerp(ZeroJointC0 * CFrame.Angles(-FrontAngle,RightAngle/2,RightAngle * 3),.05)

end)

--[[

Press ["X"] - for Run
Press ["Q"] - for Rocket Spam
Press ["V"] - for Fan of Knives



| Thansk for reading |

Made By ->

████████╗██╗░░██╗███████╗██╗░░░░░░█████╗░██╗░░░██╗██████╗░██████╗░
╚══██╔══╝██║░░██║██╔════╝██║░░░░░██╔══██╗╚██╗░██╔╝╚════██╗██╔══██╗
░░░██║░░░███████║█████╗░░██║░░░░░███████║░╚████╔╝░░█████╔╝██████╔╝
░░░██║░░░██╔══██║██╔══╝░░██║░░░░░██╔══██║░░╚██╔╝░░░╚═══██╗██╔══██╗
░░░██║░░░██║░░██║███████╗███████╗██║░░██║░░░██║░░░██████╔╝██║░░██║
░░░╚═╝░░░╚═╝░░╚═╝╚══════╝╚══════╝╚═╝░░╚═╝░░░╚═╝░░░╚═════╝░╚═╝░░╚═╝



]]



