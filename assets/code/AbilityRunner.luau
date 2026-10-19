local Players = game:GetService("Players")

local AbilityRunner = {}

local definitions = {}
local cooldowns = {}
local executing = {}

Players.PlayerRemoving:Connect(function(player)
    cooldowns[player] = nil
    executing[player] = nil
end)

function AbilityRunner.Register(name, cooldown, callback)
    assert(type(name) == "string" and #name > 0 and #name <= 40, "Invalid ability name")
    assert(type(cooldown) == "number" and cooldown == cooldown and cooldown >= 0 and cooldown <= 120, "Invalid cooldown")
    assert(type(callback) == "function", "Callback must be a function")
    assert(definitions[name] == nil, "Ability is already registered")

    definitions[name] = table.freeze({
        Cooldown = cooldown,
        Run = callback,
    })
end

function AbilityRunner.Execute(player, abilityName)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "Invalid player"
    end

    if type(abilityName) ~= "string" then
        return false, "Invalid ability"
    end

    local definition = definitions[abilityName]
    if not definition then
        return false, "Ability not registered"
    end

    local character = player.Character
    local humanoid = character and character:FindFirstChildOfClass("Humanoid")
    if not humanoid or humanoid.Health <= 0 then
        return false, "Character unavailable"
    end

    local now = os.clock()
    local playerCooldowns = cooldowns[player]
    if not playerCooldowns then
        playerCooldowns = {}
        cooldowns[player] = playerCooldowns
    end

    if now < (playerCooldowns[abilityName] or 0) then
        return false, "Cooldown"
    end

    local active = executing[player]
    if not active then
        active = {}
        executing[player] = active
    end

    if active[abilityName] then
        return false, "Already executing"
    end

    active[abilityName] = true
    playerCooldowns[abilityName] = now + definition.Cooldown

    local succeeded, result = pcall(definition.Run, player, character)
    active[abilityName] = nil

    if not succeeded then
        warn("Ability failed:", abilityName, result)
        return false, "Execution failed"
    end

    return true, result
end

function AbilityRunner.GetRemaining(player, abilityName)
    local playerCooldowns = cooldowns[player]
    if not playerCooldowns then
        return 0
    end

    return math.max(0, (playerCooldowns[abilityName] or 0) - os.clock())
end

return AbilityRunner
