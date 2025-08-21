-- Ensure required Remotes exist to prevent infinite yields on clients

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getOrCreate(parent: Instance, className: string, name: string)
	local existing = parent:FindFirstChild(name)
	if existing and existing:IsA(className) then
		return existing
	end
	if existing then
		existing:Destroy()
	end
	local obj = Instance.new(className)
	obj.Name = name
	obj.Parent = parent
	return obj
end

-- ShowAdminNotification RemoteEvent used by NotificationUI
getOrCreate(ReplicatedStorage, "RemoteEvent", "ShowAdminNotification")

-- Tycoon remotes bucket and AutoCollectToggle for shop toggle
local tycoonRemotes = ReplicatedStorage:FindFirstChild("TycoonRemotes")
if not tycoonRemotes then
	tycoonRemotes = Instance.new("Folder")
	tycoonRemotes.Name = "TycoonRemotes"
	tycoonRemotes.Parent = ReplicatedStorage
end

getOrCreate(tycoonRemotes, "RemoteEvent", "AutoCollectToggle")

