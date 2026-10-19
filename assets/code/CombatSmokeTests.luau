local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Policy = require(script.Parent.CombatPolicy)

local character = Instance.new("Model")
local weapon = Config.Weapons.TrainingSword
local started = os.clock()

local first, firstReason = State.BeginAttack(character, "Light", weapon, started)
assert(first ~= nil, tostring(firstReason))
assert(first.Combo == 1)
assert(first.Definition.Reach == 5)
assert(State.IsCurrent(character, first.Token, started))
assert(not State.CanAttack(character, started + 0.05))
assert(State.BeginAttack(character, "Heavy", weapon, started + 0.05) == nil)

local second, secondReason = State.BeginAttack(character, "Light", weapon, State.Get(character).LockUntil + 0.03)
assert(second ~= nil, tostring(secondReason))
assert(second.Combo == 2)
State.Interrupt(character, started + 1.3)
assert(not State.IsCurrent(character, second.Token, started + 0.8))
assert(State.BeginGuard(character, started + 1.4))
assert(State.Defense(character, started + 1.4).ParryUntil > started + 1.4)
State.EndGuard(character, started + 1.55)

local target = Instance.new("Model")
local root1 = Instance.new("Part")
local root2 = Instance.new("Part")
root1.Position = Vector3.zero
root2.Position = Vector3.new(0, 0, -3)
CollectionService:AddTag(target, Config.NPCTag)
local allowed, consequence = Policy.Authorize(character, target, root1, root2)
assert(allowed == true and consequence == nil)
CollectionService:RemoveTag(target, Config.NPCTag)
assert(Policy.Authorize(character, target, root1, root2) == false)

State.Cleanup(character)
character:Destroy()
target:Destroy()
root1:Destroy()
root2:Destroy()
print("CombatSmokeTests passed")
