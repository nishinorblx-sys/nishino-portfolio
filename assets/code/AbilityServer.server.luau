local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local State = require(script.Parent.CombatState)
local Runner = require(script.Parent.AbilityRunner)
local Definitions = require(script.Parent.AbilityDefinitions)

Definitions.Register()

local folder = ReplicatedStorage:FindFirstChild("AbilityNet")
if not folder then
    folder = Instance.new("Folder")
    folder.Name = "AbilityNet"
    folder.Parent = ReplicatedStorage
end

local remote = folder:FindFirstChild("Request")
if not remote then
    remote = Instance.new("RemoteEvent")
    remote.Name = "Request"
    remote.Parent = folder
end
assert(remote:IsA("RemoteEvent"))

local function setup(player)
    player.CharacterAdded:Connect(function(character)
        State.SetEssence(character, 100)
    end)
    player.CharacterRemoving:Connect(function()
        Runner.Cancel(player, "Character removed")
    end)
    if player.Character then
        State.SetEssence(player.Character, 100)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end
Players.PlayerAdded:Connect(setup)

remote.OnServerEvent:Connect(function(player, name)
    if type(name) ~= "string" or #name > 40 then
        return
    end
    local executed, accepted, result = pcall(Runner.Execute, player, name)
    if not executed then
        warn("Ability execution failed:", accepted)
        return
    end
    if accepted then
        remote:FireClient(player, "Accepted", name, Runner.GetRemaining(player, name))
    elseif result ~= "Rate limited" then
        remote:FireClient(player, "Rejected", name, tostring(result))
    end
end)
