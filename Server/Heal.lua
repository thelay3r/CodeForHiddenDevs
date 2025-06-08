local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events
local GUI = Events.GUI

local Heal = {}

local Itteration = 4
local Duration = 1

function Heal:CheckPlayers()
	local Hits = workspace:GetPartBoundsInBox(CFrame.new(self.Position),self.Size)
	
	--Hitted Table
	local Hitted = {}
	
	--cycle through all the parts
	for _,part: BasePart in Hits do
		if not part.Parent:FindFirstChildOfClass("Humanoid") then continue end
		
		
		local target: Model = part.Parent
		local humanoid: Humanoid = target:FindFirstChildOfClass("Humanoid")
		--if player already in table then skip
		if Hitted[target] then continue end
		--if we found a player then add it to the table
		Hitted[target] = true
			
		--Heal Player
		humanoid.Health += self.Heal

		--Replication gui
		GUI:FireAllClients(target.Name,self.Heal)
	end
	table.clear(Hitted)
end

function Heal:Active()
	--Itteration for healing
	for i=1,Itteration do
		--Check for players in radius
		self:CheckPlayers()
		task.wait(Duration)
	end
	
end

--Construcotr for zone
function Heal:SpawnZone(Position: Vector3)
	
	--Zone Radius
	local Zone: Vector3 = Vector3.new(20,1,20)
	
	local HealZone = setmetatable(
		{
			Size = Zone;
			Position = Position;
			Heal = 10;
		},
	{
		__index = function(t,key)
			return Heal[key]
		end,
	})
	--Acitve Zone
	HealZone:Active()
	
end

return Heal
