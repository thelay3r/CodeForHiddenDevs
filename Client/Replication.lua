-- ROBLOX Services
local TweenService = game:GetService("TweenService") -- For creating smooth animations
local ReplicatedStorage = game:GetService("ReplicatedStorage") -- Where shared assets are stored

-- Asset references
local Assets = ReplicatedStorage:WaitForChild("Assets") -- Folder containing VFX models
local BiezeModule = require(script.Parent.BiezeModule) -- Custom module for Bezier curve calculations

-- Effect duration constant
local AuraLifeTime = 3 -- How long the main aura effect lasts (in seconds)

-- Main replication table that will be returned
local Replication = {}

--[[
    UTILITIES MODULE
    Contains helper functions for VFX creation and management
]]
local UtilitiesModule = (function()
    --[[
        Moves a spell object along a quadratic Bezier curve to target position
        @param object: The BasePart to move
        @param finishPosition: Target Vector3 position
        @param Velocity: Movement speed modifier
    ]]
    function MoveSpell(object, finishPosition, Velocity)
        -- Calculate total movement time based on distance and velocity
        -- We add +10 to ensure minimum distance for smooth animation
        local distance = (object.Position - finishPosition).Magnitude + 10
        local Time = distance / Velocity
        
        -- Animation settings (60 FPS for smooth movement)
        local FrameRate = 60 -- Match client's render FPS
        local totalFrames = Time * FrameRate -- Total frames needed
        
        -- Bezier curve control points:
        -- Start: Current position
        -- Middle: Midpoint with random height/offset for arcing motion
        -- End: Target position
        local StartPosition = object.Position
        local MiddlePosition = (StartPosition + finishPosition)/2 + 
            Vector3.new(math.random(-10,10), math.random(10,20), math.random(-10,10))
        
        -- Frame-by-frame animation loop
        for frame = 0, totalFrames do
            -- Calculate progress (0 to 1)
            local progress = frame / totalFrames
            
            -- Get position along Bezier curve at current progress
            local newPosition = BiezeModule.quadraticBieze(
                StartPosition, 
                MiddlePosition, 
                finishPosition, 
                progress
            )
            
            -- Update object position
            object.Position = newPosition
            
            -- Wait for next frame (1/60th of a second)
            task.wait(1/FrameRate)
        end
    end
    
    --[[
        Calculates surface position using raycasting
        @param object: The part to position
        @param Position: Desired world position
        @return: Adjusted CFrame that sits on surface
    ]]
    function CalculatePosition(object, Position)
        -- Configure raycast parameters
        local Params = RaycastParams.new()
        Params.FilterType = Enum.RaycastFilterType.Exclude
        Params.FilterDescendantsInstances = {object} -- Ignore self in raycast
        
        -- Cast ray downward to find surface
        local raycastResult = workspace:Raycast(Position, Vector3.new(0,-5,0), Params)
        
        -- If no hit, return original position
        if not raycastResult then 
            object.Position = Position 
            return object 
        end
        
        -- Create surface-aligned CFrame:
        -- 1. Position at hit point
        -- 2. Rotated to face along surface normal
        -- 3. Tilted -90 degrees on X to stand upright
        local surfaceCFrame = CFrame.new(raycastResult.Position, raycastResult.Position + raycastResult.Normal) * 
            CFrame.Angles(math.rad(-90), 0, 0)
        
        return surfaceCFrame
    end
    
    --[[
        Generates a random Vector3 within min/max range
        @param min: Minimum value for each component
        @param max: Maximum value for each component
        @return: Random Vector3
    ]]
    function RandomVector(min, max)
        -- Scale values by 10 to allow decimal precision via integer random
        min = min * 10
        max = max * 10
        return Vector3.new(
            math.random(min,max)/10, -- X component
            math.random(min,max)/10, -- Y component 
            math.random(min,max)/10  -- Z component
        )
    end
    
    --[[
        Creates a rock part with randomized size
        @param SpawnCFrame: Optional initial CFrame
        @return: The created BasePart
    ]]
    function SpawnRock(SpawnCFrame)
        -- Create new part
        local Rock = Instance.new("Part")
        
        -- Configure properties:
        Rock.Size = RandomVector(2,4) -- Random size between 2-4 studs
        Rock.Anchored = true -- Doesn't respond to physics
        Rock.Massless = true -- Doesn't affect physics calculations
        Rock.Parent = workspace -- Place in 3D space
        
        -- Set position if provided
        if SpawnCFrame then
            Rock.CFrame = SpawnCFrame
        end
        
        return Rock
    end
    
    --[[
        Plays a sound effect anchored to an invisible part
        @param Sound: Sound object to play
        @param OriginCFrame: Where to position the sound
    ]]
    function PlaySoundWithoutAnchor(Sound, OriginCFrame)
        -- Create invisible anchor part
        local SoundPart = SpawnRock(OriginCFrame)
        SoundPart.Transparency = 1 -- Fully invisible
        SoundPart.CanCollide = false -- No collisions
        
        -- Parent and play sound
        Sound.Parent = SoundPart
        Sound:Play()
        
        -- Cleanup when sound finishes
        Sound.Ended:Once(function()
            Sound:Destroy()
            SoundPart:Destroy()
        end)
    end
    
    --[[
        Creates a crater effect with flying rocks
        @param config: Configuration table with:
            - CFrame: Center position
            - Radius: Crater size
            - RockCount: Number of rocks
            - LifeTime: How long rocks last
            - FlyRock: Whether rocks should fly out
    ]]
    function MakeCrater(config)
        -- Unpack configuration
        local CenterCFrame = config.CFrame
        local Radius = config.Radius
        local RockCount = config.RockCount or 4 -- Default to 4 rocks
        
        -- Configure raycast to only hit the map
        local CastParams = RaycastParams.new()
        CastParams.FilterType = Enum.RaycastFilterType.Include
        CastParams.FilterDescendantsInstances = {workspace.Map}
        
        -- Play impact sound effects
        PlaySoundWithoutAnchor(script.Rock_Impact:Clone(), CenterCFrame)
        PlaySoundWithoutAnchor(script.Rock_Impact2:Clone(), CenterCFrame)
        
        -- Distribute rocks evenly around circle
        for angle = 0, 360, 360/RockCount do
            -- Calculate position on circle edge
            local circlePosition = CenterCFrame * 
                CFrame.Angles(0, math.rad(angle), 0) * -- Rotate by current angle
                CFrame.new(0,0,-Radius) -- Move out to radius
            
            -- Raycast downward to find surface
            local raycastResult = workspace:Raycast(
                circlePosition.Position + Vector3.new(0,5,0), -- Start slightly above
                Vector3.new(0,-10,0), -- Cast downward
                CastParams
            )
            
            -- Skip if no surface hit
            if not raycastResult then continue end
            
            -- Create surface-aligned orientation
            local rockOrientation = CFrame.new(
                raycastResult.Position, 
                raycastResult.Position + raycastResult.Normal
            ) * CFrame.Angles(math.rad(90), 0, 0) -- Stand upright
            
            -- Add random rotation variance
            local finalOrientation = rockOrientation * 
                CFrame.Angles(
                    math.rad(math.random(-40,40)), -- Random X tilt
                    math.rad(math.random(-40,40)), -- Random Y rotation
                    math.rad(math.random(-40,40))  -- Random Z tilt
                )
            
            -- Create flying rocks if enabled
            if config.FlyRock then
                local flyingRock = SpawnRock(finalOrientation)
                
                -- Match surface material properties
                flyingRock.Material = raycastResult.Material
                flyingRock.Color = raycastResult.Instance.Color
                
                -- Physics properties
                flyingRock.Anchored = false -- Allow physics
                flyingRock.CanCollide = false -- No collisions
                flyingRock.Size = flyingRock.Size / 2 -- Smaller than main rocks
                
                -- Add velocity for flying effect
                local BodyVelocity = Instance.new("BodyVelocity", flyingRock)
                local randomVelocity = RandomVector(-25,25)
                BodyVelocity.Velocity = Vector3.new(
                    randomVelocity.X, 
                    math.abs(randomVelocity.Y) * 2, -- Ensure upward bias
                    randomVelocity.Z
                )
                BodyVelocity.P = math.huge -- Maximum force
                
                -- Cleanup sequence
                task.delay(0.3, function()
                    BodyVelocity:Destroy() -- Stop movement
                    task.wait(0.5) -- Brief hang time
                    flyingRock:Destroy() -- Remove
                end)
            end
            
            -- Create main crater rock
            local craterRock = SpawnRock(finalOrientation - Vector3.new(0,4,0))
            craterRock.Material = raycastResult.Material
            craterRock.Color = raycastResult.Instance.Color
            
            -- Animate rock "landing" with bounce effect
            TweenService:Create(craterRock, 
                TweenInfo.new(0.3, Enum.EasingStyle.Back, Enum.EasingDirection.Out), {
                    CFrame = finalOrientation - Vector3.new(0,1,0) -- Final position
                }
            ):Play()
            
            -- Schedule rock destruction after lifetime
            task.delay(config.LifeTime + angle/360, function()
                -- Shrink animation before destruction
                local destroyTween = TweenService:Create(
                    craterRock, 
                    TweenInfo.new(1, Enum.EasingStyle.Sine), {
                        Size = Vector3.zero -- Shrink to nothing
                    }
                )
                destroyTween:Play()
                destroyTween.Completed:Once(function()
                    craterRock:Destroy()
                end)
            end)
        end
    end
    
    -- Expose public functions
    return {
        MoveSpell = MoveSpell,
        CalculatePosition = CalculatePosition,
        RandomVector = RandomVector,
        SpawnRock = SpawnRock,
        PlaySoundWithoutAnchor = PlaySoundWithoutAnchor,
        MakeCrater = MakeCrater
    }
end)()

--[[
    EFFECT MODULE
    Handles visual effect activation and management
]]
local EffectModule = (function()
    -- Effect type handlers dictionary
    local EffectCallbacks = {
        -- Particle emitter handler
        ["ParticleEmitter"] = function(emitter, properties)
            -- Emit specified number of particles
            emitter:Emit(emitter:GetAttribute("EmitCount") or 1)
            -- Set enabled state
            emitter.Enabled = properties.Enabled
        end,
        
        -- Beam effect handler
        ["Beam"] = function(beam, properties)
            -- Activate beam
            beam.Enabled = true
            
            -- Handle gradual transparency if disabling
            if properties.Disable then
                local FrameRate = 60
                local totalFrames = properties.Time * FrameRate
                
                -- Async transparency animation
                task.spawn(function()
                    for frame = 1, totalFrames do
                        local progress = frame / totalFrames
                        -- Increase transparency over time
                        local transparency = beam.Transparency.Keypoints[1].Value + progress
                        beam.Transparency = NumberSequence.new(transparency)
                        task.wait(1/FrameRate)
                    end
                end)
            end
        end,
        
        -- Trail effect handler
        ["Trail"] = function(trail, properties)
            trail.Enabled = true -- Simply activate trail
        end,
        
        -- Point light handler
        ["PointLight"] = function(light, properties)
            -- Animate brightness change
            TweenService:Create(
                light, 
                TweenInfo.new(properties.Time or 0.3, Enum.EasingStyle.Sine), {
                    Brightness = properties.Brightness
                }
            ):Play()
        end
    }
    
    --[[
        Activates all VFX components on an object
        @param object: Model or BasePart containing effects
        @param properties: Configuration for the effects
    ]]
    function PlayObjectsVFX(object, properties)
        -- Recursively process all descendants
        for _, child in pairs(object:GetDescendants()) do
            -- Check if this child type has a handler
            if EffectCallbacks[child.ClassName] then
                -- Call appropriate handler
                EffectCallbacks[child.ClassName](child, properties)
            end
        end
    end
    
    return {
        PlayObjectsVFX = PlayObjectsVFX
    }
end)()

--[[
    Replicates healing GUI effect on player
    @param Caster: Player receiving heal
    @param HealAmmount: Not currently used (could show heal amount)
]]
function Replication:ReplicateGUI(Caster, HealAmmount)
    -- Get character references
    local Character = Caster.Character
    local HealGUI = script.Heal:Clone() -- Clone GUI template
    
    -- Tween configurations
    local TweenInfoIn = TweenInfo.new(
        0.5,                   -- Duration
        Enum.EasingStyle.Exponential, 
        Enum.EasingDirection.InOut
    )
    local TweenInfoOut = TweenInfo.new(
        0.75, 
        Enum.EasingStyle.Exponential, 
        Enum.EasingDirection.Out
    )
    
    -- Play heal sound effect
    UtilitiesModule.PlaySoundWithoutAnchor(
        script.healed:Clone(), 
        Character.PrimaryPart.CFrame
    )
    
    -- Attach GUI to character's head
    HealGUI.Parent = Character.Head
    
    -- Animate GUI appearance with random offset
    TweenService:Create(HealGUI, TweenInfoIn, {
        SizeOffset = Vector2.new(
            math.random(-20,20)/10, -- Random X offset (-2 to 2)
            math.random(10,30)/10   -- Random Y size (1 to 3)
        )
    }):Play()
    
    -- Schedule disappearance
    task.delay(0.4, function()
        local disappearTween = TweenService:Create(HealGUI, TweenInfoOut, {
            SizeOffset = Vector2.new(
                HealGUI.SizeOffset.X + math.random(-5,5), -- Random X variation
                math.random(-4,-3) -- Move upward
            )
        })
        disappearTween:Play()
        disappearTween.Completed:Once(function()
            HealGUI:Destroy()
        end)
    end)
end

--[[
    Replicates spell casting effect from player to target position
    @param Caster: Player casting spell
    @param mousePosition: World target position
]]
function Replication:ReplicateSpell(Caster, mousePosition)
    -- Validate character references
    local Character = Caster.Character
    assert(Character, "Character doesn't exist")
    
    local RootPart = Character.PrimaryPart
    assert(RootPart, "RootPart doesn't exist")
    
    -- Adjust mouse position slightly upward
    local adjustedMousePosition = mousePosition + Vector3.new(0,1,0)
    
    -- Create spell projectile VFX
    local StarVFX = Assets:WaitForChild("Star"):Clone()
    StarVFX.Parent = workspace
    StarVFX.CFrame = RootPart.CFrame + Vector3.new(0,5,0) -- Start above player
    
    -- Create initial explosion effect
    local StartedVFX = Assets:WaitForChild("Started"):Clone()
    StartedVFX.Parent = workspace
    StartedVFX.CFrame = StarVFX.CFrame
    
    -- Create main aura effect (cloned but not positioned yet)
    local Aura = Assets:WaitForChild("Aura"):Clone()
    
    -- Activate initial explosion effects
    EffectModule.PlayObjectsVFX(StartedVFX, {
        Enabled = true -- Turn on all particle emitters, etc
    })
    
    -- Animate projectile movement to target
    UtilitiesModule.MoveSpell(StarVFX, adjustedMousePosition, 30)
    
    -- Position aura at target location (surface-aligned)
    Aura.Parent = workspace
    Aura.CFrame = UtilitiesModule.CalculatePosition(Aura, adjustedMousePosition) + 
        Aura.CFrame.UpVector * 10 -- Slightly above surface
    
    -- Play aura sound effect
    UtilitiesModule.PlaySoundWithoutAnchor(script.HealAura:Clone(), Aura.CFrame)
    
    -- Create impact crater effect
    UtilitiesModule.MakeCrater({
        CFrame = CFrame.new(adjustedMousePosition), -- Center point
        Radius = 10,                                -- Size of effect
        RockCount = 25,                             -- Number of rocks
        LifeTime = 3,                               -- How long rocks last
        FlyRock = true                              -- Enable flying debris
    })
    
    -- Deactivate projectile effects
    EffectModule.PlayObjectsVFX(StarVFX, {
        Enabled = false,  -- Turn off emitters
        Brightness = 0,   -- Fade lights
        Time = 0.3        -- Duration of fade
    })
    
    -- Activate aura effects
    EffectModule.PlayObjectsVFX(Aura, {
        Brightness = 3,   -- Bright light
        Time = 0.3,       -- Fade-in duration
        Enabled = true     -- Turn on all effects
    })
    
    -- Schedule aura cleanup after lifetime
    task.delay(AuraLifeTime, function()
        -- Fade out aura
        EffectModule.PlayObjectsVFX(Aura, {
            Brightness = 0,   -- Fade light
            Time = 0.3,        -- Fade duration
            Enabled = false,    -- Disable emitters
            Disable = true      -- Special flag for beams
        })
        
        -- Wait for fade to complete
        task.wait(1)
        
        -- Clean up all VFX objects
        Aura:Destroy()
        StartedVFX:Destroy()
        StarVFX:Destroy()
    end)
end

return Replication