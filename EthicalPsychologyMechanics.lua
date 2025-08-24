--[[
  🧠 ETHICAL PSYCHOLOGY MECHANICS
  
  Implementing positive psychology for engagement without exploitation
  Focus on intrinsic motivation, achievement, and social connection
--]]

local EthicalPsychology = {}

-- Positive reinforcement system
local REINFORCEMENT_CONFIG = {
	-- Celebrate achievements, not purchases
	ACHIEVEMENT_TYPES = {
		EXPLORATION = {
			{id = "first_area", name = "Explorer", description = "Discover your first area"},
			{id = "all_areas", name = "World Traveler", description = "Discover all areas"},
		},
		CREATIVITY = {
			{id = "first_decoration", name = "Decorator", description = "Place your first decoration"},
			{id = "theme_master", name = "Theme Master", description = "Create a cohesive theme"},
		},
		SOCIAL = {
			{id = "first_friend", name = "Friendly", description = "Make your first friend"},
			{id = "helpful_player", name = "Helper", description = "Help 10 other players"},
		},
		PROGRESSION = {
			{id = "first_upgrade", name = "Builder", description = "Complete first upgrade"},
			{id = "tycoon_master", name = "Tycoon Master", description = "Fully upgrade tycoon"},
		}
	},
	
	-- Positive feedback without pressure
	FEEDBACK_MESSAGES = {
		SUCCESS = {
			"Great job! 🌟",
			"You're doing amazing! 🎉",
			"Fantastic work! 🏆",
			"Keep it up! 💪",
			"You're a star! ⭐"
		},
		ENCOURAGEMENT = {
			"You can do it! 💖",
			"Almost there! 🌈",
			"Keep trying! 🌸",
			"Believe in yourself! ✨",
			"You've got this! 🎀"
		},
		MILESTONE = {
			"Incredible achievement! 🏅",
			"You reached a milestone! 🎊",
			"Amazing progress! 📈",
			"You're unstoppable! 🚀",
			"What an accomplishment! 👑"
		}
	}
}

-- Intrinsic motivation mechanics
function EthicalPsychology:CreateMotivationSystem()
	local system = {
		-- Autonomy: Player choice and control
		autonomy = {
			customization_options = true,
			multiple_paths_to_success = true,
			optional_objectives = true,
			player_driven_goals = true
		},
		
		-- Mastery: Skill development
		mastery = {
			clear_progression = true,
			skill_based_challenges = true,
			learning_opportunities = true,
			practice_rewards = true
		},
		
		-- Purpose: Meaningful actions
		purpose = {
			helping_others = true,
			community_contribution = true,
			creative_expression = true,
			positive_impact = true
		}
	}
	
	return system
end

-- Achievement celebration UI
function EthicalPsychology:CelebrateAchievement(player, achievement)
	local gui = player:WaitForChild("PlayerGui")
	
	-- Create celebration frame
	local celebrationFrame = Instance.new("Frame")
	celebrationFrame.Size = UDim2.fromOffset(400, 200)
	celebrationFrame.Position = UDim2.fromScale(0.5, 0.3)
	celebrationFrame.AnchorPoint = Vector2.new(0.5, 0.5)
	celebrationFrame.BackgroundColor3 = Color3.fromRGB(255, 255, 255)
	celebrationFrame.Parent = gui
	
	-- Add rainbow gradient
	local gradient = Instance.new("UIGradient")
	gradient.Color = ColorSequence.new({
		ColorSequenceKeypoint.new(0, Color3.fromRGB(255, 182, 193)),
		ColorSequenceKeypoint.new(0.5, Color3.fromRGB(255, 218, 185)),
		ColorSequenceKeypoint.new(1, Color3.fromRGB(226, 240, 203))
	})
	gradient.Parent = celebrationFrame
	
	-- Achievement icon
	local icon = Instance.new("ImageLabel")
	icon.Size = UDim2.fromOffset(80, 80)
	icon.Position = UDim2.new(0, 20, 0.5, 0)
	icon.AnchorPoint = Vector2.new(0, 0.5)
	icon.Image = "rbxassetid://10709810284" -- Star icon
	icon.BackgroundTransparency = 1
	icon.Parent = celebrationFrame
	
	-- Achievement text
	local titleLabel = Instance.new("TextLabel")
	titleLabel.Text = achievement.name
	titleLabel.Size = UDim2.new(0.6, 0, 0, 40)
	titleLabel.Position = UDim2.new(0, 120, 0, 20)
	titleLabel.Font = Enum.Font.SourceSansBold
	titleLabel.TextScaled = true
	titleLabel.TextColor3 = Color3.fromRGB(50, 50, 50)
	titleLabel.BackgroundTransparency = 1
	titleLabel.Parent = celebrationFrame
	
	local descLabel = Instance.new("TextLabel")
	descLabel.Text = achievement.description
	descLabel.Size = UDim2.new(0.6, 0, 0, 60)
	descLabel.Position = UDim2.new(0, 120, 0, 70)
	descLabel.Font = Enum.Font.SourceSans
	descLabel.TextScaled = true
	descLabel.TextWrapped = true
	descLabel.TextColor3 = Color3.fromRGB(100, 100, 100)
	descLabel.BackgroundTransparency = 1
	descLabel.Parent = celebrationFrame
	
	-- Positive message
	local message = REINFORCEMENT_CONFIG.FEEDBACK_MESSAGES.MILESTONE[
		math.random(#REINFORCEMENT_CONFIG.FEEDBACK_MESSAGES.MILESTONE)
	]
	
	local messageLabel = Instance.new("TextLabel")
	messageLabel.Text = message
	messageLabel.Size = UDim2.new(1, -20, 0, 30)
	messageLabel.Position = UDim2.new(0, 10, 1, -40)
	messageLabel.Font = Enum.Font.Cartoon
	messageLabel.TextScaled = true
	messageLabel.TextColor3 = Color3.fromRGB(255, 100, 150)
	messageLabel.BackgroundTransparency = 1
	messageLabel.Parent = celebrationFrame
	
	-- Particle effect
	self:CreateCelebrationParticles(celebrationFrame)
	
	-- Animation
	celebrationFrame.Position = UDim2.fromScale(0.5, -0.2)
	local tween = game:GetService("TweenService"):Create(
		celebrationFrame,
		TweenInfo.new(0.5, Enum.EasingStyle.Back, Enum.EasingDirection.Out),
		{Position = UDim2.fromScale(0.5, 0.3)}
	)
	tween:Play()
	
	-- Auto dismiss
	wait(3)
	local fadeTween = game:GetService("TweenService"):Create(
		celebrationFrame,
		TweenInfo.new(0.5),
		{Position = UDim2.fromScale(0.5, 1.2)}
	)
	fadeTween:Play()
	fadeTween.Completed:Connect(function()
		celebrationFrame:Destroy()
	end)
end

-- Progress visualization (no pressure)
function EthicalPsychology:CreateProgressDisplay(player)
	local frame = Instance.new("Frame")
	frame.Name = "ProgressDisplay"
	frame.Size = UDim2.fromOffset(300, 400)
	frame.Position = UDim2.new(1, -320, 0, 100)
	frame.BackgroundColor3 = Color3.new(1, 1, 1)
	
	-- Title
	local title = Instance.new("TextLabel")
	title.Text = "Your Journey 🌟"
	title.Size = UDim2.new(1, 0, 0, 40)
	title.Font = Enum.Font.SourceSansBold
	title.TextScaled = true
	title.Parent = frame
	
	-- Progress categories
	local categories = {
		{name = "Building", icon = "🏗️", progress = 0.3},
		{name = "Decorating", icon = "🎨", progress = 0.5},
		{name = "Socializing", icon = "👥", progress = 0.2},
		{name = "Exploring", icon = "🗺️", progress = 0.7}
	}
	
	local yOffset = 60
	for _, category in ipairs(categories) do
		local catFrame = self:CreateCategoryProgress(category)
		catFrame.Position = UDim2.new(0, 10, 0, yOffset)
		catFrame.Parent = frame
		yOffset = yOffset + 80
	end
	
	-- Encouraging message
	local encouragement = Instance.new("TextLabel")
	encouragement.Text = "Every step counts! Keep exploring at your own pace 💖"
	encouragement.Size = UDim2.new(1, -20, 0, 60)
	encouragement.Position = UDim2.new(0, 10, 1, -70)
	encouragement.Font = Enum.Font.SourceSans
	encouragement.TextScaled = true
	encouragement.TextWrapped = true
	encouragement.TextColor3 = Color3.fromRGB(100, 200, 100)
	encouragement.BackgroundTransparency = 1
	encouragement.Parent = frame
	
	return frame
end

-- Daily login rewards (ethical version)
function EthicalPsychology:CreateDailyRewards()
	local rewards = {
		-- Small, consistent rewards that don't punish missing days
		{day = 1, reward = {type = "coins", amount = 100}, message = "Welcome back! 🌞"},
		{day = 2, reward = {type = "decoration", id = "flower_pot"}, message = "Happy to see you! 🌸"},
		{day = 3, reward = {type = "pet_food", amount = 5}, message = "Your pets missed you! 🐾"},
		{day = 4, reward = {type = "coins", amount = 200}, message = "Keep building! 🏗️"},
		{day = 5, reward = {type = "special_effect", id = "sparkles"}, message = "You're sparkling! ✨"},
		{day = 6, reward = {type = "coins", amount = 300}, message = "Almost a week! 📅"},
		{day = 7, reward = {type = "exclusive_decoration", id = "rainbow_fountain"}, message = "A week of fun! 🌈"}
	}
	
	-- Reset to day 1 after day 7, no streak pressure
	return {
		rewards = rewards,
		reset_weekly = true,
		no_punishment_for_missing = true,
		bonus_for_consistency = false, -- No FOMO
		flexible_claim_window = 48 -- Can claim within 48 hours
	}
end

-- Social features (positive only)
function EthicalPsychology:CreateSocialFeatures()
	return {
		-- Collaborative features
		visit_friends = {
			enabled = true,
			leave_gifts = true,
			help_with_tasks = true,
			no_stealing = true -- No negative interactions
		},
		
		-- Recognition system
		kudos_system = {
			enabled = true,
			types = {"Helpful", "Creative", "Friendly", "Inspiring"},
			daily_limit = 10, -- Prevent spam
			rewards_giver = true -- Encourage giving
		},
		
		-- Community challenges
		group_goals = {
			enabled = true,
			everyone_wins = true, -- No competition
			scaled_contribution = true, -- All contributions matter
			celebrate_together = true
		}
	}
end

-- Mindful gaming features
function EthicalPsychology:CreateWellbeingFeatures()
	local features = {}
	
	-- Break reminders (gentle, not forced)
	features.break_reminder = function(player, playtime)
		if playtime % 3600 == 0 then -- Every hour
			local reminder = Instance.new("TextLabel")
			reminder.Text = "You've been playing for an hour! Maybe stretch a bit? 🌟"
			reminder.Size = UDim2.fromOffset(400, 50)
			reminder.Position = UDim2.fromScale(0.5, 0.1)
			reminder.AnchorPoint = Vector2.new(0.5, 0)
			reminder.Font = Enum.Font.SourceSans
			reminder.TextScaled = true
			reminder.BackgroundColor3 = Color3.fromRGB(255, 255, 200)
			reminder.Parent = player.PlayerGui
			
			-- Auto dismiss
			game:GetService("Debris"):AddItem(reminder, 10)
		end
	end
	
	-- Positive daily tips
	features.daily_tips = {
		"Remember to be kind to other players! 💖",
		"Every creation is unique and special! 🎨",
		"It's okay to take breaks and come back later! 🌈",
		"Helping others makes the game more fun! 🤝",
		"Your pace is the perfect pace! 🐌",
		"Mistakes are just learning opportunities! 📚",
		"Have you smiled today? 😊",
		"You're doing great, just as you are! ⭐"
	}
	
	-- No dark patterns
	features.ethical_principles = {
		no_fomo = true,
		no_appointment_mechanics = true,
		no_punishment_for_breaks = true,
		no_pay_to_win = true,
		no_gambling = true,
		transparent_mechanics = true
	}
	
	return features
end

-- Achievement tracker (celebrates all play styles)
function EthicalPsychology:TrackPlayerProgress(player, action, value)
	local progress = player:FindFirstChild("ProgressData") or Instance.new("Folder")
	progress.Name = "ProgressData"
	progress.Parent = player
	
	-- Track various activities without judgment
	local activities = {
		building = "Building",
		decorating = "Decorating", 
		socializing = "Socializing",
		exploring = "Exploring",
		helping = "Helping",
		creating = "Creating",
		resting = "Resting" -- Even taking breaks is valid!
	}
	
	local stat = progress:FindFirstChild(activities[action])
	if not stat then
		stat = Instance.new("IntValue")
		stat.Name = activities[action]
		stat.Parent = progress
	end
	
	stat.Value = stat.Value + value
	
	-- Check for milestone celebrations (no pressure)
	if stat.Value % 10 == 0 then
		self:SendEncouragement(player, action, stat.Value)
	end
end

-- Send positive reinforcement
function EthicalPsychology:SendEncouragement(player, activity, milestone)
	local messages = REINFORCEMENT_CONFIG.FEEDBACK_MESSAGES.ENCOURAGEMENT
	local message = messages[math.random(#messages)]
	
	-- Create encouraging notification
	local notification = Instance.new("TextLabel")
	notification.Text = string.format("%s You've done %s %d times!", message, activity, milestone)
	notification.Size = UDim2.fromOffset(300, 60)
	notification.Position = UDim2.fromScale(0.5, 0.9)
	notification.AnchorPoint = Vector2.new(0.5, 1)
	notification.Font = Enum.Font.Cartoon
	notification.TextScaled = true
	notification.BackgroundColor3 = Color3.fromRGB(255, 240, 200)
	notification.TextColor3 = Color3.fromRGB(100, 50, 0)
	notification.Parent = player.PlayerGui
	
	-- Gentle fade out
	wait(2)
	local tween = game:GetService("TweenService"):Create(
		notification,
		TweenInfo.new(1),
		{BackgroundTransparency = 1, TextTransparency = 1}
	)
	tween:Play()
	tween.Completed:Connect(function()
		notification:Destroy()
	end)
end

return EthicalPsychology