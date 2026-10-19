local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")

local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Resolver = require(script.Parent.CombatResolver)

local Combat = {}
local active = setmetatable({}, { __mode = "k" })

local function living(character)
    if not character or not character.Parent then
        return nil
    end
    local root = character:FindFirstChild("HumanoidRootPart")
    local humanoid = character:FindFirstChildOfClass("Humanoid")
    if not root or not root:IsA("BasePart") or not humanoid or humanoid.Health <= 0 then
        return nil
    end
    return root, humanoid
end

local function equippedWeapon(character)
    local tool = character:FindFirstChildOfClass("Tool")
    if not tool or not CollectionService:HasTag(tool, Config.WeaponTag) then
        return nil
    end
    local weaponId = tool:GetAttribute("CombatWeaponId")
    if type(weaponId) ~= "string" then
        return nil
    end
    return Config.Weapons[weaponId], tool
end

local function visible(fromRoot, targetRoot, attacker, target, raycast)
    local displacement = targetRoot.Position - fromRoot.Position
    if displacement.Magnitude <= 0.001 then
        return true
    end
    local hit = Workspace:Raycast(fromRoot.Position, displacement, raycast)
    return hit == nil or hit.Instance:IsDescendantOf(target)
end

local function scan(character, attack, seen, hitCounter, buffers, overlap, raycast, now)
    local root = living(character)
    if not root then
        return false
    end
    local definition = attack.Definition
    local size = Vector3.new(definition.Width, definition.Height, definition.Reach)
    local center = root.CFrame * CFrame.new(0, 0, -definition.Reach * 0.5)
    local parts = Workspace:GetPartBoundsInBox(center, size, overlap)
    local candidates = buffers.Candidates
    local unique = buffers.Unique
    table.clear(candidates)
    table.clear(unique)
    local maximumRadius = definition.Reach + Config.MaxTargetRadiusAllowance
    local maximumRadiusSquared = maximumRadius * maximumRadius

    for _, part in ipairs(parts) do
        local candidate = part:FindFirstAncestorOfClass("Model")
        if candidate and candidate ~= character and not seen[candidate] and not unique[candidate] then
            unique[candidate] = true
            local targetRoot = candidate:FindFirstChild("HumanoidRootPart")
            local targetHumanoid = candidate:FindFirstChildOfClass("Humanoid")
            if targetRoot and targetRoot:IsA("BasePart") and targetHumanoid and targetHumanoid.Health > 0 then
                local displacement = targetRoot.Position - root.Position
                local distanceSquared = displacement:Dot(displacement)
                if distanceSquared <= maximumRadiusSquared and displacement:Dot(root.CFrame.LookVector) >= -0.25 then
                    candidates[#candidates + 1] = { Character = candidate, Root = targetRoot, Humanoid = targetHumanoid, Distance = distanceSquared }
                end
            end
        end
    end

    table.sort(candidates, function(left, right)
        if left.Distance == right.Distance then
            return false
        end
        return left.Distance < right.Distance
    end)

    for _, candidate in ipairs(candidates) do
        if seen[candidate.Character] then
            continue
        end
        if not visible(root, candidate.Root, character, candidate.Character, raycast) then
            continue
        end
        seen[candidate.Character] = true
        local outcome = Resolver.Apply(character, candidate.Character, root, candidate.Root, candidate.Humanoid, definition, now)
        if outcome == "Hit" or outcome == "Blocked" or outcome == "Parried" or outcome == "Clashed" or outcome == "GuardBroken" then
            hitCounter.Count += 1
        end
        if hitCounter.Count >= definition.MaxTargets or not State.IsCurrent(character, attack.Token, os.clock()) then
            break
        end
    end
    return true
end

local function runWindow(character, tool, attack)
    local started = os.clock()
    local lifetime = math.min(Config.MaxAttackLifetime, attack.EndsAt - started + 0.1)
    if lifetime <= 0 or active[character] then
        return
    end
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Exclude
    overlap.FilterDescendantsInstances = { character }
    overlap.RespectCanCollide = false
    overlap.MaxParts = 0
    local raycast = RaycastParams.new()
    raycast.FilterType = Enum.RaycastFilterType.Exclude
    raycast.FilterDescendantsInstances = { character }
    raycast.IgnoreWater = true
    local seen = {}
    local hitCounter = { Count = 0 }
    local buffers = { Candidates = {}, Unique = {} }
    local elapsed = 0
    local connection
    local function stop()
        if connection then
            connection:Disconnect()
        end
        if active[character] == attack.Token then
            active[character] = nil
        end
    end
    active[character] = attack.Token
    local function step(dt)
        local now = os.clock()
        local root, humanoid = living(character)
        if not root or not humanoid or tool.Parent ~= character or not State.IsCurrent(character, attack.Token, now) or not State.IsActive(character, now) or now > attack.EndsAt or now - started > lifetime or hitCounter.Count >= attack.Definition.MaxTargets then
            stop()
            return
        end
        elapsed += dt
        if elapsed < attack.Definition.SampleInterval then
            return
        end
        elapsed = 0
        scan(character, attack, seen, hitCounter, buffers, overlap, raycast, now)
        if not State.IsCurrent(character, attack.Token, os.clock()) then
            stop()
        end
    end
    connection = RunService.Heartbeat:Connect(step)
    step(attack.Definition.SampleInterval)
end

local function startScheduledWindow(character, tool, attack)
    task.delay(attack.Definition.Windup, function()
        local currentRoot = living(character)
        if currentRoot and tool.Parent == character and State.IsCurrent(character, attack.Token, os.clock()) then
            runWindow(character, tool, attack)
        end
    end)
end

local function startAnimationWindow(character, humanoid, tool, action, attack)
    local folder = tool:FindFirstChild("CombatAnimations")
    if not folder then
        return false
    end
    local animationName = action == "Light" and "Light" .. tostring(attack.Combo) or "Heavy"
    local animation = folder:FindFirstChild(animationName)
    if not animation or not animation:IsA("Animation") then
        return true
    end
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animator then
        return true
    end
    local loaded, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if not loaded or not track then
        return true
    end
    State.SuspendActiveWindow(character, attack.Token)
    local connections = {}
    local finished = false
    local function close()
        if finished then
            return
        end
        finished = true
        State.EndActiveWindow(character, attack.Token, os.clock())
        for _, connection in ipairs(connections) do
            connection:Disconnect()
        end
    end
    connections[#connections + 1] = track:GetMarkerReachedSignal("HitStart"):Connect(function()
        local now = os.clock()
        if finished or not State.IsCurrent(character, attack.Token, now) or tool.Parent ~= character then
            return
        end
        if State.SetActiveWindow(character, attack.Token, now, attack.Definition.Active) then
            local scheduled = table.freeze({
                Definition = attack.Definition,
                Token = attack.Token,
                Combo = attack.Combo,
                StartsAt = now,
                EndsAt = now + attack.Definition.Active,
            })
            runWindow(character, tool, scheduled)
        end
    end)
    connections[#connections + 1] = track:GetMarkerReachedSignal("HitEnd"):Connect(close)
    connections[#connections + 1] = track.Stopped:Connect(close)
    local played = pcall(function()
        track:Play(0.04)
    end)
    if not played then
        close()
    else
        task.delay(Config.MaxAttackLifetime, function()
            if not finished then
                close()
                track:Stop(0.08)
            end
        end)
    end
    return true
end

local function verifyPlayer(player)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or not player.Parent then
        return nil
    end
    local character = player.Character
    local root, humanoid = living(character)
    if not root or root.Anchored or humanoid.Sit or root.AssemblyLinearVelocity.Magnitude > Config.MaxLinearSpeed then
        return nil
    end
    return character, root, humanoid
end

function Combat.Request(player, action)
    if type(action) ~= "string" or (action ~= "Light" and action ~= "Heavy" and action ~= "GuardStart" and action ~= "GuardEnd") then
        return false, "Invalid action"
    end
    local character, root, humanoid = verifyPlayer(player)
    if not character then
        return false, "Invalid character"
    end
    local now = os.clock()
    if action == "GuardEnd" then
        State.EndGuard(character, now)
        return true, "Guard released"
    end
    local accepted, reason = State.CanRequest(character, now)
    if not accepted then
        return false, reason
    end
    if not State.UpdateMovement(character, root.Position, now) then
        return false, "Implausible movement"
    end
    local weapon, tool = equippedWeapon(character)
    if not weapon then
        return false, "No authorized weapon"
    end
    if action == "GuardStart" then
        return State.BeginGuard(character, now), "Guard"
    end
    local attack, attackError = State.BeginAttack(character, action, weapon, now)
    if not attack then
        return false, attackError
    end
    if not startAnimationWindow(character, humanoid, tool, action, attack) then
        startScheduledWindow(character, tool, attack)
    end
    return true, table.freeze({ Action = action, Combo = attack.Combo, StartsAt = attack.StartsAt, EndsAt = attack.EndsAt })
end

function Combat.Cleanup(character)
    State.Cleanup(character)
    active[character] = nil
end

return Combat
