local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local RunService = game:GetService("RunService")

local DeltaReplicator = {}

local REMOTE_NAME = "FoallowStateDelta"
local SEND_INTERVAL = 0.1
local ALLOWED_KEYS = table.freeze({ Health = true, Stamina = true, Level = true, Stance = true })

local remote = ReplicatedStorage:FindFirstChild(REMOTE_NAME)
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = REMOTE_NAME
    remote.Parent = ReplicatedStorage
end
assert(remote:IsA("RemoteEvent"), "State remote must be a RemoteEvent")

local records = {}
local elapsed = 0

local function validValue(value)
    local kind = type(value)
    if kind == "number" then
        return value == value and value > -math.huge and value < math.huge
    end
    if kind == "string" then
        return #value <= 64
    end
    return kind == "boolean"
end

function DeltaReplicator.Track(player, initial)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or records[player] then
        return false
    end

    if type(initial) ~= "table" then
        return false
    end

    local state = {}
    for key, value in pairs(initial) do
        if not ALLOWED_KEYS[key] or not validValue(value) then
            return false
        end
        state[key] = value
    end

    records[player] = { State = state, Dirty = table.clone(state) }
    return true
end

function DeltaReplicator.Set(player, key, value)
    local record = records[player]
    if not record or not ALLOWED_KEYS[key] or not validValue(value) then
        return false
    end

    if record.State[key] == value then
        return false
    end

    record.State[key] = value
    record.Dirty[key] = value
    return true
end

function DeltaReplicator.Snapshot(player)
    local record = records[player]
    if not record then
        return nil
    end

    return table.freeze(table.clone(record.State))
end

function DeltaReplicator.Sync(player)
    local record = records[player]
    if not record then
        return false
    end

    remote:FireClient(player, table.clone(record.State))
    return true
end

function DeltaReplicator.Untrack(player)
    records[player] = nil
end

Players.PlayerRemoving:Connect(DeltaReplicator.Untrack)

RunService.Heartbeat:Connect(function(deltaTime)
    elapsed += deltaTime
    if elapsed < SEND_INTERVAL then
        return
    end
    elapsed %= SEND_INTERVAL

    for player, record in pairs(records) do
        if next(record.Dirty) then
            local changed = record.Dirty
            record.Dirty = {}
            remote:FireClient(player, changed)
        end
    end
end)

return DeltaReplicator
