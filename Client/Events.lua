local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("Events")
local Replication = require(script.Replication)


Events.Replication.OnClientEvent:Connect(function(PlayerName: string, MousePosition: Vector3)
	
	local Caster: Player = Players:WaitForChild(PlayerName)
	assert(Caster, PlayerName.." doesnt exist") -- to make sure that player exists
	
	Replication:ReplicateSpell(Caster, MousePosition) -- player here stands as the caster of the spell
	
end)

Events.GUI.OnClientEvent:Connect(function(PlayerName: string,HealAmmount: number)
	
	local Caster: Player = Players:WaitForChild(PlayerName)
	assert(Caster, PlayerName.." doesnt exist") -- to make sure that player exists
	
	
	Replication:ReplicateGUI(Caster,HealAmmount)
	
end)