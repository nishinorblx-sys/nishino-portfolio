local Timeline = {}

function Timeline.New(attack, startedAt, config)
    local plannedStart = startedAt + attack.Definition.Windup
    return {
        PlannedStart = plannedStart,
        FallbackAt = plannedStart + config.AnimationMarkerGrace,
        EarliestMarker = plannedStart - config.AnimationEarlyTolerance,
        LatestMarker = plannedStart + config.AnimationLateTolerance,
        Deadline = startedAt + config.MaxAttackLifetime,
        Phase = "Pending",
        StartAt = nil,
        EndAt = nil,
    }
end

function Timeline.TryOpen(timeline, now, activeDuration, useMarker)
    if timeline.Phase ~= "Pending" or now > timeline.Deadline - activeDuration then
        return false
    end
    if useMarker then
        if now < timeline.EarliestMarker or now > timeline.LatestMarker then
            return false
        end
    elseif now < timeline.FallbackAt then
        return false
    end
    timeline.Phase = "Active"
    timeline.StartAt = now
    timeline.EndAt = now + activeDuration
    return true
end

function Timeline.Close(timeline)
    if timeline.Phase == "Done" then
        return false
    end
    timeline.Phase = "Done"
    return true
end

return Timeline
