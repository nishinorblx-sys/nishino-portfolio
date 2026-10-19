local Players = game:GetService("Players")

local NPCTargetSelector = {}

local REFRESH_SECONDS = 0.45
local MAX_RANGE = 100
local cache = setmetatable({}, { __mode = "k" })

local function resolveTarget(player)
    local character = player.Character
    if not character then
        return nil, nil
    end

    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return nil, nil
    end

    return humanoid, root
end

function NPCTargetSelector.GetNearest(npcModel, maxDistance)
    if typeof(npcModel) ~= "Instance" or not npcModel:IsA("Model") then
        return nil
    end

    local npcRoot = npcModel:FindFirstChild("HumanoidRootPart")
    if not npcRoot or not npcRoot:IsA("BasePart") then
        return nil
    end

    local radius = MAX_RANGE
    if type(maxDistance) == "number" and maxDistance == maxDistance then
        radius = math.clamp(maxDistance, 1, MAX_RANGE)
    end

    local now = os.clock()
    local stored = cache[npcModel]
    if stored and now < stored.NextRefresh and stored.Radius == radius then
        local player = stored.Player
        if not player then
            return nil
        end

        local humanoid, root = resolveTarget(player)
        if humanoid and root and (root.Position - npcRoot.Position).Magnitude <= radius then
            return player
        end
    end

    local nearestPlayer = nil
    local nearestDistanceSquared = radius * radius
    local origin = npcRoot.Position

    for _, player in ipairs(Players:GetPlayers()) do
        local humanoid, root = resolveTarget(player)
        if humanoid and root then
            local offset = root.Position - origin
            local distanceSquared = offset:Dot(offset)
            if distanceSquared < nearestDistanceSquared then
                nearestDistanceSquared = distanceSquared
                nearestPlayer = player
            end
        end
    end

    cache[npcModel] = {
        Player = nearestPlayer,
        Radius = radius,
        NextRefresh = now + REFRESH_SECONDS,
    }

    return nearestPlayer
end

function NPCTargetSelector.Forget(npcModel)
    cache[npcModel] = nil
end

return NPCTargetSelector
