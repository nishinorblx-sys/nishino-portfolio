local Sweep = {}

local function finite(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

function Sweep.Plan(previous, current, sweepDistance, maxDistance, maxAngle, maxSteps)
    if typeof(previous) ~= "CFrame" or typeof(current) ~= "CFrame" then
        return nil
    end
    if not finite(sweepDistance) or sweepDistance <= 0 or not finite(maxDistance) or maxDistance <= 0 or not finite(maxAngle) or maxAngle <= 0 or not finite(maxSteps) or maxSteps < 1 or maxSteps % 1 ~= 0 then
        return nil
    end
    local distance = (current.Position - previous.Position).Magnitude
    local angle = math.acos(math.clamp(previous.LookVector:Dot(current.LookVector), -1, 1))
    if distance > maxDistance or angle > maxAngle * maxSteps then
        return nil
    end
    local segments = math.max(1, math.ceil(distance / sweepDistance), math.ceil(angle / maxAngle))
    if segments > maxSteps then
        return nil
    end
    return segments
end

return Sweep
