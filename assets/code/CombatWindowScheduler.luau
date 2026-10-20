local Scheduler = {}

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Scheduler.New(interval, now)
    assert(finite(interval) and interval >= 1 / 120 and interval <= 0.25)
    assert(finite(now))
    return {
        Interval = interval,
        Remainder = 0,
        OpenedAt = now,
        LastObservedAt = now,
        LastSampleAt = now,
        Samples = 1,
        Finalized = false,
    }
end

function Scheduler.Step(state, dt, now, endAt, maxLateness)
    if not finite(dt) or dt < 0 or not finite(now) or not finite(endAt) or not finite(maxLateness) or maxLateness < 0 then
        return false, true, 0
    end
    if state.Finalized then
        return false, true, 0
    end
    if now < state.LastObservedAt or endAt < state.OpenedAt then
        state.Finalized = true
        return false, true, 0
    end
    local sampledUntil = math.min(now, endAt)
    local elapsed = math.max(0, sampledUntil - state.LastObservedAt)
    state.LastObservedAt = sampledUntil
    local total = state.Remainder + elapsed
    local dueCount = math.floor((total + 1e-9) / state.Interval)
    state.Remainder = math.max(0, total - dueCount * state.Interval)
    local finished = now >= endAt
    local allowed = not finished or now - endAt <= maxLateness
    local due = dueCount > 0 and allowed
    if finished and allowed and not due then
        due = math.max(0, endAt - state.LastSampleAt) >= state.Interval * 0.65
    end
    local skipped = due and math.max(0, dueCount - 1) or dueCount
    if due then
        state.Samples += 1
        state.LastSampleAt = math.min(now, endAt)
    end
    if finished then
        state.Finalized = true
    end
    return due, finished, skipped
end

return Scheduler
