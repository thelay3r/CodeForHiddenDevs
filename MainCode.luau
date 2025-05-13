-- USER INPUT SERVICE WHAAAAAAT
local UserInputService = game:GetService("UserInputService")

--Tween service 
local TweenService = game:GetService("TweenService")

--WOOOOOW PLAYER
local Player = game.Players.LocalPlayer

--character wooow
local Character = script.Parent

--wow player camera
local Camera = workspace.CurrentCamera


--camera shake module
local CameraShake = require(game.ReplicatedStorage.Modules.CameraShaker)

--Boolean switch ability move
local Get: boolean = false
--Wow its object
local Object :Part

-- cooldown
local Debounce = false


--rock spawn function 
local function CreateBlocksSphereOutline(point: Vector3, 
	info: { 
		intensity: number, 
		radius: { min: number, max: number }, 
		size: { min: number, max: number }, 
		delaytime: { min: number, max: number } }, 
	callback)



	local params = RaycastParams.new()
	params.FilterType = Enum.RaycastFilterType.Include
	params.FilterDescendantsInstances = {workspace.Map}

	local ray = workspace:Raycast(point, Vector3.new(0, -20, 0), params)
	if not ray then Object:Destroy() Get = false Debounce = false return end

	local parts = {}
	--spawn rock by angle etc
	for angle = 0, 360, 360/info.intensity do

		local smul = math.random(info.size.min*1000, info.size.max*1000)/1000

		local randPos = Vector3.new(
			math.sin(math.rad(angle))*math.random(info.radius.min, info.radius.max),
			0,
			math.cos(math.rad(angle))*math.random(info.radius.min, info.radius.max)
		)
		--instance new part
		local part = Instance.new("Part",workspace)
		part.Size = Vector3.new(smul, smul, smul)
		part.CFrame = CFrame.new(ray.Position + randPos, (ray.Position - ray.Normal)) * CFrame.Angles(math.rad(90),0,0)	
		part.Transparency = .2
		part.Color = ray.Instance.Color
		part.Material = ray.Material

		part.Anchored = true

		part.CFrame = part.CFrame + part.CFrame.UpVector * -4
		TweenService:Create(part, TweenInfo.new(.15), { CFrame = part.CFrame + part.CFrame.UpVector * 4 }):Play()


		--insert part to parts table
		table.insert(parts, part)

		task.delay(math.random(info.delaytime.min*1000, info.delaytime.max*1000)/1000, function() TweenService:Create(part, TweenInfo.new(1,Enum.EasingStyle.Sine), {Size = Vector3.zero}):Play() wait(1) part:Destroy()  end)

	end

	--return parts woooooow
	return parts

end



-- Reading iser uiput
UserInputService.InputBegan:Connect(function(input, event)
	if input.KeyCode == Enum.KeyCode.Q and not event and not Debounce then
		if Get then
			--Player mouse
			local Mouse = Player:GetMouse()
			local MousePosition = Mouse.Hit.Position
			
			--raycast params
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = {workspace.Map:GetDescendants()}
			
			--Checked raycast
			local raycast = workspace:Raycast(MousePosition + Vector3.new(0,2,0), Vector3.new(0, -20,0), params)
			if not raycast then return end
			Debounce = true
			Get = false
			if raycast then
				
				--cfg tween service 
				local EndTween = TweenService:Create(Object, TweenInfo.new(1, Enum.EasingStyle.Exponential, Enum.EasingDirection.InOut), {Position = raycast.Position})
				
				EndTween:Play()
				--delay with explosion 
				task.delay(.6,function()
					
					Object.EndSound:Play()
					
					local EndEffect = game.ReplicatedStorage.Assets.EndEffect:Clone()
					EndEffect.Parent = workspace
					EndEffect.CFrame = CFrame.new(raycast.Position)
					
					
					for _, v in pairs(EndEffect:GetDescendants()) do
						if v:IsA("ParticleEmitter") then
							v:Emit(v:GetAttribute("EmitCount"))
						end
					end
					
					--camera shake init
					local CameraShake = CameraShake.new(Enum.RenderPriority.Camera.Value, function(shakecf)
						Camera.CFrame *= shakecf
					end)
					CameraShake:Start()

					CameraShake:Shake(CameraShake.Presets.BumpModded)


					--spawn rocks
					CreateBlocksSphereOutline(raycast.Position  + Vector3.new(0,3,0), {
						intensity =  35, 
						radius =  { min =  4, max = 7 }, 
						size =  { min =  1, max = 2 }, 
						delaytime = {min =  1, max = 3 },
					})
					
				end)
				--completed tween
				EndTween.Completed:Connect(function()
					
					
					Debounce = false
					--last object to delet
					local LastObject = Object
					
					TweenService:Create(LastObject, TweenInfo.new(.5, Enum.EasingStyle.Sine),{Transparency = 1}):Play()
					--Emit vfx
					for _, v in pairs(LastObject:GetDescendants()) do
						task.spawn(function()
							if v:IsA("Beam") then
								for i=1, 10 do
									v.Transparency = NumberSequence.new(i/10)
									task.wait(0.01)
								end
							end
						end)
					end
					--destroy object
					task.spawn(function()
						task.wait(2)
						LastObject:Destroy()
					end)

				end)
				
			end
			
		else
			--Player mouse
			local Mouse = Player:GetMouse()
			local MousePosition = Mouse.Hit.Position

			--raycast params
			local params = RaycastParams.new()
			params.FilterType = Enum.RaycastFilterType.Include
			params.FilterDescendantsInstances = {workspace:GetDescendants()}
			--check raycast
			
			local raycast = workspace:Raycast(MousePosition + Vector3.new(0,2,0), Vector3.new(0, -20,0), params)
			--check if not raycast then return
			if not raycast then return end
			Debounce = true
			Get = true
			if raycast then
				--clone obj
				Object = game.ReplicatedStorage.Assets.Object:Clone()
				Object.Parent = workspace
				Object.CFrame = CFrame.new(raycast.Position - Vector3.new(0,20,0))

				--clone start vfx
				local StartEffect = game.ReplicatedStorage.Assets.StartEffect:Clone()
				StartEffect.Parent = Object
				--set vfx position
				StartEffect.CFrame = CFrame.new(raycast.Position + Vector3.new(0,2,0))
				
				--Emit vfx
				for _, v in pairs(StartEffect:GetDescendants()) do
					if v:IsA("ParticleEmitter") then
						v:Emit(v:GetAttribute("EmitCount"))
					end
				end
				
				--camerashake init
				local CameraShake = CameraShake.new(Enum.RenderPriority.Camera.Value, function(shakecf)
					Camera.CFrame *= shakecf
				end)
				CameraShake:Start()
				
				CameraShake:Shake(CameraShake.Presets.BumpModded)
				
				--Init play sound
				Object.StartSound:Play()
				
				task.delay(.1,function()
					
					
				-- spawn rocks
				CreateBlocksSphereOutline(raycast.Position  + Vector3.new(0,3,0), {
						intensity =  35, 
						radius =  { min =  4, max = 7 }, 
						size =  { min =  1, max = 2 }, 
						delaytime = {min =  1, max = 3 },
					})
				end)
				
				
				task.wait(.1)
				Object.CFrame *= CFrame.Angles(math.rad(75),math.rad(0), math.rad(75))

				-- start tween for mov obj
				local StartTween = TweenService:Create(Object, TweenInfo.new(.75, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {Position = Object.Position + Vector3.new(0,30,0)})
				StartTween:Play()
				StartTween.Completed:Connect(function()
					Debounce = false
				end)
				
				-- rotate obj
				while Get  do
					Object.CFrame *= CFrame.Angles(math.rad(1),math.rad(0),math.rad(1))
					task.wait(.01)
				end
				
			end
		end
	end
	
end)

