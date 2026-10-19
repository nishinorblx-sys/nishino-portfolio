local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.CombatConfig)
local Policy = require(script.Parent.CombatPolicy)
local NPCTargetSelector = {}
local cache = setmetatable({}, { __mode = "k" })
local REFRESH = 0.35
local MAX_RANGE = 120

local function living(character)
    if not character or not character.Parent then
        return nil
    end
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    local root = character:FindFirstChild("HumanoidRootPart")
    if not humanoid or humanoid.Health <= 0 or not root or not root:IsA("BasePart") then
        return nil
    end
    return root
end

local function visible(npc, origin, target, root)
    local offset = root.Position - origin.Position
    local params = RaycastParams.new()
    params.FilterType = Enum.RaycastFilterType.Exclude
    params.FilterDescendantsInstances = { npc }
    params.IgnoreWater = true
    local hit = Workspace:Raycast(origin.Position, offset, params)
    return hit == nil or hit.Instance:IsDescendantOf(target)
end

local function valid(npc, npcRoot, player, limit)
    if not player or not player.Parent or not player.Character then
        return nil
    end
    local character = player.Character
    local root = living(character)
    if not root then
        return nil
    end
    local delta = root.Position - npcRoot.Position
    local distance = delta:Dot(delta)
    if distance > limit or not Policy.Authorize(npc, character, npcRoot, root) or not visible(npc, npcRoot, character, root) then
        return nil
    end
    return distance
end

function NPCTargetSelector.GetNearest(npc, maxRange)
    if typeof(npc) ~= "Instance" or not npc:IsA("Model") or not CollectionService:HasTag(npc, Config.NPCTag) then
        return nil
    end
    local root = living(npc)
    if not root then
        return nil
    end
    local radius = MAX_RANGE
    if type(maxRange) == "number" and maxRange == maxRange and math.abs(maxRange) < math.huge then
        radius = math.clamp(maxRange, 1, MAX_RANGE)
    end
    local limit = radius * radius
    local now = os.clock()
    local stored = cache[npc]
    if stored and stored.Radius == radius and now < stored.Expires then
        if stored.Player and valid(npc, root, stored.Player, limit) then
            return stored.Player
        end
        if not stored.Player then
            return nil
        end
    end
    local selected = nil
    local best = limit
    for _, player in ipairs(Players:GetPlayers()) do
        local distance = valid(npc, root, player, limit)
        if distance and (distance < best or (distance == best and (not selected or player.UserId < selected.UserId))) then
            selected = player
            best = distance
        end
    end
    cache[npc] = { Player = selected, Expires = now + REFRESH, Radius = radius }
    return selected
end

function NPCTargetSelector.Forget(npc)
    cache[npc] = nil
end

return NPCTargetSelector
