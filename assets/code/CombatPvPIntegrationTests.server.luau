local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)
local Policy = require(script.Parent.CombatPolicy)
local Movement = require(script.Parent.CombatMovementGuard)
local Resolver = require(script.Parent.CombatResolver)
local State = require(script.Parent.CombatState)
local Consequences = require(script.Parent.CombatZoneConsequences)
local Combat = require(script.Parent.CombatHitboxService)
local ServerStorage = game:GetService("ServerStorage")

if not RunService:IsStudio() then
    return
end

local players = Players:GetPlayers()
if #players < 2 then
    warn("CombatPvPIntegrationTests SKIPPED: run an isolated Studio session with two players")
    return
end

local attacker, defender = players[1], players[2]
local ac = attacker.Character or attacker.CharacterAdded:Wait()
local dc = defender.Character or defender.CharacterAdded:Wait()
local ar = ac:WaitForChild("HumanoidRootPart")
local dr = dc:WaitForChild("HumanoidRootPart")
local humanoid = dc:FindFirstChildOfClass("Humanoid")
assert(humanoid and humanoid.Health > 0, "Defender must have a living Humanoid")

local previous = {
    AttackerCFrame = ar.CFrame,
    DefenderCFrame = dr.CFrame,
    AttackerAnchored = ar.Anchored,
    DefenderAnchored = dr.Anchored,
    AttackerNeutral = attacker.Neutral,
    DefenderNeutral = defender.Neutral,
    AttackerPvP = attacker:GetAttribute("PvPEnabled"),
    DefenderPvP = defender:GetAttribute("PvPEnabled"),
    AttackerFlag = attacker:GetAttribute("PvPFlagUntil"),
    DefenderFlag = defender:GetAttribute("PvPFlagUntil"),
    AttackerZone = attacker:GetAttribute("PvPLastZone"),
    DefenderZone = defender:GetAttribute("PvPLastZone"),
    AttackerOpponent = attacker:GetAttribute("PvPLastOpponent"),
    DefenderOpponent = defender:GetAttribute("PvPLastOpponent"),
    MaxHealth = humanoid.MaxHealth,
    Health = humanoid.Health,
    AttackerFaction = ac:GetAttribute("CombatFaction"),
    DefenderFaction = dc:GetAttribute("CombatFaction"),
    AttackerStunned = ac:GetAttribute("Stunned"),
    DefenderStunned = dc:GetAttribute("Stunned"),
    AttackerKnocked = ac:GetAttribute("Knocked"),
    DefenderKnocked = dc:GetAttribute("Knocked"),
    AttackerDodging = ac:GetAttribute("Dodging"),
    DefenderDodging = dc:GetAttribute("Dodging"),
    AttackerBlocking = ac:GetAttribute("Blocking"),
    DefenderBlocking = dc:GetAttribute("Blocking"),
    DefenderMultiplier = dc:GetAttribute("CombatDamageTakenMultiplier"),
}

local fixtures = {}
local suppressedForceFields = {}
local checks = 0

local function zone(kind, position)
    local part = Instance.new("Part")
    part.Name = "IsolatedCombatTestZone"
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(8, 18, 3)
    part.CFrame = CFrame.new(position)
    part:SetAttribute("ZoneType", kind)
    part.Parent = workspace
    CollectionService:AddTag(part, Config.ZoneTag)
    fixtures[#fixtures + 1] = part
    return part
end

local function flags()
    return (attacker:GetAttribute("PvPFlagUntil") or 0) > workspace:GetServerTimeNow()
        and (defender:GetAttribute("PvPFlagUntil") or 0) > workspace:GetServerTimeNow()
end

local function clearFlags()
    attacker:SetAttribute("PvPFlagUntil", 0)
    defender:SetAttribute("PvPFlagUntil", 0)
end

local function verify(name, expected, definition, setup, expectedDamage)
    State.Cleanup(ac)
    State.Cleanup(dc)
    if setup then
        setup()
    end
    clearFlags()
    local before = humanoid.Health
    local result, damage = Resolver.Apply(ac, dc, ar, dr, humanoid, definition, os.clock())
    assert(result == expected, string.format("%s expected %s, received %s", name, expected, tostring(result)))
    assert((damage > 0) == expectedDamage, name .. " damage result incorrect")
    assert((humanoid.Health < before) == expectedDamage, name .. " health result incorrect")
    assert(flags() == (expected ~= "Forbidden"), name .. " PvP flag result incorrect")
    local defense = State.Defense(dc, os.clock())
    if expected == "Blocked" then
        assert(defense.Guarding and defense.Guard < Config.Guard.Max, "Blocked hit must drain guard")
    elseif expected == "Parried" or expected == "GuardBroken" then
        assert(not defense.Guarding, expected .. " must close guard")
    elseif expected == "Clashed" then
        assert(State.Get(dc).Action == nil and State.Get(ac).Action == nil, "Clash must interrupt both sides")
    end
    checks += 1
    print("PASS", name, result, damage)
end

local function run()
    for _, instance in ipairs(dc:GetDescendants()) do
        if instance:IsA("ForceField") then
            suppressedForceFields[#suppressedForceFields + 1] = { Instance = instance, Parent = instance.Parent }
            instance.Parent = ServerStorage
        end
    end
    ar.Anchored = true
    dr.Anchored = true
    humanoid.MaxHealth = 1000
    humanoid.Health = 1000
    ac:SetAttribute("CombatFaction", nil)
    dc:SetAttribute("CombatFaction", nil)
    for _, model in ipairs({ac, dc}) do
        model:SetAttribute("Stunned", nil)
        model:SetAttribute("Knocked", nil)
        model:SetAttribute("Dodging", nil)
        model:SetAttribute("Blocking", nil)
    end
    dc:SetAttribute("CombatDamageTakenMultiplier", 1)
    attacker.Neutral = true
    defender.Neutral = true
    attacker:SetAttribute("PvPEnabled", true)
    defender:SetAttribute("PvPEnabled", true)
    ar.CFrame = CFrame.lookAt(Vector3.new(0, 25000, 0), Vector3.new(0, 25000, -4))
    dr.CFrame = CFrame.lookAt(Vector3.new(0, 25000, -4), Vector3.new(0, 25000, 0))
    Movement.Forget(ac)
    Movement.Forget(dc)
    Movement.Track(ac)
    Movement.Track(dc)
    assert(Movement.Validate(ac, os.clock()), "Attacker fixture movement was not trusted")
    assert(Movement.Validate(dc, os.clock()), "Defender fixture movement was not trusted")
    Policy.SetConsequenceHandler(Consequences.Apply)
    local red = zone("Red", ar.Position)
    local dark = zone("Dark", dr.Position)
    local light = { Damage = 15, PostureDamage = 18 }
    local heavy = { Damage = 25, PostureDamage = Config.Guard.Max + 20 }
    local allowed, info = Policy.Authorize(ac, dc, ar, dr)
    assert(allowed and info and info.Zone == "Dark", "Cross-zone severity must choose Dark")
    verify("Hit", "Hit", light, nil, true)
    verify("Block", "Blocked", light, function()
        assert(State.BeginGuard(dc, os.clock()))
    end, false)
    verify("Parry", "Parried", light, function()
        assert(State.BeginParry(dc, os.clock()))
    end, false)
    verify("Clash", "Clashed", light, function()
        local now = os.clock()
        local attack = State.BeginAttack(dc, "Light", Config.Weapons.TrainingSword, now - 0.02)
        assert(attack)
        assert(State.SetActiveWindow(dc, attack.Token, now - 0.01, 0.1))
    end, false)
    verify("Guardbreak", "GuardBroken", heavy, function()
        assert(State.BeginGuard(dc, os.clock()))
    end, true)
    dark:SetAttribute("ZoneType", "Safe")
    verify("SafeZone", "Forbidden", light, nil, false)
    dark:SetAttribute("ZoneType", "Dark")
    red:SetAttribute("ZoneType", "Yellow")
    defender:SetAttribute("PvPEnabled", false)
    verify("PvPOptOut", "Forbidden", light, nil, false)
    defender:SetAttribute("PvPEnabled", true)
    State.Cleanup(ac)
    assert(State.BeginGuard(ac, os.clock()))
    ac:SetAttribute("Stunned", true)
    assert(Combat.Request(attacker, "GuardEnd"))
    assert(not State.Get(ac).Guarding, "GuardEnd must work while stunned and anchored")
    ac:SetAttribute("Stunned", nil)
    State.Cleanup(ac)
    local probeTime = os.clock()
    assert(State.BeginParry(ac, probeTime), "Parry fixture failed")
    assert(not State.KeepGuard(ac, probeTime + 0.05), "Parry must never accept held-guard renewal")
    assert(not State.Get(ac).Guarding, "A rejected parry renewal must not leave held guard active")
    checks += 2
    local now = os.clock()
    local pending = State.BeginAttack(dc, "Light", Config.Weapons.TrainingSword, now)
    assert(pending)
    assert(State.SetActiveWindow(dc, pending.Token, now, 0.1))
    State.Interrupt(dc, now + 1)
    assert(not State.IsCurrent(dc, pending.Token, now))
    assert(not State.IsActive(dc, now))
    checks += 1
    print(string.format("CombatPvPIntegrationTests PASS: %d resolver and lifecycle checks", checks))
end

local ok, err = xpcall(run, debug.traceback)
for _, part in ipairs(fixtures) do
    part:Destroy()
end
for _, item in ipairs(suppressedForceFields) do
    if item.Instance.Parent == ServerStorage then
        item.Instance.Parent = item.Parent
    end
end
ac:SetAttribute("Stunned", previous.AttackerStunned)
dc:SetAttribute("Stunned", previous.DefenderStunned)
ac:SetAttribute("Knocked", previous.AttackerKnocked)
dc:SetAttribute("Knocked", previous.DefenderKnocked)
ac:SetAttribute("Dodging", previous.AttackerDodging)
dc:SetAttribute("Dodging", previous.DefenderDodging)
ac:SetAttribute("Blocking", previous.AttackerBlocking)
dc:SetAttribute("Blocking", previous.DefenderBlocking)
ac:SetAttribute("CombatFaction", previous.AttackerFaction)
dc:SetAttribute("CombatFaction", previous.DefenderFaction)
dc:SetAttribute("CombatDamageTakenMultiplier", previous.DefenderMultiplier)
State.Cleanup(ac)
State.Cleanup(dc)
ar.CFrame = previous.AttackerCFrame
dr.CFrame = previous.DefenderCFrame
ar.Anchored = previous.AttackerAnchored
dr.Anchored = previous.DefenderAnchored
Movement.Forget(ac)
Movement.Forget(dc)
Movement.Track(ac)
Movement.Track(dc)
attacker.Neutral = previous.AttackerNeutral
defender.Neutral = previous.DefenderNeutral
attacker:SetAttribute("PvPEnabled", previous.AttackerPvP)
defender:SetAttribute("PvPEnabled", previous.DefenderPvP)
attacker:SetAttribute("PvPFlagUntil", previous.AttackerFlag)
defender:SetAttribute("PvPFlagUntil", previous.DefenderFlag)
attacker:SetAttribute("PvPLastZone", previous.AttackerZone)
defender:SetAttribute("PvPLastZone", previous.DefenderZone)
attacker:SetAttribute("PvPLastOpponent", previous.AttackerOpponent)
defender:SetAttribute("PvPLastOpponent", previous.DefenderOpponent)
humanoid.MaxHealth = previous.MaxHealth
humanoid.Health = math.min(previous.Health, previous.MaxHealth)
assert(ok, err)
