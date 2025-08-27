-- ========================================
-- MARKET SYSTEM MODULE
-- Complete marketplace for trading pets and items
-- ========================================

local MarketSystem = {}

-- Dependencies
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local DataStoreService = game:GetService("DataStoreService")
local HttpService = game:GetService("HttpService")

-- Constants
local MARKET_VERSION = 1
local MAX_LISTINGS_PER_PLAYER = 10
local LISTING_DURATION = 24 * 60 * 60 -- 24 hours
local MARKET_TAX = 0.05 -- 5% tax on sales
local MIN_PRICE = 10
local MAX_PRICE = 999999999

-- Market categories
local CATEGORIES = {
    PETS = "pets",
    ITEMS = "items",
    BUNDLES = "bundles"
}

-- Sorting options
local SORT_OPTIONS = {
    PRICE_LOW = "price_low",
    PRICE_HIGH = "price_high",
    NEWEST = "newest",
    ENDING_SOON = "ending_soon",
    RARITY = "rarity"
}

-- Initialize
function MarketSystem:Init()
    -- Use proper module requires instead of globals
    self.Configuration = require(script.Parent.Configuration)
    self.DataStoreModule = require(script.Parent.DataStoreModule)
    self.PetSystem = require(script.Parent.PetSystem)
    self.PetDatabase = require(script.Parent.PetDatabase)
    
    -- Market data
    self.ActiveListings = {}
    self.ListingsByPlayer = {}
    self.RecentSales = {}
    self.PriceHistory = {}
    
    -- DataStore for persistent market data
    self.MarketDataStore = DataStoreService:GetDataStore("MarketDataV" .. MARKET_VERSION)
    self.PriceDataStore = DataStoreService:GetDataStore("PriceHistoryV" .. MARKET_VERSION)
    
    -- Load market data
    self:LoadMarketData()
    
    -- Start cleanup loop
    spawn(function()
        while true do
            wait(60) -- Check every minute
            self:CleanupExpiredListings()
        end
    end)
    
    -- Price history is now updated efficiently on each sale
    -- No need for the inefficient UpdatePriceHistory loop
    
    print("[MarketSystem] Initialized")
end

-- ========================================
-- LISTING MANAGEMENT
-- ========================================

function MarketSystem:CreateListing(player, itemType, itemData, price, duration)
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    -- Validate listing
    local validation = self:ValidateListing(player, itemType, itemData, price, duration)
    if not validation.success then
        return validation
    end
    
    -- Check listing limit
    local playerListings = self.ListingsByPlayer[player.UserId] or {}
    if #playerListings >= MAX_LISTINGS_PER_PLAYER then
        return {success = false, error = "Maximum listings reached (" .. MAX_LISTINGS_PER_PLAYER .. ")"}
    end
    
    -- Create listing ID
    local listingId = HttpService:GenerateGUID(false)
    
    -- Process based on item type
    local listingData = {
        id = listingId,
        sellerId = player.UserId,
        sellerName = player.Name,
        itemType = itemType,
        price = price,
        createdAt = os.time(),
        expiresAt = os.time() + (duration or LISTING_DURATION),
        status = "active"
    }
    
    if itemType == CATEGORIES.PETS then
        -- Remove pet from player inventory
        local pet = playerData.pets[itemData.petId]
        if not pet then
            return {success = false, error = "Pet not found in inventory"}
        end
        
        if pet.equipped then
            return {success = false, error = "Cannot list equipped pets"}
        end
        
        -- Store pet data in listing
        listingData.itemData = {
            petId = itemData.petId,
            petType = pet.petId,
            level = pet.level,
            experience = pet.experience,
            nickname = pet.nickname,
            variant = pet.variant,
            enchantments = pet.enchantments,
            statistics = pet.statistics
        }
        
        -- Add display data
        local petDbData = self.PetDatabase:GetPet(pet.petId)
        if petDbData then
            listingData.displayData = {
                name = pet.nickname or petDbData.displayName,
                imageId = petDbData.imageId,
                rarity = petDbData.rarity,
                category = petDbData.category
            }
        end
        
        -- Remove from inventory
        playerData.pets[itemData.petId] = nil
        
    elseif itemType == CATEGORIES.ITEMS then
        -- Handle item listings (future implementation)
        return {success = false, error = "Item market coming soon!"}
        
    elseif itemType == CATEGORIES.BUNDLES then
        -- Handle bundle listings (future implementation)
        return {success = false, error = "Bundle market coming soon!"}
    end
    
    -- Add to active listings
    self.ActiveListings[listingId] = listingData
    
    -- Track by player
    if not self.ListingsByPlayer[player.UserId] then
        self.ListingsByPlayer[player.UserId] = {}
    end
    table.insert(self.ListingsByPlayer[player.UserId], listingId)
    
    -- Save to DataStore
    self:SaveListing(listingData)
    
    -- Mark player data dirty
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Fire events
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.MarketListingCreated:FireClient(player, listingData)
    RemoteEvents.MarketUpdated:FireAllClients()
    
    return {
        success = true,
        listingId = listingId,
        expiresAt = listingData.expiresAt
    }
end

function MarketSystem:CancelListing(player, listingId)
    local listing = self.ActiveListings[listingId]
    if not listing then
        return {success = false, error = "Listing not found"}
    end
    
    if listing.sellerId ~= player.UserId then
        return {success = false, error = "You don't own this listing"}
    end
    
    if listing.status ~= "active" then
        return {success = false, error = "Listing is not active"}
    end
    
    -- Return item to player
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    if listing.itemType == CATEGORIES.PETS then
        -- Return pet to inventory
        local petData = listing.itemData
        playerData.pets[petData.petId] = {
            id = petData.petId,
            petId = petData.petType,
            level = petData.level,
            experience = petData.experience,
            nickname = petData.nickname,
            variant = petData.variant,
            enchantments = petData.enchantments,
            statistics = petData.statistics,
            equipped = false
        }
    end
    
    -- Update listing status
    listing.status = "cancelled"
    listing.cancelledAt = os.time()
    
    -- Remove from active listings
    self.ActiveListings[listingId] = nil
    
    -- Remove from player listings
    local playerListings = self.ListingsByPlayer[player.UserId]
    if playerListings then
        for i, id in ipairs(playerListings) do
            if id == listingId then
                table.remove(playerListings, i)
                break
            end
        end
    end
    
    -- Update DataStore
    self:RemoveListing(listingId)
    
    -- Mark player data dirty
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    
    -- Fire events
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.MarketListingCancelled:FireClient(player, listingId)
    RemoteEvents.MarketUpdated:FireAllClients()
    
    return {success = true}
end

function MarketSystem:PurchaseListing(player, listingId)
    local listing = self.ActiveListings[listingId]
    if not listing then
        return {success = false, error = "Listing not found or expired"}
    end
    
    if listing.sellerId == player.UserId then
        return {success = false, error = "Cannot buy your own listing"}
    end
    
    if listing.status ~= "active" then
        return {success = false, error = "Listing is no longer available"}
    end
    
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    -- Check currency
    local currency = "coins" -- Default to coins, could be gems based on listing
    if playerData.currencies[currency] < listing.price then
        return {success = false, error = "Insufficient funds"}
    end
    
    -- Process purchase
    -- Deduct from buyer
    playerData.currencies[currency] = playerData.currencies[currency] - listing.price
    
    -- Add to seller (minus tax)
    local seller = Players:GetPlayerByUserId(listing.sellerId)
    local sellerData = self.DataStoreModule:GetPlayerData(listing.sellerId)
    
    if sellerData then
        local taxAmount = math.floor(listing.price * MARKET_TAX)
        local sellerAmount = listing.price - taxAmount
        
        sellerData.currencies[currency] = (sellerData.currencies[currency] or 0) + sellerAmount
        sellerData.statistics.marketSales = (sellerData.statistics.marketSales or 0) + 1
        sellerData.statistics.marketEarnings = (sellerData.statistics.marketEarnings or 0) + sellerAmount
        
        -- Send notification to seller if online
        if seller then
            local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
            RemoteEvents.NotificationSent:FireClient(seller, {
                title = "Item Sold!",
                message = "Your " .. (listing.displayData and listing.displayData.name or "item") .. " sold for " .. sellerAmount .. " " .. currency,
                type = "success"
            })
        end
    end
    
    -- Transfer item to buyer
    if listing.itemType == CATEGORIES.PETS then
        local petData = listing.itemData
        playerData.pets[petData.petId] = {
            id = petData.petId,
            petId = petData.petType,
            level = petData.level,
            experience = petData.experience,
            nickname = petData.nickname,
            variant = petData.variant,
            enchantments = petData.enchantments,
            statistics = petData.statistics,
            equipped = false,
            obtainedFrom = "market",
            obtainedAt = os.time()
        }
    end
    
    -- Update statistics
    playerData.statistics.marketPurchases = (playerData.statistics.marketPurchases or 0) + 1
    playerData.statistics.marketSpent = (playerData.statistics.marketSpent or 0) + listing.price
    
    -- Update listing
    listing.status = "sold"
    listing.soldAt = os.time()
    listing.buyerId = player.UserId
    listing.buyerName = player.Name
    
    -- Add to recent sales
    table.insert(self.RecentSales, 1, {
        listingId = listingId,
        itemType = listing.itemType,
        displayData = listing.displayData,
        price = listing.price,
        sellerId = listing.sellerId,
        sellerName = listing.sellerName,
        buyerId = player.UserId,
        buyerName = player.Name,
        soldAt = os.time()
    })
    
    -- Keep only last 100 sales
    if #self.RecentSales > 100 then
        self.RecentSales = {unpack(self.RecentSales, 1, 100)}
    end
    
    -- ==========================================================
    -- ADD THIS CODE TO EFFICIENTLY UPDATE PRICE HISTORY
    -- ==========================================================
    -- Record this sale for price history
    if listing.itemType == CATEGORIES.PETS then
        local petType = listing.itemData.petType
        local key = CATEGORIES.PETS .. "_" .. petType
        
        if not self.PriceHistory[key] then
            self.PriceHistory[key] = {}
        end
        
        table.insert(self.PriceHistory[key], 1, {
            timestamp = os.time(),
            price = listing.price,
            level = listing.itemData.level,
            variant = listing.itemData.variant
        })
        
        -- Keep only the last 50-100 sales per item to save space
        if #self.PriceHistory[key] > 50 then
            self.PriceHistory[key] = {unpack(self.PriceHistory[key], 1, 50)}
        end
    end
    -- ==========================================================
    
    -- Remove from active listings
    self.ActiveListings[listingId] = nil
    
    -- Remove from seller's listings
    local sellerListings = self.ListingsByPlayer[listing.sellerId]
    if sellerListings then
        for i, id in ipairs(sellerListings) do
            if id == listingId then
                table.remove(sellerListings, i)
                break
            end
        end
    end
    
    -- Update DataStore
    self:RemoveListing(listingId)
    
    -- Mark data dirty
    self.DataStoreModule:MarkPlayerDirty(player.UserId)
    if sellerData then
        self.DataStoreModule:MarkPlayerDirty(listing.sellerId)
    end
    
    -- Fire events
    local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
    RemoteEvents.MarketPurchaseComplete:FireClient(player, listing)
    RemoteEvents.MarketUpdated:FireAllClients()
    
    return {
        success = true,
        item = listing.itemData,
        displayData = listing.displayData
    }
end

-- ========================================
-- SEARCH AND FILTERING
-- ========================================

function MarketSystem:SearchListings(filters)
    local results = {}
    
    for listingId, listing in pairs(self.ActiveListings) do
        if listing.status == "active" then
            local match = true
            
            -- Category filter
            if filters.category and listing.itemType ~= filters.category then
                match = false
            end
            
            -- Search query
            if match and filters.search then
                local searchLower = filters.search:lower()
                local found = false
                
                if listing.displayData then
                    if listing.displayData.name and listing.displayData.name:lower():find(searchLower) then
                        found = true
                    end
                end
                
                if not found then
                    match = false
                end
            end
            
            -- Price range
            if match and filters.minPrice and listing.price < filters.minPrice then
                match = false
            end
            
            if match and filters.maxPrice and listing.price > filters.maxPrice then
                match = false
            end
            
            -- Rarity filter (for pets)
            if match and filters.rarity and listing.displayData and listing.displayData.rarity then
                if listing.displayData.rarity ~= filters.rarity then
                    match = false
                end
            end
            
            -- Level filter (for pets)
            if match and filters.minLevel and listing.itemData and listing.itemData.level then
                if listing.itemData.level < filters.minLevel then
                    match = false
                end
            end
            
            if match then
                table.insert(results, listing)
            end
        end
    end
    
    -- Sort results
    local sortBy = filters.sortBy or SORT_OPTIONS.NEWEST
    
    if sortBy == SORT_OPTIONS.PRICE_LOW then
        table.sort(results, function(a, b) return a.price < b.price end)
    elseif sortBy == SORT_OPTIONS.PRICE_HIGH then
        table.sort(results, function(a, b) return a.price > b.price end)
    elseif sortBy == SORT_OPTIONS.NEWEST then
        table.sort(results, function(a, b) return a.createdAt > b.createdAt end)
    elseif sortBy == SORT_OPTIONS.ENDING_SOON then
        table.sort(results, function(a, b) return a.expiresAt < b.expiresAt end)
    elseif sortBy == SORT_OPTIONS.RARITY then
        table.sort(results, function(a, b)
            local rarityA = a.displayData and a.displayData.rarity or 1
            local rarityB = b.displayData and b.displayData.rarity or 1
            return rarityA > rarityB
        end)
    end
    
    -- Pagination
    local page = filters.page or 1
    local pageSize = filters.pageSize or 20
    local startIndex = (page - 1) * pageSize + 1
    local endIndex = startIndex + pageSize - 1
    
    local paginatedResults = {}
    for i = startIndex, math.min(endIndex, #results) do
        if results[i] then
            table.insert(paginatedResults, results[i])
        end
    end
    
    return {
        success = true,
        results = paginatedResults,
        totalResults = #results,
        page = page,
        totalPages = math.ceil(#results / pageSize)
    }
end

function MarketSystem:GetPlayerListings(player)
    local listings = {}
    local playerListingIds = self.ListingsByPlayer[player.UserId] or {}
    
    for _, listingId in ipairs(playerListingIds) do
        local listing = self.ActiveListings[listingId]
        if listing then
            table.insert(listings, listing)
        end
    end
    
    return {
        success = true,
        listings = listings,
        count = #listings,
        maxListings = MAX_LISTINGS_PER_PLAYER
    }
end

function MarketSystem:GetRecentSales()
    return {
        success = true,
        sales = self.RecentSales
    }
end

function MarketSystem:GetPriceHistory(itemType, itemId)
    local key = itemType .. "_" .. itemId
    local history = self.PriceHistory[key] or {}
    
    return {
        success = true,
        history = history,
        averagePrice = self:CalculateAveragePrice(history),
        trend = self:CalculatePriceTrend(history)
    }
end

-- ========================================
-- VALIDATION AND UTILITIES
-- ========================================

function MarketSystem:ValidateListing(player, itemType, itemData, price, duration)
    -- Validate price
    if not price or type(price) ~= "number" then
        return {success = false, error = "Invalid price"}
    end
    
    if price < MIN_PRICE then
        return {success = false, error = "Minimum price is " .. MIN_PRICE}
    end
    
    if price > MAX_PRICE then
        return {success = false, error = "Maximum price is " .. MAX_PRICE}
    end
    
    -- Validate item type
    local validType = false
    for _, category in pairs(CATEGORIES) do
        if itemType == category then
            validType = true
            break
        end
    end
    
    if not validType then
        return {success = false, error = "Invalid item type"}
    end
    
    -- Validate duration
    if duration and (duration < 3600 or duration > 7 * 24 * 60 * 60) then
        return {success = false, error = "Invalid duration"}
    end
    
    -- ENHANCED VALIDATION: Check item ownership and validity
    local playerData = self.DataStoreModule:GetPlayerData(player)
    if not playerData then
        return {success = false, error = "Player data not found"}
    end
    
    if itemType == CATEGORIES.PETS then
        if not itemData or not itemData.petId then
            return {success = false, error = "Invalid pet data"}
        end
        
        local pet = playerData.pets[itemData.petId]
        if not pet then
            return {success = false, error = "You don't own this pet"}
        end
        
        if pet.equipped then
            return {success = false, error = "Cannot list equipped pets"}
        end
        
        if pet.locked then
            return {success = false, error = "Cannot list locked pets"}
        end
    elseif itemType == CATEGORIES.ITEMS then
        if not itemData or not itemData.itemId then
            return {success = false, error = "Invalid item data"}
        end
        
        -- Check item ownership in inventory
        local hasItem = false
        if playerData.inventory and playerData.inventory[itemData.itemId] then
            hasItem = playerData.inventory[itemData.itemId] > 0
        end
        
        if not hasItem then
            return {success = false, error = "You don't own this item"}
        end
    end
    
    -- Check listing limits
    local playerListings = self.ListingsByPlayer[player.UserId] or {}
    if #playerListings >= MAX_LISTINGS_PER_PLAYER then
        return {success = false, error = "You have reached the maximum number of listings (" .. MAX_LISTINGS_PER_PLAYER .. ")"}
    end
    
    return {success = true}
end

function MarketSystem:CleanupExpiredListings()
    local currentTime = os.time()
    local expiredListings = {}
    
    for listingId, listing in pairs(self.ActiveListings) do
        if listing.expiresAt <= currentTime and listing.status == "active" then
            table.insert(expiredListings, listing)
        end
    end
    
    for _, listing in ipairs(expiredListings) do
        -- Return item to owner
        local ownerData = self.DataStoreModule:GetPlayerData(listing.sellerId)
        if ownerData then
            if listing.itemType == CATEGORIES.PETS then
                local petData = listing.itemData
                ownerData.pets[petData.petId] = {
                    id = petData.petId,
                    petId = petData.petType,
                    level = petData.level,
                    experience = petData.experience,
                    nickname = petData.nickname,
                    variant = petData.variant,
                    enchantments = petData.enchantments,
                    statistics = petData.statistics,
                    equipped = false
                }
                
                self.DataStoreModule:MarkPlayerDirty(listing.sellerId)
            end
            
            -- Notify if online
            local seller = Players:GetPlayerByUserId(listing.sellerId)
            if seller then
                local RemoteEvents = game.ReplicatedStorage:WaitForChild("RemoteEvents")
                RemoteEvents.NotificationSent:FireClient(seller, {
                    title = "Listing Expired",
                    message = "Your " .. (listing.displayData and listing.displayData.name or "item") .. " listing has expired and been returned",
                    type = "info"
                })
            end
        end
        
        -- Update listing
        listing.status = "expired"
        listing.expiredAt = currentTime
        
        -- Remove from active
        self.ActiveListings[listing.id] = nil
        
        -- Remove from player listings
        local playerListings = self.ListingsByPlayer[listing.sellerId]
        if playerListings then
            for i, id in ipairs(playerListings) do
                if id == listing.id then
                    table.remove(playerListings, i)
                    break
                end
            end
        end
        
        -- Update DataStore
        self:RemoveListing(listing.id)
    end
    
    if #expiredListings > 0 then
        print("[MarketSystem] Cleaned up", #expiredListings, "expired listings")
    end
end

-- UpdatePriceHistory function removed - price history is now recorded on each sale

function MarketSystem:CalculateAveragePrice(history)
    if #history == 0 then return 0 end
    
    local total = 0
    local count = 0
    
    -- Weight recent prices more heavily
    for i, entry in ipairs(history) do
        local weight = math.max(1, #history - i + 1)
        total = total + (entry.averagePrice * weight)
        count = count + weight
    end
    
    return math.floor(total / count)
end

function MarketSystem:CalculatePriceTrend(history)
    if #history < 2 then return "stable" end
    
    -- Compare last 3 entries to previous 3
    local recent = 0
    local previous = 0
    local recentCount = 0
    local previousCount = 0
    
    for i = 1, math.min(3, #history) do
        recent = recent + history[i].averagePrice
        recentCount = recentCount + 1
    end
    
    for i = 4, math.min(6, #history) do
        previous = previous + history[i].averagePrice
        previousCount = previousCount + 1
    end
    
    if previousCount == 0 then return "stable" end
    
    local recentAvg = recent / recentCount
    local previousAvg = previous / previousCount
    
    local change = (recentAvg - previousAvg) / previousAvg
    
    if change > 0.1 then
        return "rising"
    elseif change < -0.1 then
        return "falling"
    else
        return "stable"
    end
end

-- ========================================
-- DATA PERSISTENCE
-- ========================================

function MarketSystem:LoadMarketData()
    -- Load active listings from DataStore
    local success, data = pcall(function()
        return self.MarketDataStore:GetAsync("ActiveListings")
    end)
    
    if success and data then
        -- Validate and load listings
        for listingId, listing in pairs(data) do
            if listing.expiresAt > os.time() and listing.status == "active" then
                self.ActiveListings[listingId] = listing
                
                -- Rebuild player listing index
                if not self.ListingsByPlayer[listing.sellerId] then
                    self.ListingsByPlayer[listing.sellerId] = {}
                end
                table.insert(self.ListingsByPlayer[listing.sellerId], listingId)
            end
        end
        
        print("[MarketSystem] Loaded", table.getn(self.ActiveListings), "active listings")
    end
    
    -- Load recent sales
    success, data = pcall(function()
        return self.MarketDataStore:GetAsync("RecentSales")
    end)
    
    if success and data then
        self.RecentSales = data
    end
    
    -- Load price history
    success, data = pcall(function()
        return self.PriceDataStore:GetAsync("PriceHistory")
    end)
    
    if success and data then
        self.PriceHistory = data
    end
end

-- ==========================================================
-- REPLACE THE OLD SaveListing FUNCTION WITH THIS
-- ==========================================================
function MarketSystem:SaveListing(listing)
    spawn(function()
        local success, err = pcall(function()
            self.MarketDataStore:UpdateAsync("ActiveListings", function(oldData)
                local allListings = oldData or {}
                allListings[listing.id] = listing
                return allListings
            end)
        end)
        if not success then
            warn("[MarketSystem] Failed to save listing " .. listing.id .. ": " .. err)
        end
    end)
end

-- ==========================================================
-- REPLACE THE OLD RemoveListing FUNCTION WITH THIS
-- ==========================================================
function MarketSystem:RemoveListing(listingId)
    spawn(function()
        local success, err = pcall(function()
            self.MarketDataStore:UpdateAsync("ActiveListings", function(oldData)
                local allListings = oldData or {}
                allListings[listingId] = nil
                return allListings
            end)
        end)
        if not success then
            warn("[MarketSystem] Failed to remove listing " .. listingId .. ": " .. err)
        end
    end)
end

function MarketSystem:SaveMarketData()
    -- Periodic save of all market data
    spawn(function()
        -- Save active listings
        pcall(function()
            self.MarketDataStore:SetAsync("ActiveListings", self.ActiveListings)
        end)
        
        -- Save recent sales
        pcall(function()
            self.MarketDataStore:SetAsync("RecentSales", self.RecentSales)
        end)
        
        -- Save price history
        pcall(function()
            self.PriceDataStore:SetAsync("PriceHistory", self.PriceHistory)
        end)
    end)
end

-- ========================================
-- PLAYER EVENTS
-- ========================================

function MarketSystem:OnPlayerLeaving(player)
    -- Save any pending data
    if self.ListingsByPlayer[player.UserId] then
        self:SaveMarketData()
    end
end

return MarketSystem