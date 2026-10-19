local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Guard = {}
local tracked = setmetatable({}, { __mode = "k" })
local bindings = setmetatable({}, { __mode = "k" })
local SPEED = 72
local SLACK = 5
local QUARANTINE = 1.25

local function validNumber(value)
    return type(value) == "number" and value == value and math.abs(value) < math.huge
end

local function rootOf(character)
    local root = character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

function Guard.Track(character)
    if not character or tracked[character] then
        return
    end
    local entry = { Accepted = nil, At = 0, BlockedUntil = 0, Teleport = nil, Impulse = nil }
    tracked[character] = entry
    local function seed(root)
        if tracked[character] ~= entry or not root:IsA("BasePart") or root.Name ~= "HumanoidRootPart" then
            return
        end
        entry.Accepted = root.Position
        entry.At = os.clock()
    end
    bindings[character] = {
        character.Destroying:Connect(function()
            Guard.Forget(character)
        end),
        character.ChildAdded:Connect(seed),
    }
    local root = rootOf(character)
    if root then
        seed(root)
    end
end

function Guard.Forget(character)
    tracked[character] = nil
    if bindings[character] then
        for _, connection in ipairs(bindings[character]) do
            connection:Disconnect()
        end
        bindings[character] = nil
    end
end

function Guard.AuthorizeTeleport(character, destination, radius, duration)
    local entry = tracked[character]
    if not entry or typeof(destination) ~= "Vector3" or not validNumber(destination.X) or not validNumber(destination.Y) or not validNumber(destination.Z) or not validNumber(radius) or not validNumber(duration) or radius < 0 or radius > 32 or duration <= 0 or duration > 2 then
        return false
    end
    entry.Teleport = { Destination = destination, Radius = radius, Until = os.clock() + duration }
    return true
end

function Guard.AuthorizeImpulse(character, extraDistance, duration)
    local entry = tracked[character]
    if not entry or not validNumber(extraDistance) or extraDistance < 0 or extraDistance > 120 or not validNumber(duration) or duration <= 0 or duration > 2 then
        return false
    end
    entry.Impulse = { Extra = extraDistance, Until = os.clock() + duration }
    return true
end

local function inspect(character, now)
    local entry = tracked[character]
    if not entry then
        return false
    end
    local root = rootOf(character)
    if not root then
        return false
    end
    local position = root.Position
    if entry.Accepted == nil then
        return false
    end
    if entry.Teleport and now <= entry.Teleport.Until then
        if (position - entry.Teleport.Destination).Magnitude <= entry.Teleport.Radius then
            entry.Accepted = position
            entry.At = now
            entry.BlockedUntil = 0
            entry.Teleport = nil
            return true
        end
    elseif entry.Teleport then
        entry.Teleport = nil
    end
    local elapsed = math.clamp(now - entry.At, 1 / 240, 0.25)
    local maximum = SLACK + SPEED * elapsed
    if entry.Impulse then
        if now <= entry.Impulse.Until then
            maximum += entry.Impulse.Extra
        else
            entry.Impulse = nil
        end
    end
    if (position - entry.Accepted).Magnitude > maximum then
        entry.BlockedUntil = math.max(entry.BlockedUntil, now + QUARANTINE)
        return false
    end
    entry.Accepted = position
    entry.At = now
    return now >= entry.BlockedUntil
end

function Guard.GetAcceptedPosition(character)
    local entry = tracked[character]
    return entry and entry.Accepted or nil
end

function Guard.Validate(character, now)
    local entry = tracked[character]
    if not entry then
        return false
    end
    return inspect(character, now or os.clock())
end

function Guard.IsImpulseAuthorized(character, now)
    local entry = tracked[character]
    return entry ~= nil and entry.Impulse ~= nil and (now or os.clock()) <= entry.Impulse.Until
end

function Guard.Reset(character)
    local entry = tracked[character]
    if entry then
        entry.BlockedUntil = os.clock() + QUARANTINE
    end
end

local function hookPlayer(player)
    player.CharacterAdded:Connect(Guard.Track)
    player.CharacterRemoving:Connect(Guard.Forget)
    if player.Character then
        Guard.Track(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    hookPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)

for _, model in ipairs(CollectionService:GetTagged("CombatNPC")) do
    if model:IsA("Model") then
        Guard.Track(model)
    end
end
CollectionService:GetInstanceAddedSignal("CombatNPC"):Connect(function(model)
    if model:IsA("Model") then
        Guard.Track(model)
    end
end)
CollectionService:GetInstanceRemovedSignal("CombatNPC"):Connect(Guard.Forget)

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for character in pairs(tracked) do
        inspect(character, now)
    end
end)

return Guard
