local ZoneConsequences = {}
local lengths = table.freeze({ Yellow = 12, Red = 35, Dark = 50 })

function ZoneConsequences.Apply(info, damage, result)
    if result == "Forbidden" or result == "Invalid" then
        return
    end
    local attacker = info.Attacker
    if not attacker or not attacker.Parent then
        return
    end
    local now = workspace:GetServerTimeNow()
    local duration = lengths[info.Zone]
    if not duration then
        return
    end
    local previous = attacker:GetAttribute("PvPFlagUntil")
    if type(previous) ~= "number" or previous ~= previous then
        previous = 0
    end
    local untilTime = math.max(previous, now + duration)
    attacker:SetAttribute("PvPFlagUntil", untilTime)
    attacker:SetAttribute("PvPLastZone", info.Zone)
    attacker:SetAttribute("PvPLastOpponent", info.Target.UserId)
end

return ZoneConsequences
