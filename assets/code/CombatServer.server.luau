local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local Combat = require(script.Parent.CombatHitboxService)
local Policy = require(script.Parent.CombatPolicy)
local Consequences = require(script.Parent.CombatZoneConsequences)

Policy.SetConsequenceHandler(Consequences.Apply)

local folder = ReplicatedStorage:FindFirstChild("CombatNet")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "CombatNet"
    folder.Parent = ReplicatedStorage
end

local remote = folder:FindFirstChild("Action")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "Action"
    remote.Parent = folder
end

assert(remote:IsA("RemoteEvent"), "CombatNet.Action must be a RemoteEvent")

local function hookPlayer(player)
    player.CharacterRemoving:Connect(function(character)
        Combat.Cleanup(character)
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    hookPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)

remote.OnServerEvent:Connect(function(player, action)
    local ok, details = Combat.Request(player, action)
    if ok and type(details) == "table" then
        local serverNow = workspace:GetServerTimeNow()
        local localNow = os.clock()
        local windowStart = serverNow + math.max(0, details.StartsAt - localNow)
        local windowEnd = serverNow + math.max(0, details.EndsAt - localNow)
        remote:FireAllClients("AttackStarted", player, details.Action, details.Combo, windowStart, windowEnd)
    elseif ok and type(details) == "string" then
        remote:FireAllClients("GuardChanged", player, action == "GuardStart")
    elseif not ok then
        remote:FireClient(player, "Rejected", details)
    end
end)
