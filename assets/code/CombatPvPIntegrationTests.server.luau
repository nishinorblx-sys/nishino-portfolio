local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Config = require(script.Parent.CombatConfig)
local Policy = require(script.Parent.CombatPolicy)
local Movement = require(script.Parent.CombatMovementGuard)
local Resolver = require(script.Parent.CombatResolver)
local State = require(script.Parent.CombatState)
local Consequences = require(script.Parent.CombatZoneConsequences)

local users = Players:GetPlayers()
if #users < 2 then
    warn("CombatPvPIntegrationTests requires two Studio players in an isolated test place")
    return
end
local attacker, defender = users[1], users[2]
local ac = attacker.Character or attacker.CharacterAdded:Wait()
local dc = defender.Character or defender.CharacterAdded:Wait()
local ar = ac:WaitForChild("HumanoidRootPart")
local dr = dc:WaitForChild("HumanoidRootPart")
local humanoid = dc:FindFirstChildOfClass("Humanoid")
assert(humanoid and humanoid.Health > 0)
for _, shield in ipairs(dc:GetChildren()) do
    if shield:IsA("ForceField") then
        shield:Destroy()
    end
end
local originalMaxHealth, originalHealth = humanoid.MaxHealth, humanoid.Health
humanoid.MaxHealth = 1000
humanoid.Health = 1000
local oldACFrame, oldDCFrame = ar.CFrame, dr.CFrame
ar.CFrame = CFrame.lookAt(ar.Position, dr.Position)
dr.CFrame = CFrame.lookAt(dr.Position, ar.Position)
assert((ar.Position - dr.Position).Magnitude > 20, "Players must be at least 20 studs apart for isolated zone fixtures")

local oldPvP1, oldPvP2 = attacker:GetAttribute("PvPEnabled"), defender:GetAttribute("PvPEnabled")
local oldTeam1, oldTeam2 = attacker.Team, defender.Team
local oldNeutral1, oldNeutral2 = attacker.Neutral, defender.Neutral
attacker.Neutral = true
defender.Neutral = true
attacker:SetAttribute("PvPEnabled", true)
defender:SetAttribute("PvPEnabled", true)
Policy.SetConsequenceHandler(Consequences.Apply)
Movement.Track(ac)
Movement.Track(dc)

local function zone(name, position)
    local part = Instance.new("Part")
    part.Name = "CombatIntegrationZone" .. name
    part.Anchored = true
    part.CanCollide = false
    part.Transparency = 1
    part.Size = Vector3.new(12, 18, 12)
    part.Position = position
    part:SetAttribute("ZoneType", name)
    part.Parent = workspace
    CollectionService:AddTag(part, Config.ZoneTag)
    return part
end

local zoneA = zone("Red", ar.Position)
local zoneB = zone("Dark", dr.Position)
local base = os.clock()
local definition = { Damage = 12, PostureDamage = 12 }
local function apply(now, attackDefinition)
    return Resolver.Apply(ac, dc, ar, dr, humanoid, attackDefinition or definition, now)
end

local function clearFlags()
    attacker:SetAttribute("PvPFlagUntil", 0)
    defender:SetAttribute("PvPFlagUntil", 0)
end

local function flagged()
    return (attacker:GetAttribute("PvPFlagUntil") or 0) > workspace:GetServerTimeNow() and (defender:GetAttribute("PvPFlagUntil") or 0) > workspace:GetServerTimeNow()
end

local allowed, info = Policy.Authorize(ac, dc, ar, dr)
assert(allowed and info.Zone == "Dark")
local zoneCases = {
    { "Red", "Dark", "Dark" },
    { "Yellow", "Red", "Red" },
    { "Yellow", "Yellow", "Yellow" },
    { "Dark", "Dark", "Dark" },
}
for _, item in ipairs(zoneCases) do
    zoneA:SetAttribute("ZoneType", item[1])
    zoneB:SetAttribute("ZoneType", item[2])
    local canFight, selection = Policy.Authorize(ac, dc, ar, dr)
    assert(canFight and selection.Zone == item[3])
end
zoneA:SetAttribute("ZoneType", "Yellow")
defender:SetAttribute("PvPEnabled", false)
assert(not Policy.Authorize(ac, dc, ar, dr))
defender:SetAttribute("PvPEnabled", true)
zoneA:SetAttribute("ZoneType", "Red")
zoneB:SetAttribute("ZoneType", "Dark")
clearFlags()
local outcome, damage = apply(base)
assert(outcome == "Hit" and damage > 0 and flagged())

State.Cleanup(dc)
assert(State.BeginGuard(dc, base + 0.1))
clearFlags()
outcome, damage = apply(base + 0.11)
assert(outcome == "Blocked" and damage == 0 and flagged())

State.Cleanup(dc)
assert(State.BeginParry(dc, base + 0.2))
clearFlags()
outcome, damage = apply(base + 0.21)
assert(outcome == "Parried" and damage == 0 and flagged())

State.Cleanup(dc)
local attack = State.BeginAttack(dc, "Light", Config.Weapons.TrainingSword, base + 0.3)
assert(attack)
assert(State.SetActiveWindow(dc, attack.Token, base + 0.31, 0.1))
clearFlags()
outcome, damage = apply(base + 0.32)
assert(outcome == "Clashed" and damage == 0 and flagged())

State.Cleanup(dc)
assert(State.BeginGuard(dc, base + 0.4))
clearFlags()
outcome, damage = apply(base + 0.41, { Damage = 30, PostureDamage = Config.Guard.Max + 1 })
assert(outcome == "GuardBroken" and damage > 0 and flagged())

zoneB:SetAttribute("ZoneType", "Safe")
clearFlags()
outcome, damage = apply(base + 0.5)
assert(outcome == "Forbidden" and damage == 0 and not flagged())
zoneA:Destroy()
zoneB:Destroy()
State.Cleanup(ac)
State.Cleanup(dc)
attacker:SetAttribute("PvPEnabled", oldPvP1)
defender:SetAttribute("PvPEnabled", oldPvP2)
attacker.Team = oldTeam1
defender.Team = oldTeam2
attacker.Neutral = oldNeutral1
defender.Neutral = oldNeutral2
ar.CFrame = oldACFrame
dr.CFrame = oldDCFrame
humanoid.MaxHealth = originalMaxHealth
humanoid.Health = math.min(originalMaxHealth, originalHealth)
print("CombatPvPIntegrationTests passed: hit, block, parry, clash, guardbreak, zone prohibition")
