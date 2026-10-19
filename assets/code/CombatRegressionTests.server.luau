local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Movement = require(script.Parent.CombatMovementGuard)
local Policy = require(script.Parent.CombatPolicy)
local Resolver = require(script.Parent.CombatResolver)
local Timeline = require(script.Parent.CombatTimeline)

local function dummy(name, position, lookAt)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Anchored = true
    root.Size = Vector3.new(2, 2, 1)
    root.CFrame = CFrame.lookAt(position, lookAt)
    root.Parent = model
    local hum = Instance.new("Humanoid")
    hum.MaxHealth = 1000
    hum.Health = 1000
    hum.Parent = model
    model.Parent = workspace
    CollectionService:AddTag(model, Config.NPCTag)
    Movement.Track(model)
    return model, root, hum
end

local attacker, ar = dummy("RegressionAttacker", Vector3.new(0, 5, 0), Vector3.new(0, 5, -3))
local defender, dr, humanoid = dummy("RegressionDefender", Vector3.new(0, 5, -3), Vector3.new(0, 5, 0))
local now = os.clock()
assert(Movement.Validate(attacker, now))
local baseline = Movement.GetAcceptedPosition(attacker)
ar.Position = Vector3.new(150, 5, 0)
assert(not Movement.Validate(attacker, now + 0.04))
assert(Movement.GetAcceptedPosition(attacker) == baseline)
assert(not Movement.Validate(attacker, now + 1.1))
assert(Movement.AuthorizeTeleport(attacker, ar.Position, 2, 0.5))
assert(Movement.Validate(attacker, os.clock()))
assert(Movement.GetAcceptedPosition(attacker) == ar.Position)
ar.Position = baseline
assert(Movement.AuthorizeTeleport(attacker, ar.Position, 2, 0.5))
assert(Movement.Validate(attacker, os.clock()))

assert(State.BeginAbility(attacker, math.huge, 10, now) == nil)
assert(State.BeginAbility(attacker, 0.9, 0 / 0, now) == nil)
assert(State.RefundEssence(attacker, math.huge) == false)
assert(State.RefundEssence(attacker, 0 / 0) == false)
attacker:SetAttribute("Stunned", true)
assert(State.BeginGuard(attacker, now + 1.3) == false)
attacker:SetAttribute("Stunned", nil)

local weapon = Config.Weapons.TrainingSword
local attack = State.BeginAttack(attacker, "Light", weapon, now + 1.4)
assert(attack ~= nil)
local timeline = Timeline.New(attack, now + 1.4, Config)
assert(Timeline.TryOpen(timeline, timeline.FallbackAt, attack.Definition.Active, false))
assert(not Timeline.TryOpen(timeline, timeline.FallbackAt, attack.Definition.Active, false))
assert(State.SetActiveWindow(attacker, attack.Token, timeline.FallbackAt, attack.Definition.Active))
assert(State.IsActive(attacker, timeline.FallbackAt + 0.01))
State.Interrupt(attacker, timeline.FallbackAt + 0.25)
assert(not State.IsActive(attacker, timeline.FallbackAt + 0.03))

local allowed = Policy.Authorize(attacker, defender, ar, dr)
assert(allowed == true)
local hitDefinition = { Damage = 20, PostureDamage = 35 }
local healthBefore = humanoid.Health
local result, dealt = Resolver.Apply(attacker, defender, ar, dr, humanoid, hitDefinition, now + 4)
assert(result == "Hit" and dealt > 0 and humanoid.Health < healthBefore)

assert(State.BeginGuard(defender, now + 4.1))
result = Resolver.Apply(attacker, defender, ar, dr, humanoid, hitDefinition, now + 4.11)
assert(result == "Parried")
State.EndGuard(defender, now + 4.2)
assert(State.BeginGuard(defender, now + 5))
local defendState = State.Get(defender)
defendState.ParryUntil = 0
defendState.Guard = 1
healthBefore = humanoid.Health
defender:SetAttribute("CombatDamageTakenMultiplier", 0)
result, dealt = Resolver.Apply(attacker, defender, ar, dr, humanoid, hitDefinition, now + 5.1)
assert(result == "GuardBroken" and dealt == 0 and humanoid.Health == healthBefore)

State.Cleanup(attacker)
State.Cleanup(defender)
Movement.Forget(attacker)
Movement.Forget(defender)
attacker:Destroy()
defender:Destroy()
print("Combat regression assertions finished in Studio")
