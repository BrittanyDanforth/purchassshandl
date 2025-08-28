--[[
    ╔══════════════════════════════════════════════════════════════════════════════════════╗
    ║                    SANRIO TYCOON CLIENT - SIMPLE v10.0                               ║
    ║                    MINIMAL WORKING VERSION                                           ║
    ╚══════════════════════════════════════════════════════════════════════════════════════╝
]]

-- Simple working client that just opens the Shop UI

-- ========================================
-- SERVICES
-- ========================================
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local LocalPlayer = Players.LocalPlayer
local PlayerGui = LocalPlayer:WaitForChild("PlayerGui")

print("[SimpleClient] Starting...")

-- ========================================
-- WAIT FOR MODULES
-- ========================================
local ClientModules = script.Parent:WaitForChild("ClientModules", 10)
if not ClientModules then
    warn("[SimpleClient] ClientModules not found!")
    return
end

-- ========================================
-- SIMPLE UI OPENER
-- ========================================
local function openShopUI()
    print("[SimpleClient] Attempting to open Shop UI...")
    
    -- Find the MainUI module
    local FrameworkModules = ClientModules:FindFirstChild("Framework")
    if not FrameworkModules then
        warn("[SimpleClient] Framework modules not found!")
        return
    end
    
    local MainUIModule = FrameworkModules:FindFirstChild("MainUI")
    if not MainUIModule then
        warn("[SimpleClient] MainUI module not found!")
        return
    end
    
    -- Try to require it
    local success, MainUI = pcall(require, MainUIModule)
    if not success then
        warn("[SimpleClient] Failed to require MainUI: " .. tostring(MainUI))
        return
    end
    
    -- Check if it's a class or instance
    if type(MainUI) == "table" and MainUI.new then
        print("[SimpleClient] MainUI is a class, need to instantiate it...")
        -- This would require all the dependencies, too complex
        warn("[SimpleClient] Cannot instantiate MainUI without dependencies")
        return
    end
    
    -- Try direct approach - find the UI in PlayerGui
    local SanrioUI = PlayerGui:FindFirstChild("SanrioTycoonUI")
    if SanrioUI then
        print("[SimpleClient] Found existing SanrioTycoonUI")
        
        -- Look for navigation buttons
        local navBar = SanrioUI:FindFirstChild("NavigationBar", true)
        if navBar then
            print("[SimpleClient] Found NavigationBar")
            
            -- Find shop button
            for _, button in ipairs(navBar:GetDescendants()) do
                if button:IsA("TextButton") and (button.Name == "ShopButton" or button.Text == "Shop") then
                    print("[SimpleClient] Found Shop button, clicking it!")
                    -- Simulate click
                    button.MouseButton1Click:Fire()
                    return
                end
            end
            
            warn("[SimpleClient] Could not find Shop button in NavigationBar")
        else
            warn("[SimpleClient] NavigationBar not found")
        end
    else
        warn("[SimpleClient] SanrioTycoonUI not found in PlayerGui")
    end
end

-- ========================================
-- REMOTE MONITORING
-- ========================================
local function monitorRemotes()
    local RemoteEvents = ReplicatedStorage:FindFirstChild("RemoteEvents")
    if RemoteEvents then
        print("[SimpleClient] Found RemoteEvents folder")
        
        -- Monitor DataLoaded
        local DataLoaded = RemoteEvents:FindFirstChild("DataLoaded")
        if DataLoaded then
            DataLoaded.OnClientEvent:Connect(function(playerData)
                print("[SimpleClient] DataLoaded received!")
                -- Try to open shop after data loads
                task.wait(1)
                openShopUI()
            end)
        end
    end
end

-- ========================================
-- MAIN
-- ========================================
print("[SimpleClient] Waiting for game to load...")
task.wait(3)

-- Monitor remotes
monitorRemotes()

-- Try to open shop
openShopUI()

-- Create simple command
_G.OpenShop = function()
    openShopUI()
end

print("[SimpleClient] Ready! Use _G.OpenShop() to try opening the shop.")

-- ========================================
-- UI EXISTENCE CHECK
-- ========================================
task.spawn(function()
    while task.wait(5) do
        local count = 0
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                count = count + 1
            end
        end
        print("[SimpleClient] ScreenGuis in PlayerGui: " .. count)
        
        -- List them
        for _, gui in ipairs(PlayerGui:GetChildren()) do
            if gui:IsA("ScreenGui") then
                print("  - " .. gui.Name)
            end
        end
    end
end)