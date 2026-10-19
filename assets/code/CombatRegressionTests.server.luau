local CollectionService = game:GetService("CollectionService")
local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Movement = require(script.Parent.CombatMovementGuard)
local Policy = require(script.Parent.CombatPolicy)
local Resolver = require(script.Parent.CombatResolver)

local function dummy(name, position, lookAt)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Anchored = true
    root.CanCollide = false
    root.Size = Vector3.new(2, 2, 1)
    root.CFrame = CFrame.lookAt(position, lookAt)
    root.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 1000
    humanoid.Health = 1000
    humanoid.RequiresNeck = false
    humanoid.Parent = model
    model.Parent = workspace
    CollectionService:AddTag(model, Config.NPCTag)
    Movement.Track(model)
    return model, root, humanoid
end

local attacker, ar = dummy("RegressionAttacker", Vector3.new(0, 12, 0), Vector3.new(0, 12, -3))
local defender, dr, humanoid = dummy("RegressionDefender", Vector3.new(0, 12, -3), Vector3.new(0, 12, 0))
local now = os.clock()
assert(Movement.Validate(attacker, now))
local baseline = Movement.GetAcceptedPosition(attacker)
ar.Position = Vector3.new(150, 12, 0)
local safe = Instance.new("Part")
safe.Name = "UntrustedPositionSafeZone"
safe.Anchored = true
safe.Transparency = 1
safe.CanCollide = false
safe.Size = Vector3.new(10, 15, 10)
safe.Position = ar.Position
safe:SetAttribute("ZoneType", "Safe")
safe.Parent = workspace
CollectionService:AddTag(safe, Config.ZoneTag)
assert(Policy.Authorize(attacker, defender, ar, dr))
assert(not Movement.Validate(attacker, now + 0.04))
assert(Movement.GetAcceptedPosition(attacker) == baseline)
assert((ar.Position - baseline).Magnitude < 0.01)
assert(not Movement.Validate(attacker, now + 0.05))
safe:Destroy()
assert(Movement.AuthorizeTeleport(attacker, Vector3.new(150, 12, 0), 2, 0.5))
ar.Position = Vector3.new(150, 12, 0)
assert(Movement.Validate(attacker, os.clock()))
assert(Movement.GetAcceptedPosition(attacker) == ar.Position)
assert(Movement.AuthorizeTeleport(attacker, baseline, 2, 0.5))
ar.Position = baseline
assert(Movement.Validate(attacker, os.clock()))

assert(State.BeginAbility(attacker, math.huge, 10, now) == nil)
assert(State.BeginAbility(attacker, 0.9, 0 / 0, now) == nil)
assert(not State.RefundEssence(attacker, math.huge))
assert(not State.RefundEssence(attacker, 0 / 0))
attacker:SetAttribute("Stunned", true)
assert(not State.BeginGuard(attacker, now))
assert(not State.BeginParry(attacker, now))
attacker:SetAttribute("Stunned", nil)

assert(Policy.Authorize(attacker, defender, ar, dr))
local definition = { Damage = 20, PostureDamage = 35 }
local healthBefore = humanoid.Health
local result, dealt = Resolver.Apply(attacker, defender, ar, dr, humanoid, definition, now)
assert(result == "Hit" and dealt > 0 and humanoid.Health < healthBefore)

assert(State.BeginGuard(defender, now + 0.1))
result = Resolver.Apply(attacker, defender, ar, dr, humanoid, definition, now + 0.11)
assert(result == "Blocked" and dealt == 0)
State.EndGuard(defender, now + 0.2)
assert(State.BeginParry(defender, now + 0.21))
result = Resolver.Apply(attacker, defender, ar, dr, humanoid, definition, now + 0.22)
assert(result == "Parried")
assert(State.Defense(defender, now + 0.23).Guarding == false)

assert(State.BeginGuard(defender, now + 0.3))
defender:SetAttribute("CombatDamageTakenMultiplier", 0)
healthBefore = humanoid.Health
result, dealt = Resolver.Apply(attacker, defender, ar, dr, humanoid, { Damage = 20, PostureDamage = 500 }, now + 0.31)
assert(result == "GuardBroken" and dealt == 0 and humanoid.Health == healthBefore)
assert(State.Defense(defender, now + 0.31).Guarding == false)

State.Cleanup(attacker)
State.Cleanup(defender)
Movement.Forget(attacker)
Movement.Forget(defender)
attacker:Destroy()
defender:Destroy()
print("CombatRegressionTests passed")
