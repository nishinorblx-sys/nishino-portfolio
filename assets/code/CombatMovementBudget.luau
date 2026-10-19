local Config = require(script.Parent.CombatConfig)

local Budget = {}

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Budget.New(position, now)
    assert(typeof(position) == "Vector3" and finite(position.X) and finite(position.Y) and finite(position.Z) and finite(now))
    return {
        Accepted = position,
        LastAt = now,
        Tolerance = Config.Movement.Tolerance,
        Impulse = nil,
    }
end

function Budget.GrantImpulse(entry, distance, duration, now, direction)
    if not finite(distance) or distance <= 0 or distance > Config.Movement.MaxImpulse or not finite(duration) or duration <= 0 or duration > Config.Movement.MaxImpulseDuration or not finite(now) then
        return false
    end
    if direction ~= nil then
        if typeof(direction) ~= "Vector3" or not finite(direction.X) or not finite(direction.Y) or not finite(direction.Z) or direction.Magnitude < 0.001 then
            return false
        end
        direction = direction.Unit
    end
    if entry.Impulse and entry.Impulse.Expires > now and entry.Impulse.Remaining > 0 then
        return false
    end
    entry.Impulse = { Remaining = distance, Expires = now + duration, Direction = direction }
    return true
end

function Budget.Sample(entry, position, now)
    if typeof(position) ~= "Vector3" or not finite(position.X) or not finite(position.Y) or not finite(position.Z) or not finite(now) then
        return false, "Nonfinite position"
    end
    if now < entry.LastAt then
        return false, "Nonmonotonic timestamp"
    end
    local elapsed = math.min(now - entry.LastAt, Config.Movement.MaxSampleElapsed)
    entry.LastAt = now
    entry.Tolerance = math.min(Config.Movement.Tolerance, entry.Tolerance + Config.Movement.ToleranceRegen * elapsed)
    if entry.Impulse and now >= entry.Impulse.Expires then
        entry.Impulse = nil
    end
    local displacement = position - entry.Accepted
    local delta = displacement.Magnitude
    local normalDistance = Config.Movement.MaxSpeed * elapsed
    local excess = math.max(0, delta - normalDistance)
    local impulse = entry.Impulse and entry.Impulse.Remaining or 0
    if entry.Impulse and entry.Impulse.Direction then
        local aligned = math.max(0, displacement:Dot(entry.Impulse.Direction))
        impulse = math.min(impulse, aligned)
    end
    if excess > entry.Tolerance + impulse + 0.000001 then
        return false, "Movement budget exceeded"
    end
    local usedTolerance = math.min(entry.Tolerance, excess)
    entry.Tolerance -= usedTolerance
    if entry.Impulse then
        entry.Impulse.Remaining = math.max(0, entry.Impulse.Remaining - math.max(0, excess - usedTolerance))
    end
    entry.Accepted = position
    return true
end

return Budget
