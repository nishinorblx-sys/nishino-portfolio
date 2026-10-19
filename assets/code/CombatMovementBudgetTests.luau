local Budget = require(script.Parent.CombatMovementBudget)
local Config = require(script.Parent.CombatConfig)

local function near(a, b)
    return math.abs(a - b) < 0.0001
end

local entry = Budget.New(Vector3.zero, 0)
for frame = 1, 600 do
    local time = frame / 60
    assert(Budget.Sample(entry, Vector3.new(72 * time, 0, 0), time))
end
assert(near(entry.Accepted.X, 720))

local rapid = Budget.New(Vector3.zero, 0)
local rejected = false
for frame = 1, 60 do
    local time = frame / 60
    local valid = Budget.Sample(rapid, Vector3.new(350 * time, 0, 0), time)
    if not valid then
        rejected = true
        break
    end
end
assert(rejected)
assert(rapid.Accepted.X < 20)

local teleport = Budget.New(Vector3.zero, 0)
assert(not Budget.Sample(teleport, Vector3.new(140, 0, 0), 0.04))
assert(teleport.Accepted == Vector3.zero)
assert(not Budget.Sample(teleport, Vector3.new(140, 0, 0), 30))

local impulse = Budget.New(Vector3.zero, 0)
assert(Budget.GrantImpulse(impulse, 15, 0.5, 0))
assert(not Budget.GrantImpulse(impulse, 15, 0.5, 0))
assert(Budget.Sample(impulse, Vector3.new(14, 0, 0), 0.01))
local remainder = impulse.Impulse.Remaining
assert(remainder < 15 and remainder > 0)
assert(not Budget.Sample(impulse, Vector3.new(50, 0, 0), 0.02))
assert(impulse.Impulse.Remaining == remainder)
assert(not Budget.Sample(impulse, Vector3.new(50, 0, 0), 0.6))
assert(impulse.Impulse == nil)

local tolerance = Budget.New(Vector3.zero, 0)
assert(Budget.Sample(tolerance, Vector3.new(Config.Movement.Tolerance + 0.5, 0, 0), 0.01))
assert(tolerance.Tolerance < Config.Movement.Tolerance)
assert(not Budget.Sample(tolerance, Vector3.new(9, 0, 0), 0.02))
assert(not Budget.Sample(tolerance, Vector3.new(9, 0, 0), 0.03))

print("CombatMovementBudgetTests passed")
