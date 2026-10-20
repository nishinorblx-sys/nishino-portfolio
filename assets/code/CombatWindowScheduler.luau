local Scheduler = {}

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Scheduler.New(interval, now)
    assert(finite(interval) and interval >= 1 / 120 and interval <= 0.25)
    assert(finite(now))
    return { Interval = interval, Remainder = 0, LastSampleAt = now, Samples = 1 }
end

function Scheduler.Step(state, dt, now, endAt, maxLateness)
    if not finite(dt) or not finite(now) or not finite(endAt) or not finite(maxLateness) then
        return false, true, 0
    end
    if now >= endAt then
        if now - endAt <= maxLateness and now - state.LastSampleAt >= state.Interval * 0.65 then
            state.LastSampleAt = now
            state.Samples += 1
            return true, true, 0
        end
        return false, true, 0
    end
    local elapsed = math.max(0, dt)
    local total = state.Remainder + elapsed
    local due = math.floor(total / state.Interval)
    state.Remainder = total % state.Interval
    if due < 1 then
        return false, false, 0
    end
    state.LastSampleAt = now
    state.Samples += 1
    return true, false, due - 1
end

return Scheduler
