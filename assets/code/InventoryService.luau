local Players = game:GetService("Players")

local InventoryService = {}
local rules = table.freeze({
    Potion = table.freeze({ MaxStack = 30 }),
    Crystal = table.freeze({ MaxStack = 99 }),
    Sword = table.freeze({ MaxStack = 1 }),
})
local MAX_SLOTS = 24
local MAX_OPERATIONS = 16
local MAX_AMOUNT = 99
local MAX_REPLAYS = 48
local inventories = {}

local function validInteger(value, min, max)
    return type(value) == "number" and value == value and value % 1 == 0 and value >= min and value <= max
end

local function verifyOperations(operations)
    if type(operations) ~= "table" or not validInteger(#operations, 1, MAX_OPERATIONS) then
        return false
    end
    for _, operation in ipairs(operations) do
        if type(operation) ~= "table" or not rules[operation.Id] or not validInteger(operation.Amount, -MAX_AMOUNT, MAX_AMOUNT) or operation.Amount == 0 then
            return false
        end
    end
    return true
end

function InventoryService.Open(player, initial)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or inventories[player] then
        return false
    end
    local entries = {}
    local slots = 0
    if initial ~= nil then
        if type(initial) ~= "table" then
            return false
        end
        for id, count in pairs(initial) do
            if not rules[id] or not validInteger(count, 1, rules[id].MaxStack) then
                return false
            end
            entries[id] = count
            slots += 1
        end
    end
    if slots > MAX_SLOTS then
        return false
    end
    inventories[player] = { Items = entries, Slots = slots, Version = 0, Replays = {}, ReplayOrder = {} }
    return true
end

function InventoryService.Transact(player, operations, expectedVersion, requestId)
    local profile = inventories[player]
    if not profile or not verifyOperations(operations) then
        return false, "Invalid transaction"
    end
    local fingerprintParts = {}
    for _, item in ipairs(operations) do
        fingerprintParts[#fingerprintParts + 1] = item.Id .. ":" .. tostring(item.Amount)
    end
    local fingerprint = table.concat(fingerprintParts, "|")
    if requestId ~= nil then
        if type(requestId) ~= "string" or #requestId < 1 or #requestId > 64 then
            return false, "Invalid request ID"
        end
        local previous = profile.Replays[requestId]
        if previous then
            if previous.Fingerprint ~= fingerprint then
                return false, "Request ID reused"
            end
            return true, previous.Version
        end
    end
    if expectedVersion ~= nil and expectedVersion ~= profile.Version then
        return false, "Version mismatch"
    end
    local candidate = table.clone(profile.Items)
    for _, operation in ipairs(operations) do
        local current = candidate[operation.Id] or 0
        local nextValue = current + operation.Amount
        if nextValue < 0 or nextValue > rules[operation.Id].MaxStack then
            return false, "Item limit"
        end
        candidate[operation.Id] = nextValue == 0 and nil or nextValue
    end
    local slots = 0
    for _ in pairs(candidate) do
        slots += 1
    end
    if slots > MAX_SLOTS then
        return false, "Inventory full"
    end
    profile.Items = candidate
    profile.Slots = slots
    profile.Version += 1
    if requestId then
        profile.Replays[requestId] = { Version = profile.Version, Fingerprint = fingerprint }
        local order = profile.ReplayOrder
        order[#order + 1] = requestId
        if #order > MAX_REPLAYS then
            profile.Replays[table.remove(order, 1)] = nil
        end
    end
    return true, profile.Version
end

function InventoryService.Add(player, id, amount)
    return InventoryService.Transact(player, { { Id = id, Amount = amount } })
end

function InventoryService.Remove(player, id, amount)
    if not validInteger(amount, 1, MAX_AMOUNT) then
        return false, "Invalid amount"
    end
    return InventoryService.Transact(player, { { Id = id, Amount = -amount } })
end

function InventoryService.GetCount(player, id)
    local profile = inventories[player]
    return profile and profile.Items[id] or 0
end

function InventoryService.Snapshot(player)
    local profile = inventories[player]
    if not profile then
        return nil
    end
    return table.freeze({ Version = profile.Version, Slots = profile.Slots, Items = table.freeze(table.clone(profile.Items)) })
end

function InventoryService.Close(player)
    inventories[player] = nil
end

Players.PlayerRemoving:Connect(InventoryService.Close)

return InventoryService
