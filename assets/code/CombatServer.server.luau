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
    player.CharacterRemoving:Connect(Combat.Cleanup)
end

for _, player in ipairs(Players:GetPlayers()) do
    hookPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)

remote.OnServerEvent:Connect(function(player, action)
    local executed, accepted, details = pcall(Combat.Request, player, action)
    if not executed then
        warn("Combat.Request failed:", accepted)
        if player.Character then
            Combat.Cancel(player.Character)
        end
        return
    end
    if accepted and type(details) == "table" then
        local serverNow = workspace:GetServerTimeNow()
        local localNow = os.clock()
        remote:FireAllClients("AttackStarted", player, details.Action, details.Combo, serverNow + math.max(0, details.StartsAt - localNow), serverNow + math.max(0, details.EndsAt - localNow))
    elseif accepted and type(details) == "string" then
        if action == "Parry" then
            remote:FireAllClients("ParryStarted", player, require(script.Parent.CombatConfig).Guard.ParryWindow)
        elseif action ~= "GuardKeepAlive" then
            remote:FireAllClients("GuardChanged", player, action == "GuardStart")
        end
    elseif not accepted and type(action) == "string" and #action < 20 and details ~= "Rate limited" and details ~= "Invalid action" then
        remote:FireClient(player, "Rejected", details)
    end
end)
