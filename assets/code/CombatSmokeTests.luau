local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Policy = require(script.Parent.CombatPolicy)
local Timeline = require(script.Parent.CombatTimeline)
local Hurtboxes = require(script.Parent.CombatHurtboxIndex)

local character = Instance.new("Model")
local weapon = Config.Weapons.TrainingSword
local started = os.clock()
local first, reason = State.BeginAttack(character, "Light", weapon, started)
assert(first ~= nil, tostring(reason))
assert(first.Combo == 1)
assert(first.Definition.Reach == 5)
assert(State.IsCurrent(character, first.Token, started))
assert(not State.IsActive(character, first.StartsAt))
assert(not State.CanAttack(character, started + 0.05))
assert(State.BeginAttack(character, "Heavy", weapon, started + 0.05) == nil)

local timing = Timeline.New(first, started, Config)
assert(not Timeline.TryOpen(timing, started, first.Definition.Active, false))
assert(not Timeline.TryOpen(timing, started, first.Definition.Active, true))
local late = timing.FallbackAt + 0.001
assert(Timeline.TryOpen(timing, late, first.Definition.Active, false))
assert(not Timeline.TryOpen(timing, late, first.Definition.Active, true))
assert(State.SetActiveWindow(character, first.Token, late, first.Definition.Active))
assert(State.IsActive(character, late + 0.005))
assert(State.CompleteAttack(character, first.Token))
assert(not State.IsActive(character, late + 0.02))

local nextAt = State.Get(character).LockUntil + 0.02
local second, secondReason = State.BeginAttack(character, "Light", weapon, nextAt)
assert(second ~= nil, tostring(secondReason))
assert(second.Combo == 2)
State.Interrupt(character, nextAt + 0.4)
assert(not State.IsCurrent(character, second.Token, nextAt + 0.2))
assert(State.BeginGuard(character, nextAt + 0.85))
assert(State.Defense(character, nextAt + 0.85).ParryUntil > nextAt + 0.85)
State.EndGuard(character, nextAt + 1.0)

local target = Instance.new("Model")
local root1 = Instance.new("Part")
local root2 = Instance.new("Part")
root1.Position = Vector3.zero
root2.Name = "HumanoidRootPart"
root2.Position = Vector3.new(0, 0, -3)
root2.Parent = target
local npcHumanoid = Instance.new("Humanoid")
npcHumanoid.Parent = target
target.Parent = workspace
CollectionService:AddTag(target, Config.NPCTag)
task.wait()
local registeredRoots = Hurtboxes.Snapshot()
assert(table.find(registeredRoots, root2) ~= nil)
local permitted = Policy.Authorize(character, target, root1, root2)
assert(permitted == true)
CollectionService:RemoveTag(target, Config.NPCTag)
local unregisteredRoots = Hurtboxes.Snapshot()
assert(table.find(unregisteredRoots, root2) == nil)
assert(Policy.Authorize(character, target, root1, root2) == false)

local failing = Timeline.New(first, started, Config)
assert(not Timeline.TryOpen(failing, failing.Deadline, first.Definition.Active, false))
local marker = Timeline.New(first, started, Config)
assert(Timeline.TryOpen(marker, marker.PlannedStart, first.Definition.Active, true))
assert(marker.StartAt == marker.PlannedStart)
assert(not Timeline.TryOpen(marker, marker.FallbackAt, first.Definition.Active, false))

State.Cleanup(character)
character:Destroy()
target:Destroy()
root1:Destroy()
root2:Destroy()
print("CombatSmokeTests passed")
