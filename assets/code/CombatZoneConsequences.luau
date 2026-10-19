local ZoneConsequences = {}
local lengths = table.freeze({ Yellow = 12, Red = 35, Dark = 50 })

local function mark(player, opponent, zone, untilTime)
    local previous = player:GetAttribute("PvPFlagUntil")
    if type(previous) ~= "number" or previous ~= previous or math.abs(previous) == math.huge then
        previous = 0
    end
    if untilTime > previous then
        player:SetAttribute("PvPFlagUntil", untilTime)
    end
    if player:GetAttribute("PvPLastZone") ~= zone then
        player:SetAttribute("PvPLastZone", zone)
    end
    if player:GetAttribute("PvPLastOpponent") ~= opponent.UserId then
        player:SetAttribute("PvPLastOpponent", opponent.UserId)
    end
end

function ZoneConsequences.Apply(info)
    local attacker = info.Attacker
    local target = info.Target
    local duration = lengths[info.Zone]
    if not duration or not attacker or not target or not attacker.Parent or not target.Parent then
        return false
    end
    local untilTime = workspace:GetServerTimeNow() + duration
    mark(attacker, target, info.Zone, untilTime)
    mark(target, attacker, info.Zone, untilTime)
    return true
end

return ZoneConsequences
