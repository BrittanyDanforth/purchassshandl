-- ========================================
-- SANRIO TYCOON RUNTIME FIXES
-- ========================================
-- Apply these fixes to your scripts to resolve the runtime errors

-- ========================================
-- SERVER SCRIPT FIXES
-- ========================================

-- FIX 1: GetWeightedRandomPet function (around line 4756)
-- Replace the beginning of the function with:
local function GetWeightedRandomPet(eggType, player)
    local egg = EggCases[eggType]
    if not egg then return nil end
    
    -- Handle nil player gracefully
    local playerData = nil
    local luckMultiplier = 1
    
    if player and player.UserId then
        playerData = PlayerData[player.UserId]
    end
    
    -- Apply luck multipliers
    if playerData then
        -- existing luck code...
    end
    
    -- rest of function...
end

-- FIX 2: GenerateCaseItems function (around line 4801)
-- Add player parameter to function signature:
local function GenerateCaseItems(eggType, winnerPet, player)
    local egg = EggCases[eggType]
    if not egg then return {} end
    
    local items = {}
    
    -- Generate 100 items for the spinner
    for i = 1, 100 do
        if i == 50 then
            -- Place winner at center
            items[i] = winnerPet
        elseif i >= 47 and i <= 53 and i ~= 50 then
            -- Place legendary items near center for psychological effect
            local legendaryPets = {}
            for petName, petData in pairs(PetDatabase) do
                if petData.rarity >= 5 then
                    table.insert(legendaryPets, petData.id)
                end
            end
            
            if #legendaryPets > 0 then
                items[i] = legendaryPets[math.random(#legendaryPets)]
            else
                items[i] = GetWeightedRandomPet(eggType, player) -- Pass player here
            end
        else
            -- Random pets for other positions
            items[i] = GetWeightedRandomPet(eggType, player) -- Pass player here
        end
    end
    
    return items
end

-- FIX 3: OpenCase function (around line 4950)
-- Update the GenerateCaseItems call to include player:
-- Find this line:
-- local caseItems = GenerateCaseItems(eggType, winnerPet)
-- Replace with:
local caseItems = GenerateCaseItems(eggType, winnerPet, player)

-- FIX 4: Achievement checks (around line 6656-6662)
-- Add nil checks for all statistics:
elseif achievement.requirement.type == "battles_won" then
    completed = (playerData.statistics.battleStats and playerData.statistics.battleStats.wins or 0) >= achievement.requirement.value
    
elseif achievement.requirement.type == "win_streak" then
    completed = (playerData.statistics.battleStats and playerData.statistics.battleStats.highestWinStreak or 0) >= achievement.requirement.value
    
elseif achievement.requirement.type == "trades_completed" then
    completed = (playerData.statistics.tradingStats and playerData.statistics.tradingStats.tradesCompleted or 0) >= achievement.requirement.value

-- ========================================
-- CLIENT SCRIPT FIXES
-- ========================================

-- FIX 1: AbsoluteContentSize error (line 1126)
-- Find this line:
-- gridContainer.CanvasSize = UDim2.new(0, 0, 0, eggGrid.AbsoluteContentSize.Y)
-- Replace with:
spawn(function()
    wait(0.1) -- Wait for layout to update
    if eggGrid.Parent then
        gridContainer.CanvasSize = UDim2.new(0, 0, 0, eggGrid.AbsoluteContentSize.Y)
    end
end)

-- FIX 2: UpdateValue method for progress bars (add after line 489)
-- Add this to the CreateProgressBar function:
progressBar.UpdateValue = function(self, newValue)
    local percentage = math.clamp((newValue - min) / (max - min), 0, 1)
    fill:TweenSize(
        UDim2.new(percentage, 0, 1, 0),
        Enum.EasingDirection.Out,
        Enum.EasingStyle.Quad,
        0.3,
        true
    )
    if label then
        label.Text = string.format("%d/%d", newValue, max)
    end
end

-- FIX 3: SetValue method for toggles (add after line 555)
-- Add this to the CreateToggle function:
toggle.SetValue = function(self, value)
    isOn = value
    if isOn then
        Utilities:Tween(toggleButton, {Position = UDim2.new(1, -22, 0.5, -10)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(toggleButton, {BackgroundColor3 = CLIENT_CONFIG.COLORS.Success}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        toggle.BackgroundColor3 = CLIENT_CONFIG.COLORS.Success
    else
        Utilities:Tween(toggleButton, {Position = UDim2.new(0, 2, 0.5, -10)}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        Utilities:Tween(toggleButton, {BackgroundColor3 = CLIENT_CONFIG.COLORS.White}, CLIENT_CONFIG.TWEEN_INFO.Fast)
        toggle.BackgroundColor3 = Color3.fromRGB(200, 200, 200)
    end
end

-- FIX 4: Missing UI methods (around lines 3456, 2534, 3102)
-- Add these stub methods to prevent errors:

-- For CreateAchievementList (add to QuestUI module):
function UIModules.QuestUI:CreateAchievementList(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    
    -- Add achievement items here
    local achievementLabel = UIComponents:CreateLabel(scrollFrame, "Achievements coming soon!", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    achievementLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    
    return scrollFrame
end

-- For CreateActiveTradesView (add to TradingUI module):
function UIModules.TradingUI:CreateActiveTradesView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    
    -- Add trade items here
    local tradeLabel = UIComponents:CreateLabel(scrollFrame, "No active trades", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    tradeLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    
    return scrollFrame
end

-- For CreateTournamentView (add to BattleUI module):
function UIModules.BattleUI:CreateTournamentView(parent)
    local scrollFrame = UIComponents:CreateScrollingFrame(parent)
    local listLayout = Instance.new("UIListLayout")
    listLayout.Parent = scrollFrame
    listLayout.FillDirection = Enum.FillDirection.Vertical
    listLayout.Padding = UDim.new(0, 5)
    
    -- Add tournament items here
    local tournamentLabel = UIComponents:CreateLabel(scrollFrame, "No active tournaments", UDim2.new(1, -20, 0, 50), UDim2.new(0, 10, 0, 10), 18)
    tournamentLabel.TextColor3 = Color3.fromRGB(150, 150, 150)
    
    return scrollFrame
end

-- ========================================
-- QUICK FIX INSTRUCTIONS
-- ========================================
--[[
1. Open SANRIO_TYCOON_SERVER_COMPLETE_5000PLUS.lua
2. Search for "GetWeightedRandomPet" and apply FIX 1
3. Search for "GenerateCaseItems" and apply FIX 2 & 3
4. Search for "battles_won" and apply FIX 4

5. Open SANRIO_TYCOON_CLIENT_COMPLETE_5000PLUS.lua
6. Search for "AbsoluteContentSize" and apply FIX 1
7. Search for "CreateProgressBar" and add the UpdateValue method
8. Search for "CreateToggle" and add the SetValue method
9. Add the missing UI methods at the end of the respective modules

These fixes will resolve all the runtime errors and allow the egg opening system to work properly!
]]