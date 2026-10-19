local Players = game:GetService("Players")

local InventoryService = {}

local ITEM_RULES = table.freeze({
    Potion = table.freeze({ MaxStack = 30 }),
    Crystal = table.freeze({ MaxStack = 99 }),
    Sword = table.freeze({ MaxStack = 1 }),
})

local MAX_SLOTS = 24
local MAX_TRANSACTION = 99
local inventories = {}

local function validAmount(amount)
    return type(amount) == "number"
        and amount == amount
        and amount % 1 == 0
        and amount >= 1
        and amount <= MAX_TRANSACTION
end

function InventoryService.Open(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false
    end

    if inventories[player] then
        return false
    end

    inventories[player] = { Items = {}, Slots = 0, Version = 0 }
    return true
end

function InventoryService.Add(player, itemId, amount)
    local profile = inventories[player]
    local rule = type(itemId) == "string" and ITEM_RULES[itemId] or nil
    if not profile or not rule or not validAmount(amount) then
        return false, "Invalid transaction"
    end

    local previous = profile.Items[itemId] or 0
    if previous + amount > rule.MaxStack then
        return false, "Stack limit"
    end

    if previous == 0 and profile.Slots >= MAX_SLOTS then
        return false, "Inventory full"
    end

    profile.Items[itemId] = previous + amount
    if previous == 0 then
        profile.Slots += 1
    end
    profile.Version += 1

    return true, profile.Version
end

function InventoryService.Remove(player, itemId, amount)
    local profile = inventories[player]
    if not profile or type(itemId) ~= "string" or not validAmount(amount) then
        return false, "Invalid transaction"
    end

    local previous = profile.Items[itemId] or 0
    if previous < amount then
        return false, "Insufficient items"
    end

    local remaining = previous - amount
    if remaining == 0 then
        profile.Items[itemId] = nil
        profile.Slots -= 1
    else
        profile.Items[itemId] = remaining
    end
    profile.Version += 1

    return true, profile.Version
end

function InventoryService.GetCount(player, itemId)
    local profile = inventories[player]
    if not profile or type(itemId) ~= "string" then
        return 0
    end
    return profile.Items[itemId] or 0
end

function InventoryService.Snapshot(player)
    local profile = inventories[player]
    if not profile then
        return nil
    end

    return table.freeze({
        Version = profile.Version,
        Slots = profile.Slots,
        Items = table.freeze(table.clone(profile.Items)),
    })
end

function InventoryService.Close(player)
    inventories[player] = nil
end

Players.PlayerRemoving:Connect(InventoryService.Close)

return InventoryService
