local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(script.Parent.CombatConfig)
local Policy = {}

local ZONES = table.freeze({ Safe = 4, Yellow = 3, Red = 2, Dark = 1 })
local volumes = {}
local consequenceHandler = nil

local function register(instance)
    if instance:IsA("BasePart") then
        volumes[instance] = true
    end
end

for _, part in ipairs(CollectionService:GetTagged(Config.ZoneTag)) do
    register(part)
end
CollectionService:GetInstanceAddedSignal(Config.ZoneTag):Connect(register)
CollectionService:GetInstanceRemovedSignal(Config.ZoneTag):Connect(function(instance)
    volumes[instance] = nil
end)

function Policy.SetConsequenceHandler(callback)
    assert(type(callback) == "function", "PvP consequences must have a server handler")
    consequenceHandler = callback
end

local function zoneAt(position)
    local name
    local priority = 0
    for part in pairs(volumes) do
        if part.Parent then
            local zoneType = part:GetAttribute("ZoneType")
            local order = ZONES[zoneType]
            if order and order > priority then
                local localPosition = part.CFrame:PointToObjectSpace(position)
                local halfSize = part.Size * 0.5
                if math.abs(localPosition.X) <= halfSize.X and math.abs(localPosition.Y) <= halfSize.Y and math.abs(localPosition.Z) <= halfSize.Z then
                    name = zoneType
                    priority = order
                end
            end
        end
    end
    return name
end

function Policy.Authorize(attacker, target, attackerRoot, targetRoot)
    if attacker == target then
        return false, nil
    end
    local attackerFaction = attacker:GetAttribute("CombatFaction")
    local targetFaction = target:GetAttribute("CombatFaction")
    if attackerFaction ~= nil and attackerFaction == targetFaction then
        return false, nil
    end
    local attackerPlayer = Players:GetPlayerFromCharacter(attacker)
    local targetPlayer = Players:GetPlayerFromCharacter(target)
    if not targetPlayer then
        return CollectionService:HasTag(target, Config.NPCTag), nil
    end
    if not attackerPlayer or not consequenceHandler then
        return false, nil
    end
    if attackerPlayer.Team ~= nil and attackerPlayer.Team == targetPlayer.Team then
        return false, nil
    end
    local attackerZone = zoneAt(attackerRoot.Position)
    local targetZone = zoneAt(targetRoot.Position)
    if not attackerZone or not targetZone or attackerZone == "Safe" or targetZone == "Safe" then
        return false, nil
    end
    if (attackerZone == "Yellow" or targetZone == "Yellow") and (attackerPlayer:GetAttribute("PvPEnabled") ~= true or targetPlayer:GetAttribute("PvPEnabled") ~= true) then
        return false, nil
    end
    local zone = ZONES[attackerZone] > ZONES[targetZone] and attackerZone or targetZone
    return true, table.freeze({ Attacker = attackerPlayer, Target = targetPlayer, Zone = zone })
end

function Policy.RecordConsequence(info, damage, result)
    if not info then
        return
    end
    local ok, response = pcall(consequenceHandler, info, damage, result)
    if not ok then
        warn("Combat PvP consequence handler failed:", response)
    end
end

return Policy
