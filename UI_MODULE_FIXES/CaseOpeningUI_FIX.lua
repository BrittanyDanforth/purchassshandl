--[[
    Case Opening UI Fix
    Fix for ClientModules/UIModules/CaseOpeningUI.lua
]]

-- Fix the ShowResult function (around line 525) to handle nil pet names:
function CaseOpeningUI:ShowResult(result)
    if not result then return end
    
    -- Ensure result has all required fields
    result.petName = result.petName or result.name or "Unknown Pet"
    result.rarity = result.rarity or "Common"
    result.isNew = result.isNew ~= false
    
    local resultFrame = self.ResultFrame
    if not resultFrame then return end
    
    -- Update pet image
    local petImage = resultFrame:FindFirstChild("PetImage")
    if petImage then
        petImage.Image = result.icon or ""
    end
    
    -- Update pet name - safely concatenate
    local nameLabel = resultFrame:FindFirstChild("PetName")
    if nameLabel then
        nameLabel.Text = tostring(result.petName)
    end
    
    -- Update rarity
    local rarityLabel = resultFrame:FindFirstChild("Rarity")
    if rarityLabel then
        rarityLabel.Text = tostring(result.rarity)
        rarityLabel.TextColor3 = self._config:GetRarityColor(result.rarityLevel or 1)
    end
    
    -- Show NEW badge if applicable
    local newBadge = resultFrame:FindFirstChild("NewBadge")
    if newBadge then
        newBadge.Visible = result.isNew == true
    end
end

-- Also ensure the Open function properly structures results:
function CaseOpeningUI:Open(results, eggData)
    if not results then return end
    
    -- Ensure each result has proper structure
    for i, result in ipairs(results) do
        if type(result) == "table" then
            result.petName = result.petName or result.name or ("Pet " .. i)
            result.rarity = result.rarity or "Common"
        end
    end
    
    -- Create overlay if needed
    if not self.Overlay then
        self:CreateOverlay()
    end
    
    -- Make visible
    if self.Overlay then
        self.Overlay.Visible = true
        self.Overlay.Parent = game.Players.LocalPlayer.PlayerGui
    end
    
    -- Store data
    self._currentResults = results
    self._currentEggData = eggData or {name = "Mystery Egg"}
    
    -- Start animation
    self:StartCaseOpeningSequence()
end