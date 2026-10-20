local Sweep = require(script.Parent.CombatSweepPlanner)

local origin = CFrame.new(0, 0, 0)
local translation = CFrame.new(3, 0, 0)
local rotation = CFrame.Angles(0, math.rad(70), 0)

assert(Sweep.Plan(origin, origin, 1.8, 9, math.rad(20), 4) == 1)
assert(Sweep.Plan(origin, translation, 1.8, 9, math.rad(20), 4) == 2)
assert(Sweep.Plan(origin, rotation, 1.8, 9, math.rad(20), 4) == 4)
assert(Sweep.Plan(origin, CFrame.new(12, 0, 0), 1.8, 9, math.rad(20), 4) == nil)
assert(Sweep.Plan(origin, CFrame.Angles(0, math.rad(110), 0), 1.8, 9, math.rad(20), 4) == nil)
assert(Sweep.Plan(origin, translation, 0, 9, math.rad(20), 4) == nil)

print("CombatSweepPlannerTests passed")
