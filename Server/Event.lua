local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events

local ABILITYCD = 3 -- constant ability cooldown
local PlayersCDs: {[number]: boolean} = {} -- a table which consists of all the players and their cooldowns 

local HealModule = require(script.Heal)
local BiezeModule = require(script.BiezeModule)

function MoveSpell(object: BasePart, finishPosition: Vector3, Velocity: number)

	local Time = ((object.Position - finishPosition).Magnitude + 10)/Velocity
	local FrameRate = 60 -- set to 60 so we can animate vfx movement each frame (considering the selected client fps is 60)
	local Frames = Time*FrameRate

	for i=0,Frames do  -- loop to animate bezier curve
		local t=i/Frames
		task.wait(1/FrameRate)
	end

end

function CheckCD(player: Player)
	if PlayersCDs[player.UserId] then return true end
	return false
end

function SetCD(player: Player)
	PlayersCDs[player.UserId] = true
	
	task.delay(ABILITYCD, function()
		PlayersCDs[player.UserId] = nil -- to nullify the cooldown after a certain period
	end)
end

Events.Ability.OnServerEvent:Connect(function(player: Player, mousePosition: Vector3)
	if CheckCD(player) then return end
	SetCD(player)
	
	Events.Replication:FireAllClients(player.Name, mousePosition) -- for client replciation
	MoveSpell(player.Character.PrimaryPart,mousePosition,30)
	
	
	HealModule:SpawnZone(mousePosition)
	
end)
