local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Events = ReplicatedStorage.Events
local GUI = Events.GUI

local Heal = {}

local Itteration = 4
local Duration = 1

function Heal:CheckPlayers()
	local Hits = workspace:GetPartBoundsInBox(CFrame.new(self.Position),self.Size)
	
	local Hitted = {}
	
	for _,part: BasePart in Hits do
		if not part.Parent:FindFirstChildOfClass("Humanoid") then continue end
		
		local target: Model = part.Parent
		local humanoid: Humanoid = target:FindFirstChildOfClass("Humanoid")
		if Hitted[target] then continue end
		Hitted[target] = true
			
		humanoid.Health += self.Heal

		GUI:FireAllClients(target.Name,self.Heal)
	end
	table.clear(Hitted)
end

function Heal:Active()
	
	for i=1,Itteration do
		self:CheckPlayers()
		task.wait(Duration)
	end
	
end

function Heal:SpawnZone(Position: Vector3)
	
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
	HealZone:Active()
	
end

return Heal
