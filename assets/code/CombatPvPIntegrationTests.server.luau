local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)
local Policy = require(script.Parent.CombatPolicy)
local Consequences = require(script.Parent.CombatZoneConsequences)
local Resolver = require(script.Parent.CombatResolver)
local State = require(script.Parent.CombatState)

local users = Players:GetPlayers()
if #users < 2 then
    warn("PvP integration tests need at least two Studio players")
    return
end

local attacker = users[1]
local defender = users[2]
local ac = attacker.Character or attacker.CharacterAdded:Wait()
local dc = defender.Character or defender.CharacterAdded:Wait()
local ar = ac:WaitForChild("HumanoidRootPart")
local dr = dc:WaitForChild("HumanoidRootPart")
local humanoid = dc:FindFirstChildOfClass("Humanoid")
assert(humanoid)

local function zone(name, position)
    local part = Instance.new("Part")
    part.Name = "TestZone" .. name
    part.Anchored = true
    part.Transparency = 1
    part.CanCollide = false
    part.Size = Vector3.new(12, 20, 12)
    part.Position = position
    part:SetAttribute("ZoneType", name)
    part.Parent = workspace
    CollectionService:AddTag(part, Config.ZoneTag)
    return part
end

Policy.SetConsequenceHandler(Consequences.Apply)
attacker:SetAttribute("PvPEnabled", true)
defender:SetAttribute("PvPEnabled", true)

local zoneA = zone("Red", ar.Position)
local zoneB = zone("Dark", dr.Position)
local allowed, info = Policy.Authorize(ac, dc, ar, dr)
assert(allowed and info.Zone == "Dark")
assert(Policy.RecordConsequence(info))
assert(attacker:GetAttribute("PvPFlagUntil") > workspace:GetServerTimeNow())
assert(defender:GetAttribute("PvPFlagUntil") > workspace:GetServerTimeNow())
assert(attacker:GetAttribute("PvPLastZone") == "Dark")

CollectionService:RemoveTag(zoneB, Config.ZoneTag)
zoneB:SetAttribute("ZoneType", "Safe")
CollectionService:AddTag(zoneB, Config.ZoneTag)
assert(Policy.Authorize(ac, dc, ar, dr) == false)
zoneA:Destroy()
zoneB:Destroy()
State.Cleanup(ac)
State.Cleanup(dc)
print("PvP integration assertions finished in Studio")
