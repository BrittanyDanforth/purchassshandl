-- Item Spawner Module
-- Handles spawning and managing shop items as tools

local ItemSpawner = {}
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")
local Debris = game:GetService("Debris")

-- Create Tools Folder
local toolsFolder = Instance.new("Folder")
toolsFolder.Name = "ShopTools"
toolsFolder.Parent = ReplicatedStorage

-- Tool Creation Functions
local function createRedCoil()
    local tool = Instance.new("Tool")
    tool.Name = "Red Coil"
    tool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 3)
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.BrickColor = BrickColor.new("Really red")
    handle.Material = Enum.Material.Neon
    handle.Parent = tool
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxasset://fonts/sword.mesh"
    mesh.Scale = Vector3.new(0.5, 0.5, 1.5)
    mesh.TextureId = "rbxassetid://9676503482"
    mesh.Parent = handle
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/swoosh.wav"
    sound.Volume = 0.5
    sound.Parent = handle
    
    local speedScript = Instance.new("Script")
    speedScript.Source = [[
        local tool = script.Parent
        local handle = tool:WaitForChild("Handle")
        local sound = handle:WaitForChild("Sound")
        
        tool.Equipped:Connect(function()
            local character = tool.Parent
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 32
                sound:Play()
            end
        end)
        
        tool.Unequipped:Connect(function()
            -- Speed reset handled by server
        end)
    ]]
    speedScript.Parent = tool
    
    tool.Parent = toolsFolder
    return tool
end

local function createGreenCoil()
    local tool = Instance.new("Tool")
    tool.Name = "Green Coil"
    tool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 1, 3)
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.BrickColor = BrickColor.new("Lime green")
    handle.Material = Enum.Material.Neon
    handle.Parent = tool
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxasset://fonts/sword.mesh"
    mesh.Scale = Vector3.new(0.5, 0.5, 1.5)
    mesh.TextureId = "rbxassetid://9676542145"
    mesh.Parent = handle
    
    local sound = Instance.new("Sound")
    sound.SoundId = "rbxasset://sounds/swoosh.wav"
    sound.Volume = 0.5
    sound.Pitch = 1.2
    sound.Parent = handle
    
    local speedScript = Instance.new("Script")
    speedScript.Source = [[
        local tool = script.Parent
        local handle = tool:WaitForChild("Handle")
        local sound = handle:WaitForChild("Sound")
        
        tool.Equipped:Connect(function()
            local character = tool.Parent
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.WalkSpeed = 40
                sound:Play()
            end
        end)
        
        tool.Unequipped:Connect(function()
            -- Speed reset handled by server
        end)
    ]]
    speedScript.Parent = tool
    
    tool.Parent = toolsFolder
    return tool
end

local function createRedBalloon()
    local tool = Instance.new("Tool")
    tool.Name = "Red Balloon"
    tool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(2, 2, 2)
    handle.Shape = Enum.PartType.Ball
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.BrickColor = BrickColor.new("Really red")
    handle.Material = Enum.Material.ForceField
    handle.Transparency = 0.3
    handle.Parent = tool
    
    local decal = Instance.new("Decal")
    decal.Texture = "rbxassetid://9672579022"
    decal.Face = Enum.NormalId.Front
    decal.Parent = handle
    
    local string = Instance.new("Part")
    string.Name = "String"
    string.Size = Vector3.new(0.1, 3, 0.1)
    string.BrickColor = BrickColor.new("White")
    string.TopSurface = Enum.SurfaceType.Smooth
    string.BottomSurface = Enum.SurfaceType.Smooth
    string.Parent = tool
    
    local weld = Instance.new("WeldConstraint")
    weld.Part0 = handle
    weld.Part1 = string
    weld.Parent = handle
    
    string.CFrame = handle.CFrame * CFrame.new(0, -2.5, 0)
    
    local floatScript = Instance.new("Script")
    floatScript.Source = [[
        local tool = script.Parent
        local handle = tool:WaitForChild("Handle")
        
        tool.Equipped:Connect(function()
            local character = tool.Parent
            local humanoid = character:FindFirstChildOfClass("Humanoid")
            if humanoid then
                humanoid.JumpPower = 100
                
                -- Add float effect
                local bodyVelocity = Instance.new("BodyVelocity")
                bodyVelocity.MaxForce = Vector3.new(0, 4000, 0)
                bodyVelocity.Velocity = Vector3.new(0, 10, 0)
                bodyVelocity.Parent = character:WaitForChild("HumanoidRootPart")
                
                wait(0.5)
                bodyVelocity:Destroy()
            end
        end)
        
        tool.Unequipped:Connect(function()
            -- Jump power reset handled by server
        end)
    ]]
    floatScript.Parent = tool
    
    tool.Parent = toolsFolder
    return tool
end

local function createGrapplingHook()
    local tool = Instance.new("Tool")
    tool.Name = "Grappling Hook"
    tool.RequiresHandle = true
    
    local handle = Instance.new("Part")
    handle.Name = "Handle"
    handle.Size = Vector3.new(1, 2, 1)
    handle.TopSurface = Enum.SurfaceType.Smooth
    handle.BottomSurface = Enum.SurfaceType.Smooth
    handle.BrickColor = BrickColor.new("Dark stone grey")
    handle.Material = Enum.Material.Metal
    handle.Parent = tool
    
    local mesh = Instance.new("SpecialMesh")
    mesh.MeshType = Enum.MeshType.FileMesh
    mesh.MeshId = "rbxasset://fonts/PaintballGun.mesh"
    mesh.TextureId = "rbxassetid://9677437680"
    mesh.Scale = Vector3.new(0.7, 0.7, 0.7)
    mesh.Parent = handle
    
    local hookScript = Instance.new("Script")
    hookScript.Source = [[
        local tool = script.Parent
        local handle = tool:WaitForChild("Handle")
        local player = nil
        local character = nil
        local mouse = nil
        
        local rope = nil
        local attachment0 = nil
        local attachment1 = nil
        
        tool.Equipped:Connect(function(playerMouse)
            character = tool.Parent
            player = game.Players:GetPlayerFromCharacter(character)
            mouse = playerMouse
            
            mouse.Button1Down:Connect(function()
                if rope then
                    rope:Destroy()
                    if attachment0 then attachment0:Destroy() end
                    if attachment1 then attachment1:Destroy() end
                end
                
                local target = mouse.Hit.Position
                local distance = (handle.Position - target).Magnitude
                
                if distance <= 50 then
                    -- Create rope
                    rope = Instance.new("RopeConstraint")
                    attachment0 = Instance.new("Attachment", handle)
                    attachment1 = Instance.new("Attachment")
                    attachment1.WorldPosition = target
                    attachment1.Parent = workspace.Terrain
                    
                    rope.Attachment0 = attachment0
                    rope.Attachment1 = attachment1
                    rope.Length = distance
                    rope.Visible = true
                    rope.Parent = handle
                    
                    -- Pull player
                    local bodyVelocity = Instance.new("BodyVelocity")
                    bodyVelocity.MaxForce = Vector3.new(4000, 4000, 4000)
                    bodyVelocity.Velocity = (target - character.HumanoidRootPart.Position).Unit * 50
                    bodyVelocity.Parent = character.HumanoidRootPart
                    
                    wait(0.5)
                    bodyVelocity:Destroy()
                end
            end)
        end)
        
        tool.Unequipped:Connect(function()
            if rope then
                rope:Destroy()
                if attachment0 then attachment0:Destroy() end
                if attachment1 then attachment1:Destroy() end
            end
        end)
    ]]
    hookScript.Parent = tool
    
    tool.Parent = toolsFolder
    return tool
end

-- Initialize tools
createRedCoil()
createGreenCoil()
createRedBalloon()
createGrapplingHook()

-- Function to give tool to player
function ItemSpawner.GiveTool(player, itemId)
    local character = player.Character
    if not character then return end
    
    -- Remove existing tools
    for _, tool in pairs(character:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
        end
    end
    
    for _, tool in pairs(player.Backpack:GetChildren()) do
        if tool:IsA("Tool") then
            tool:Destroy()
        end
    end
    
    -- Give new tool
    local toolName = nil
    if itemId == "RedCoil" then
        toolName = "Red Coil"
    elseif itemId == "GreenCoil" then
        toolName = "Green Coil"
    elseif itemId == "RedBalloon" then
        toolName = "Red Balloon"
    elseif itemId == "GrapplingHook" then
        toolName = "Grappling Hook"
    end
    
    if toolName then
        local tool = toolsFolder:FindFirstChild(toolName)
        if tool then
            local newTool = tool:Clone()
            newTool.Parent = player.Backpack
        end
    end
end

return ItemSpawner