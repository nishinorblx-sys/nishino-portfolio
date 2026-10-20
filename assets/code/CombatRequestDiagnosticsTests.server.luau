local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
    return
end

local Combat = require(script.Parent.CombatHitboxService)

Combat.Diagnostics(true)

local first = Combat.Request(nil, "Light")
local second = Combat.Request({}, "Heavy")
local third = Combat.RequestNPC(Instance.new("Model"), "Light")

assert(first == false and second == false and third == false)

local result = Combat.Diagnostics(false)
assert(result.Requests == 3)
assert(result.Rejected == 3)
assert(result.Accepted == 0)
assert(result.RejectedContacts == 0)

print("CombatRequestDiagnosticsTests passed")
