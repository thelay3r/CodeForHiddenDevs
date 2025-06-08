local ReplicatedStorage = game:GetService("ReplicatedStorage")
local UIS = game:GetService("UserInputService")
local Players = game:GetService("Players")

local Events = ReplicatedStorage:WaitForChild("Events")
local Player = Players.LocalPlayer
local Mouse  = Player:GetMouse() -- player mouse object wont change, so we can keep it that way

local KEYCODE = Enum.KeyCode.E -- ability activation keycode

UIS.InputBegan:Connect(function(Input, IsEvent) -- detects any input
	if (IsEvent) then return end -- to prevent firing when chatting
	if (Input.KeyCode ~= KEYCODE) then return end 
	
	Events.Ability:FireServer(Mouse.Hit.Position)
end)