local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)
local Policy = {}
local severity = table.freeze({ Safe = 4, Yellow = 1, Red = 2, Dark = 3 })
local volumes = {}
local consequenceHandler = nil

local function register(part)
    if part:IsA("BasePart") then
        volumes[part] = true
    end
end

for _, part in ipairs(CollectionService:GetTagged(Config.ZoneTag)) do
    register(part)
end
CollectionService:GetInstanceAddedSignal(Config.ZoneTag):Connect(register)
CollectionService:GetInstanceRemovedSignal(Config.ZoneTag):Connect(function(part)
    volumes[part] = nil
end)

function Policy.SetConsequenceHandler(callback)
    assert(type(callback) == "function")
    consequenceHandler = callback
end

function Policy.ZoneAt(position)
    local chosen = nil
    local highest = 0
    for part in pairs(volumes) do
        if part.Parent then
            local zone = part:GetAttribute("ZoneType")
            local priority = severity[zone]
            if priority and priority > highest then
                local localPosition = part.CFrame:PointToObjectSpace(position)
                local half = part.Size * 0.5
                if math.abs(localPosition.X) <= half.X and math.abs(localPosition.Y) <= half.Y and math.abs(localPosition.Z) <= half.Z then
                    chosen = zone
                    highest = priority
                end
            end
        end
    end
    return chosen
end

function Policy.Authorize(attacker, defender, attackerRoot, defenderRoot)
    if attacker == defender or not attacker.Parent or not defender.Parent then
        return false, nil
    end
    local af = attacker:GetAttribute("CombatFaction")
    local df = defender:GetAttribute("CombatFaction")
    if af ~= nil and af == df then
        return false, nil
    end
    local ap = Players:GetPlayerFromCharacter(attacker)
    local dp = Players:GetPlayerFromCharacter(defender)
    if not ap and not CollectionService:HasTag(attacker, Config.NPCTag) then
        return false, nil
    end
    if not dp and not CollectionService:HasTag(defender, Config.NPCTag) then
        return false, nil
    end
    local attackerZone = Policy.ZoneAt(attackerRoot.Position)
    local defenderZone = Policy.ZoneAt(defenderRoot.Position)
    if attackerZone == "Safe" or defenderZone == "Safe" then
        return false, nil
    end
    if ap and dp then
        if not attackerZone or not defenderZone or consequenceHandler == nil then
            return false, nil
        end
        if ap.Team ~= nil and ap.Team == dp.Team then
            return false, nil
        end
        if (attackerZone == "Yellow" or defenderZone == "Yellow") and (ap:GetAttribute("PvPEnabled") ~= true or dp:GetAttribute("PvPEnabled") ~= true) then
            return false, nil
        end
        local chosen = severity[attackerZone] >= severity[defenderZone] and attackerZone or defenderZone
        return true, { Attacker = ap, Target = dp, Zone = chosen }
    end
    return true, nil
end

function Policy.RecordConsequence(info)
    if not info then
        return true
    end
    if consequenceHandler == nil then
        return false
    end
    local succeeded, result = pcall(consequenceHandler, info)
    if not succeeded then
        warn("Combat PvP consequence transaction failed:", result)
        return false
    end
    return result == true
end

return Policy
