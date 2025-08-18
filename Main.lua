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

-- All game assets are stored here
local Modules = ReplicatedStorage:WaitForChild("Modules")
local Assets = ReplicatedStorage:WaitForChild("Assets")
local Sounds = ReplicatedStorage:WaitForChild("Sounds")

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
	}
}

-- Player character setup
local Player = Players.LocalPlayer
local Character = Player.Character or Player.CharacterAdded:Wait()
local Humanoid = Character:WaitForChild("Humanoid")
local RootPart = Character:WaitForChild("HumanoidRootPart") :: BasePart
local PlayerCamera = Workspace.CurrentCamera

-- Stores all active event connections
local ActiveConnections = {}

-- Setup raycasting parameters
local RayParams = RaycastParams.new()
RayParams.FilterType = Enum.RaycastFilterType.Exclude
RayParams.FilterDescendantsInstances = {Workspace.Ignore, Character}

-- Initialize camera shake effect
local Shaker = CameraShake.new(Enum.RenderPriority.Camera.Value+1, function(cf)
	PlayerCamera.CFrame *= cf
end)
Shaker:Start()

-- Creates randomly sized rocks for natural look
local function CreateRandomRock(material, color)
	local rock = Instance.new("Part")
	rock.Parent = Workspace.Ignore
	local sizeX = math.random(Config.RockSettings.MinSize, Config.RockSettings.MaxSize)/10
	local sizeY = math.random(Config.RockSettings.MinSize, Config.RockSettings.MaxSize)/10
	local sizeZ = math.random(Config.RockSettings.MinSize, Config.RockSettings.MaxSize)/10
	rock.Size = Vector3.new(sizeX, sizeY, sizeZ)
	rock.Material = material or Enum.Material.Rock
	rock.Color = color or Color3.new(0.5, 0.5, 0.5)
	rock.Anchored = true
	rock.CanCollide = false
	return rock
end

-- Calculates where spell should land based on mouse position
local function CalculateTargetPosition()
	local mousePos = Player:GetMouse().Hit.Position
	local direction = (mousePos - RootPart.Position).Unit * Config.MaxDistance
	local rayResult = Workspace:Raycast(RootPart.Position, direction, RayParams)
	return rayResult and rayResult.Position or (RootPart.Position + direction)
end

-- Makes rocks fly away from impact point
local function LaunchRocks(position, hitData, duration)
	local rock = CreateRandomRock(hitData.Material, hitData.Instance.Color)
	rock.Position = position
	rock.Anchored = false
	rock.Massless = true

	rock.Size /=2

	-- Apply random rotation
	rock.CFrame = rock.CFrame * CFrame.Angles(
		math.rad(math.random(-80, 80)),
		math.rad(math.random(-80, 80)),
		math.rad(math.random(-80, 80))
	)

	-- Add physics movement
	local velocity = Instance.new("BodyVelocity")
	velocity.Velocity = Vector3.new(
		math.random(Config.RockSettings.VelocityRange.X[1], Config.RockSettings.VelocityRange.X[2]),
		math.random(Config.RockSettings.VelocityRange.Y[1], Config.RockSettings.VelocityRange.Y[2]),
		math.random(Config.RockSettings.VelocityRange.Z[1], Config.RockSettings.VelocityRange.Z[2])
	)
	velocity.Parent = rock

	-- Cleanup after effect duration
	task.delay(duration, function()
		velocity:Destroy()
	end)
end



-- Creates circular crater effect at target position
local function GenerateCrater(centerPos, rockCount, radius, lifetime)
	local angleStep = 360 / rockCount
	for angle = 0, 360, angleStep do
		local rayOrigin = centerPos + Vector3.new(0, 25, 0)
		local rayDirection = Vector3.new(0, -100, 0)
		local hit = Workspace:Raycast(rayOrigin, rayDirection, RayParams)
		if not hit then continue end

		-- Position rocks in circle
		local rock = CreateRandomRock(hit.Material, hit.Instance.Color)
		local distance = math.random(radius/1.2, radius)
		rock.CFrame = CFrame.new(hit.Position) * CFrame.Angles(0, math.rad(angle), 0) * CFrame.new(0, 0, distance)

		-- Add slight random tilt
		rock.CFrame = rock.CFrame * CFrame.Angles(
			math.rad(math.random(-25, 25)),
			math.rad(math.random(-10, 10)),
			0
		)

		-- Launch some flying rocks
		LaunchRocks(hit.Position, hit, 0.4)

		-- Fade out effect after lifetime
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
	for _,effect in pairs(object:GetDescendants()) do
		if effect:IsA("ParticleEmitter") then
			effect:Emit(effect:GetAttribute("EmitCount") or 1)
		end
	end
end

-- Copy Sound by name from Sounds folder
local function CopySound(SoundName,Played: boolean)
	local Sound: Sound = Sounds:FindFirstChild(SoundName)
	if not Sound then return end
	local ClonnedSound = Sound:Clone()
	
	ClonnedSound.Parent = Character.PrimaryPart
	if not Played then return ClonnedSound end
	ClonnedSound:Play()
	ClonnedSound.Ended:Once(function()
		ClonnedSound:Destroy()
	end)
end

-- Handles the spell casting sequence
local function CastSpell()
	local targetPos = CalculateTargetPosition()
	if not targetPos then return end

	-- Create main explosion effect
	local explosion = Assets.Explosion:Clone()
	explosion.Parent = Workspace.Ignore
	explosion:PivotTo(CFrame.new(targetPos) * Config.ExplosionAngle + Config.HeightOffset)

	-- Animate character upward
	RootPart.Anchored = true

	
	TweenService:Create(RootPart, TweenInfo.new(0.5), {
		CFrame = RootPart.CFrame + Vector3.new(0, 50, 0)
	}):Play()

	--Play Sound
	CopySound("AirWosh",true)

	-- Sequence of spell effects
	task.delay(0.5, function()
		RootPart.Anchored = false
		Shaker:ShakeOnce(5, 50, 0, 0.3)

		-- Trigger different effect parts
		ActivateEffects(explosion.Dummy)
		task.wait(0.1)
		ActivateEffects(explosion.Impact)
		--Play Sound
		CopySound("Explosion",true)

		
		-- Create crater effects
		GenerateCrater(targetPos, 35, 30, 1)
		GenerateCrater(targetPos, 25, 20, 1.5)
	end)
end

-- Setup input listener for spell casting
ActiveConnections.InputBegan = UserInputService.InputBegan:Connect(function(input,event)
	if input.KeyCode == Config.KeyBind and not event then
		if Config.CoolDown then return end
		Config.CoolDown = true
		CastSpell()
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