local Players = game:GetService("Players")
local Workspace = game:GetService("Workspace")

local CombatHitboxService = {}

local ATTACKS = table.freeze({
    Light = table.freeze({ Damage = 12, Cooldown = 0.35, Reach = 5.5, Width = 5, Height = 5, MaxTargets = 4 }),
    Heavy = table.freeze({ Damage = 27, Cooldown = 1.1, Reach = 7, Width = 6, Height = 5, MaxTargets = 6 }),
})

local cooldowns = {}

Players.PlayerRemoving:Connect(function(player)
    cooldowns[player] = nil
end)

function CombatHitboxService.Perform(player, attackName)
    if typeof(player) ~= "Instance" or not player:IsA("Player") then
        return false, "Invalid player"
    end

    if type(attackName) ~= "string" then
        return false, "Invalid attack"
    end

    local attack = ATTACKS[attackName]
    if not attack then
        return false, "Unknown attack"
    end

    local character = player.Character
    if not character then
        return false, "Character missing"
    end

    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        return false, "Character unavailable"
    end

    local now = os.clock()
    local playerCooldowns = cooldowns[player]
    if not playerCooldowns then
        playerCooldowns = {}
        cooldowns[player] = playerCooldowns
    end

    if now < (playerCooldowns[attackName] or 0) then
        return false, "Cooldown"
    end

    playerCooldowns[attackName] = now + attack.Cooldown

    local query = OverlapParams.new()
    query.FilterType = Enum.RaycastFilterType.Exclude
    query.FilterDescendantsInstances = { character }
    query.MaxParts = 128
    query.RespectCanCollide = false

    local size = Vector3.new(attack.Width, attack.Height, attack.Reach)
    local origin = root.CFrame * CFrame.new(0, 0, -(attack.Reach * 0.5 + 1.5))
    local parts = Workspace:GetPartBoundsInBox(origin, size, query)
    local seen = {}
    local hitCount = 0

    for _, part in ipairs(parts) do
        local model = part:FindFirstAncestorOfClass("Model")
        if model and model ~= character and not seen[model] then
            seen[model] = true
            local targetHumanoid = model:FindFirstChildOfClass("Humanoid")
            if targetHumanoid and targetHumanoid.Health > 0 then
                local targetPlayer = Players:GetPlayerFromCharacter(model)
                if not targetPlayer or player.Neutral or targetPlayer.Neutral or player.Team ~= targetPlayer.Team then
                    targetHumanoid:TakeDamage(attack.Damage)
                    hitCount += 1
                    if hitCount >= attack.MaxTargets then
                        break
                    end
                end
            end
        end
    end

    return true, hitCount
end

return CombatHitboxService
