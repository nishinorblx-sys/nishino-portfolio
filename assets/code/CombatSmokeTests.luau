local RunService = game:GetService("RunService")
local CollectionService = game:GetService("CollectionService")
local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Policy = require(script.Parent.CombatPolicy)
local Timeline = require(script.Parent.CombatTimeline)
local Movement = require(script.Parent.CombatMovementGuard)
local Hurtboxes = require(script.Parent.CombatHurtboxIndex)


if not RunService:IsStudio() then
    return
end

local fixtures = {}

local function dummy(name, position, lookAt)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Anchored = true
    root.CanCollide = false
    root.CFrame = CFrame.lookAt(position, lookAt)
    root.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.RequiresNeck = false
    humanoid.Parent = model
    model.Parent = workspace
    CollectionService:AddTag(model, Config.NPCTag)
    Movement.Track(model)
    Hurtboxes.Track(model)
    fixtures[#fixtures + 1] = model
    return model, root
end

local function run()
    local character, root1 = dummy("SmokeAttacker", Vector3.new(0, 10, 0), Vector3.new(0, 10, -3))
    local target, root2 = dummy("SmokeDefender", Vector3.new(0, 10, -3), Vector3.new(0, 10, 0))
    local weapon = Config.Weapons.TrainingSword
    assert(#weapon.Light == 5)
    assert(#Config.Weapons.HeavySword.Light == 4)

    local now = os.clock()
    for combo = 1, 5 do
        local attack, reason = State.BeginAttack(character, "Light", weapon, now)
        assert(attack, tostring(reason))
        assert(attack.Combo == combo)
        local timing = Timeline.New(attack, now, Config)
        assert(not Timeline.TryOpen(timing, now, attack.Definition.Active, false))
        assert(Timeline.TryOpen(timing, timing.FallbackAt, attack.Definition.Active, false))
        assert(not Timeline.TryOpen(timing, timing.FallbackAt, attack.Definition.Active, true))
        assert(State.SetActiveWindow(character, attack.Token, timing.FallbackAt, attack.Definition.Active))
        assert(State.IsActive(character, timing.FallbackAt + 0.01))
        assert(State.CompleteAttack(character, attack.Token))
        now = State.Get(character).LockUntil + 0.02
    end
    local reset = State.BeginAttack(character, "Light", weapon, now + weapon.ComboReset + 0.01)
    assert(reset and reset.Combo == 1)
    State.Interrupt(character, now + 3)

    local allowed = Policy.Authorize(character, target, root1, root2)
    assert(allowed == true)
    local roots = Hurtboxes.Snapshot()
    assert(table.find(roots, root1) ~= nil)
    assert(table.find(roots, root2) ~= nil)
    local guard = State.Get(character)
    assert(not pcall(function()
        guard.Guard = -100
    end))

    local defNow = now + 4
    assert(State.BeginParry(target, defNow))
    assert(State.Defense(target, defNow).ParryUntil > defNow)
    assert(State.Defense(target, defNow).GuardMode == "Parry")
    assert(not State.KeepGuard(target, defNow + 0.01))
    State.EndGuard(target, defNow + 0.18)
    assert(State.BeginGuard(target, defNow + 0.19))
    assert(State.Defense(target, defNow + 0.2).ParryUntil == 0)
    assert(State.Defense(target, defNow + 0.2).GuardMode == "Hold")
    State.EndGuard(target, defNow + 0.3)
    assert(not State.OpenAbilityWindow(target, 0, 0 / 0, 0.1))

end

local ok, err = xpcall(run, debug.traceback)
for _, instance in ipairs(fixtures) do
    if instance:IsA("Model") then
        State.Cleanup(instance)
        Movement.Forget(instance)
        Hurtboxes.Forget(instance)
    end
    instance:Destroy()
end
assert(ok, err)
print("CombatSmokeTests passed")
