-- ========================================
-- JANITOR MODULE
-- Professional memory management for Roblox
-- Prevents memory leaks automatically
-- ========================================

local Janitor = {}
Janitor.__index = Janitor

-- Supported cleanup methods
local CLEANUP_METHODS = {
    ["function"] = true,
    ["RBXScriptConnection"] = "Disconnect",
    ["Instance"] = "Destroy",
    ["table"] = true, -- Will check for Destroy/Disconnect/destroy/disconnect methods
}

-- ========================================
-- CONSTRUCTOR
-- ========================================
function Janitor.new()
    local self = setmetatable({}, Janitor)
    self._tasks = {}
    self._cleaning = false
    return self
end

-- ========================================
-- ADD TASK FOR CLEANUP
-- ========================================
function Janitor:Add(task, cleanupMethod)
    if self._cleaning then
        error("Cannot add tasks while cleaning", 2)
    end
    
    -- Determine cleanup method if not provided
    if not cleanupMethod then
        local taskType = typeof(task)
        
        if taskType == "function" then
            cleanupMethod = task
            task = nil
        elseif taskType == "RBXScriptConnection" then
            cleanupMethod = "Disconnect"
        elseif taskType == "Instance" then
            cleanupMethod = "Destroy"
        elseif taskType == "table" then
            -- Check for common cleanup methods
            if task.Destroy then
                cleanupMethod = "Destroy"
            elseif task.destroy then
                cleanupMethod = "destroy"
            elseif task.Disconnect then
                cleanupMethod = "Disconnect"
            elseif task.disconnect then
                cleanupMethod = "disconnect"
            elseif task.Remove then
                cleanupMethod = "Remove"
            elseif task.remove then
                cleanupMethod = "remove"
            else
                error("Table task has no recognizable cleanup method", 2)
            end
        else
            error("Unsupported task type: " .. taskType, 2)
        end
    end
    
    table.insert(self._tasks, {
        task = task,
        cleanupMethod = cleanupMethod
    })
    
    return task
end

-- ========================================
-- ADD TASK WITH CUSTOM INDEX
-- ========================================
function Janitor:AddObject(index, task, cleanupMethod)
    if self._cleaning then
        error("Cannot add tasks while cleaning", 2)
    end
    
    -- Remove existing task with same index if it exists
    self:RemoveObject(index)
    
    -- Add the new task
    self._tasks[index] = {
        task = task,
        cleanupMethod = cleanupMethod or self:_getCleanupMethod(task)
    }
    
    return task
end

-- ========================================
-- REMOVE SPECIFIC INDEXED TASK
-- ========================================
function Janitor:RemoveObject(index)
    local taskData = self._tasks[index]
    if taskData then
        self:_cleanupTask(taskData)
        self._tasks[index] = nil
    end
end

-- ========================================
-- LINK JANITORS (PARENT-CHILD)
-- ========================================
function Janitor:LinkToInstance(instance)
    if typeof(instance) ~= "Instance" then
        error("Can only link to Instance objects", 2)
    end
    
    return self:Add(instance.AncestryChanged:Connect(function(_, parent)
        if not parent then
            self:Cleanup()
        end
    end))
end

-- ========================================
-- CLEANUP ALL TASKS
-- ========================================
function Janitor:Cleanup()
    if self._cleaning then
        return
    end
    
    self._cleaning = true
    
    -- Clean indexed tasks
    for index, taskData in pairs(self._tasks) do
        if type(index) ~= "number" then
            self:_cleanupTask(taskData)
        end
    end
    
    -- Clean array tasks (in reverse order)
    for i = #self._tasks, 1, -1 do
        local taskData = self._tasks[i]
        if taskData then
            self:_cleanupTask(taskData)
        end
    end
    
    table.clear(self._tasks)
    self._cleaning = false
end

-- Alias for Cleanup
function Janitor:Destroy()
    self:Cleanup()
end

-- ========================================
-- INTERNAL CLEANUP METHOD
-- ========================================
function Janitor:_cleanupTask(taskData)
    local task = taskData.task
    local cleanupMethod = taskData.cleanupMethod
    
    if type(cleanupMethod) == "function" then
        -- Custom cleanup function
        local success, err = pcall(cleanupMethod, task)
        if not success then
            warn("Janitor cleanup error:", err)
        end
    elseif type(cleanupMethod) == "string" and task then
        -- Method name
        local method = task[cleanupMethod]
        if method then
            local success, err = pcall(method, task)
            if not success then
                warn("Janitor cleanup error:", err)
            end
        end
    end
end

-- ========================================
-- GET CLEANUP METHOD
-- ========================================
function Janitor:_getCleanupMethod(task)
    local taskType = typeof(task)
    
    if taskType == "RBXScriptConnection" then
        return "Disconnect"
    elseif taskType == "Instance" then
        return "Destroy"
    elseif taskType == "table" then
        if task.Destroy then
            return "Destroy"
        elseif task.destroy then
            return "destroy"
        elseif task.Disconnect then
            return "Disconnect"
        elseif task.disconnect then
            return "disconnect"
        end
    end
    
    error("Cannot determine cleanup method for task type: " .. taskType, 3)
end

-- ========================================
-- ADVANCED FEATURES
-- ========================================

-- Create a task that cleans up after a duration
function Janitor:AddDelayedCleanup(duration, task, cleanupMethod)
    local connection
    connection = task.spawn(function()
        task.wait(duration)
        self:RemoveObject(connection)
        self:Add(task, cleanupMethod)
    end)
    
    self:AddObject(connection, connection)
    return task
end

-- Add a janitor as a task to another janitor
function Janitor:AddJanitor(janitor)
    if getmetatable(janitor) ~= Janitor then
        error("Argument must be a Janitor", 2)
    end
    
    return self:Add(janitor, "Cleanup")
end

-- Create a promise-compatible cleanup
function Janitor:AddPromise(promise)
    if type(promise) ~= "table" or not promise.cancel then
        error("Invalid promise object", 2)
    end
    
    return self:Add(promise, "cancel")
end

-- ========================================
-- USAGE EXAMPLES
-- ========================================
--[[
Example 1: Basic UI Cleanup
```lua
local janitor = Janitor.new()

-- Add connection
janitor:Add(button.MouseButton1Click:Connect(function()
    print("Clicked!")
end))

-- Add instance
janitor:Add(frame)

-- Add custom cleanup
janitor:Add(function()
    print("Custom cleanup!")
end)

-- Clean everything
janitor:Cleanup()
```

Example 2: Indexed Tasks
```lua
local janitor = Janitor.new()

-- Add with custom index
janitor:AddObject("MainConnection", RunService.Heartbeat:Connect(function()
    -- Update logic
end))

-- Replace the connection later
janitor:AddObject("MainConnection", RunService.Stepped:Connect(function()
    -- Different update logic
end))

-- Remove specific task
janitor:RemoveObject("MainConnection")
```

Example 3: Nested Janitors
```lua
local mainJanitor = Janitor.new()
local subJanitor = Janitor.new()

-- Link janitors
mainJanitor:AddJanitor(subJanitor)

-- When mainJanitor cleans up, subJanitor will too
mainJanitor:Cleanup()
```
--]]

return Janitor