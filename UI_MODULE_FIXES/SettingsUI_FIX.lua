--[[
    Settings UI Fix
    Replace lines 1480-1495 in ClientModules/UIModules/SettingsUI.lua with this:
]]

function SettingsUI:ApplySettings()
    -- Apply all settings with proper checks
    if self._soundSystem then
        -- Check if methods exist before calling
        local masterVolume = (self.Settings.masterVolume or 100) / 100
        local musicVolume = (self.Settings.musicVolume or 80) / 100
        local sfxVolume = (self.Settings.sfxVolume or 100) / 100
        
        -- Set master volume
        if self._soundSystem.SetMasterVolume then
            self._soundSystem:SetMasterVolume(masterVolume)
        elseif self._soundSystem._masterVolume ~= nil then
            self._soundSystem._masterVolume = masterVolume
        end
        
        -- Set music volume
        if self._soundSystem.SetMusicVolume then
            self._soundSystem:SetMusicVolume(musicVolume)
        elseif self._soundSystem._musicVolume ~= nil then
            self._soundSystem._musicVolume = musicVolume
        end
        
        -- Set SFX volume
        if self._soundSystem.SetSFXVolume then
            self._soundSystem:SetSFXVolume(sfxVolume)
        elseif self._soundSystem._sfxVolume ~= nil then
            self._soundSystem._sfxVolume = sfxVolume
        end
    end
    
    -- Apply other settings...
end

-- Also add this to the Close function (around line 197):
function SettingsUI:Close()
    if self.Frame then
        self.Frame.Visible = false
        
        -- Save any unsaved changes
        if self.UnsavedChanges then
            self:SaveSettings()
        end
        
        -- Notify window manager
        if self._windowManager then
            self._windowManager:CloseWindow("SettingsUI")
        end
    end
end