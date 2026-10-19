local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local RunService = game:GetService("RunService")

local Config = require(script.Parent.CombatConfig)
local Budget = require(script.Parent.CombatMovementBudget)
local Guard = {}
local tracked = setmetatable({}, { __mode = "k" })
local bindings = setmetatable({}, { __mode = "k" })

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function rootOf(character)
    if not character then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    return root and root:IsA("BasePart") and root or nil
end

local function seed(character, root)
    local entry = tracked[character]
    if not entry or not root or root.Parent ~= character then
        return
    end
    local valid, budget = pcall(Budget.New, root.Position, os.clock())
    if not valid then
        return
    end
    entry.Budget = budget
    entry.CFrame = root.CFrame
    entry.BlockedUntil = 0
    entry.Teleport = nil
end

function Guard.Track(character)
    if not character or tracked[character] then
        return
    end
    tracked[character] = { Budget = nil, CFrame = nil, BlockedUntil = 0, Teleport = nil, RecoveryToken = 0 }
    bindings[character] = {
        character.Destroying:Connect(function()
            Guard.Forget(character)
        end),
        character.ChildAdded:Connect(function(child)
            if child.Name == "HumanoidRootPart" and child:IsA("BasePart") then
                seed(character, child)
            end
        end),
    }
    seed(character, rootOf(character))
end

function Guard.Forget(character)
    tracked[character] = nil
    local connections = bindings[character]
    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        bindings[character] = nil
    end
end

function Guard.AuthorizeTeleport(character, destination, radius, duration)
    local entry = tracked[character]
    if not entry or not entry.Budget or typeof(destination) ~= "Vector3" or not finite(destination.X) or not finite(destination.Y) or not finite(destination.Z) or not finite(radius) or radius < 0 or radius > Config.Movement.MaxTeleportRadius or not finite(duration) or duration <= 0 or duration > 2 then
        return false
    end
    entry.Teleport = { Position = destination, Radius = radius, Expires = os.clock() + duration }
    return true
end

function Guard.AuthorizeImpulse(character, distance, duration, direction)
    local entry = tracked[character]
    return entry ~= nil and entry.Budget ~= nil and Budget.GrantImpulse(entry.Budget, distance, duration, os.clock(), direction) or false
end

local function correct(character, root, entry, now)
    entry.BlockedUntil = math.max(entry.BlockedUntil, now + Config.Movement.Quarantine)
    entry.RecoveryToken += 1
    local token = entry.RecoveryToken
    if not entry.CFrame then
        return
    end
    if not root.Anchored then
        pcall(function()
            root:SetNetworkOwner(nil)
        end)
    end
    local succeeded = pcall(function()
        root.CFrame = entry.CFrame
        root.AssemblyLinearVelocity = Vector3.zero
        root.AssemblyAngularVelocity = Vector3.zero
    end)
    if succeeded and not root.Anchored then
        task.delay(Config.Movement.NetworkRecovery, function()
            if tracked[character] == entry and entry.RecoveryToken == token and root.Parent == character then
                pcall(function()
                    root:SetNetworkOwnershipAuto()
                end)
            end
        end)
    end
end

local function inspect(character, now)
    local entry = tracked[character]
    local root = rootOf(character)
    if not entry or not entry.Budget or not root then
        return false
    end
    local pending = entry.Teleport
    if pending then
        if now > pending.Expires then
            entry.Teleport = nil
        elseif (root.Position - pending.Position).Magnitude <= pending.Radius then
            entry.Teleport = nil
            entry.Budget = Budget.New(root.Position, now)
            entry.CFrame = root.CFrame
            entry.BlockedUntil = 0
            return true
        end
    end
    local valid = Budget.Sample(entry.Budget, root.Position, now)
    if not valid then
        correct(character, root, entry, now)
        return false
    end
    entry.CFrame = root.CFrame
    return now >= entry.BlockedUntil
end

function Guard.Validate(character, now)
    return inspect(character, now or os.clock())
end

function Guard.GetAcceptedPosition(character)
    local entry = tracked[character]
    return entry and entry.Budget and entry.Budget.Accepted or nil
end

function Guard.IsImpulseAuthorized(character, now)
    local entry = tracked[character]
    local impulse = entry and entry.Budget and entry.Budget.Impulse
    return impulse ~= nil and impulse.Remaining > 0 and (now or os.clock()) < impulse.Expires
end

function Guard.Reset(character)
    local entry = tracked[character]
    if entry then
        entry.BlockedUntil = math.max(entry.BlockedUntil, os.clock() + Config.Movement.Quarantine)
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

for _, model in ipairs(CollectionService:GetTagged(Config.NPCTag)) do
    if model:IsA("Model") then
        Guard.Track(model)
    end
end
CollectionService:GetInstanceAddedSignal(Config.NPCTag):Connect(function(model)
    if model:IsA("Model") then
        Guard.Track(model)
    end
end)
CollectionService:GetInstanceRemovedSignal(Config.NPCTag):Connect(Guard.Forget)

RunService.Heartbeat:Connect(function()
    local now = os.clock()
    for character in pairs(tracked) do
        inspect(character, now)
    end
end)

return Guard
