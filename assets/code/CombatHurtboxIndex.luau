local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)

local Index = {}
local roots = {}
local characters = {}
local cleanupConnections = {}
local ranks = {}
local lastRank = 0
local snapshot = {}
local version = 0
local dirty = true

local function invalidate()
    version += 1
    dirty = true
end

local function setRoot(character, root)
    if not characters[character] then
        return
    end
    if root and (not root:IsA("BasePart") or root.Name ~= "HumanoidRootPart" or root.Parent ~= character) then
        return
    end
    if roots[character] ~= root then
        roots[character] = root
        invalidate()
    end
end

function Index.Track(character)
    if not character or characters[character] then
        return
    end
    characters[character] = true
    lastRank += 1
    ranks[character] = lastRank
    cleanupConnections[character] = {
        character.Destroying:Connect(function()
            Index.Forget(character)
        end),
        character.ChildAdded:Connect(function(child)
            if child.Name == "HumanoidRootPart" then
                setRoot(character, child)
            end
        end),
        character.ChildRemoved:Connect(function(child)
            if roots[character] == child then
                setRoot(character, nil)
            end
        end),
    }
    local existing = character:FindFirstChild("HumanoidRootPart")
    if existing then
        setRoot(character, existing)
    end
end

function Index.Forget(character)
    if not characters[character] then
        return
    end
    characters[character] = nil
    ranks[character] = nil
    local connections = cleanupConnections[character]
    if connections then
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
        cleanupConnections[character] = nil
    end
    if roots[character] then
        roots[character] = nil
        invalidate()
    end
end

function Index.Rank(character)
    return ranks[character] or math.huge
end

function Index.Snapshot()
    if dirty then
        table.clear(snapshot)
        for character, root in pairs(roots) do
            if characters[character] and root.Parent == character then
                snapshot[#snapshot + 1] = root
            end
        end
        dirty = false
    end
    return snapshot, version
end

local function hookPlayer(player)
    player.CharacterAdded:Connect(Index.Track)
    player.CharacterRemoving:Connect(Index.Forget)
    if player.Character then
        Index.Track(player.Character)
    end
end

for _, player in ipairs(Players:GetPlayers()) do
    hookPlayer(player)
end
Players.PlayerAdded:Connect(hookPlayer)

for _, character in ipairs(CollectionService:GetTagged(Config.NPCTag)) do
    if character:IsA("Model") then
        Index.Track(character)
    end
end
CollectionService:GetInstanceAddedSignal(Config.NPCTag):Connect(function(character)
    if character:IsA("Model") then
        Index.Track(character)
    end
end)
CollectionService:GetInstanceRemovedSignal(Config.NPCTag):Connect(function(character)
    Index.Forget(character)
end)

return Index
