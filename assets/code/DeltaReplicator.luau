local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local Replicator = {}
local INTERVAL = 0.1
local MAX_KEY_LENGTH = 64
local validators = table.freeze({
    Health = function(value) return type(value) == "number" and value == value and value >= 0 and value < math.huge end,
    Stamina = function(value) return type(value) == "number" and value == value and value >= 0 and value <= 10000 end,
    Level = function(value) return type(value) == "number" and value % 1 == 0 and value >= 1 and value <= 10000 end,
    Stance = function(value) return type(value) == "string" and #value > 0 and #value <= MAX_KEY_LENGTH end,
})
local records = {}
local elapsed = 0

local function remote(name, class)
    local found = ReplicatedStorage:FindFirstChild(name)
    if not found then
        found = Instance.new(class)
        found.Name = name
        found.Parent = ReplicatedStorage
    end
    assert(found:IsA(class), "Incorrect network instance")
    return found
end

local delta = remote("FoallowStateDelta", "RemoteEvent")
local snapshotRemote = remote("FoallowStateSnapshot", "RemoteFunction")
local lastResync = {}

function Replicator.Track(player, initial)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or records[player] or type(initial) ~= "table" then
        return false
    end
    local state = {}
    for key, value in pairs(initial) do
        if not validators[key] or not validators[key](value) then
            return false
        end
        state[key] = value
    end
    records[player] = { State = state, Dirty = table.clone(state), Version = 0 }
    return true
end

function Replicator.Set(player, key, value)
    local entry = records[player]
    if not entry or not validators[key] or not validators[key](value) or entry.State[key] == value then
        return false
    end
    entry.State[key] = value
    entry.Dirty[key] = value
    return true
end

function Replicator.Snapshot(player)
    local entry = records[player]
    if not entry then
        return nil
    end
    return table.freeze({ Version = entry.Version, Fields = table.freeze(table.clone(entry.State)) })
end

function Replicator.Sync(player)
    local snapshot = Replicator.Snapshot(player)
    if not snapshot then
        return false
    end
    return pcall(delta.FireClient, delta, player, "Snapshot", snapshot.Version, snapshot.Fields)
end

function Replicator.Untrack(player)
    records[player] = nil
    lastResync[player] = nil
end

Players.PlayerRemoving:Connect(Replicator.Untrack)

snapshotRemote.OnServerInvoke = function(player)
    local now = os.clock()
    if now - (lastResync[player] or -math.huge) < 0.4 then
        return nil
    end
    lastResync[player] = now
    local snapshot = Replicator.Snapshot(player)
    return snapshot and { Version = snapshot.Version, Fields = snapshot.Fields } or nil
end

RunService.Heartbeat:Connect(function(deltaTime)
    elapsed += deltaTime
    if elapsed < INTERVAL then
        return
    end
    elapsed %= INTERVAL
    for player, entry in pairs(records) do
        if next(entry.Dirty) then
            local nextVersion = entry.Version + 1
            local changes = table.clone(entry.Dirty)
            local successful, err = pcall(delta.FireClient, delta, player, "Delta", nextVersion, changes)
            if successful then
                entry.Version = nextVersion
                for key, value in pairs(changes) do
                    if entry.Dirty[key] == value then
                        entry.Dirty[key] = nil
                    end
                end
            else
                warn("State replication delivery failed:", err)
            end
        end
    end
end)

return Replicator
