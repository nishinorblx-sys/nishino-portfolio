local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Resolver = require(script.Parent.CombatResolver)
local Timeline = require(script.Parent.CombatTimeline)
local Hurtboxes = require(script.Parent.CombatHurtboxIndex)

local Combat = {}
local active = {}
local heartbeat = nil
local lastRemote = setmetatable({}, { __mode = "k" })

Players.PlayerRemoving:Connect(function(player)
    lastRemote[player] = nil
end)

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

local function visible(fromRoot, targetRoot, target, raycast)
    local displacement = targetRoot.Position - fromRoot.Position
    if displacement.Magnitude < 0.001 then
        return true
    end
    local hit = Workspace:Raycast(fromRoot.Position, displacement, raycast)
    return hit == nil or hit.Instance:IsDescendantOf(target)
end

local function scan(context, now)
    local character = context.Character
    local root = living(character)
    if not root then
        return false
    end
    local definition = context.Attack.Definition
    local roots, version = Hurtboxes.Snapshot()
    if context.IndexVersion ~= version then
        context.Overlap.FilterDescendantsInstances = roots
        context.IndexVersion = version
    end
    if #roots == 0 then
        return true
    end
    local center = root.CFrame * CFrame.new(0, 0, -definition.Reach * 0.5)
    local region = Vector3.new(definition.Width, definition.Height, definition.Reach)
    local parts = Workspace:GetPartBoundsInBox(center, region, context.Overlap)
    local candidates = context.Candidates
    table.clear(candidates)
    local radius = definition.Reach + Config.MaxTargetRadiusAllowance
    local maximumDistance = radius * radius
    for _, part in ipairs(parts) do
        local candidate = part.Parent
        if candidate and candidate:IsA("Model") and candidate ~= character and not context.Seen[candidate] then
            local humanoid = candidate:FindFirstChildOfClass("Humanoid")
            if humanoid and humanoid.Health > 0 then
                local offset = part.Position - root.Position
                local distance = offset:Dot(offset)
                if distance <= maximumDistance and offset:Dot(root.CFrame.LookVector) >= -0.25 then
                    candidates[#candidates + 1] = { Character = candidate, Root = part, Humanoid = humanoid, Distance = distance }
                end
            end
        end
    end
    table.sort(candidates, function(a, b)
        if a.Distance == b.Distance then
            return Hurtboxes.Rank(a.Character) < Hurtboxes.Rank(b.Character)
        end
        return a.Distance < b.Distance
    end)
    for _, candidate in ipairs(candidates) do
        if not context.Seen[candidate.Character] and visible(root, candidate.Root, candidate.Character, context.Raycast) then
            context.Seen[candidate.Character] = true
            local outcome = Resolver.Apply(character, candidate.Character, root, candidate.Root, candidate.Humanoid, definition, now)
            if outcome == "Hit" or outcome == "Blocked" or outcome == "Parried" or outcome == "Clashed" or outcome == "GuardBroken" then
                context.Hits += 1
            end
            if context.Hits >= definition.MaxTargets or not State.IsCurrent(character, context.Attack.Token, os.clock()) then
                break
            end
        end
    end
    return true
end

local function stop(context, aborted)
    if context.Stopped then
        return
    end
    context.Stopped = true
    local character = context.Character
    if active[character] == context then
        active[character] = nil
    end
    for _, connection in ipairs(context.Connections) do
        connection:Disconnect()
    end
    table.clear(context.Connections)
    Timeline.Close(context.Timing)
    if aborted then
        State.AbortAttack(character, context.Attack.Token)
        if context.Track then
            pcall(function()
                context.Track:Stop(0.06)
            end)
        end
    else
        State.CompleteAttack(character, context.Attack.Token)
    end
end

local function openWindow(context, now, viaMarker)
    if context.Stopped then
        return false
    end
    local timeline = context.Timing
    if not Timeline.TryOpen(timeline, now, context.Attack.Definition.Active, viaMarker) then
        return false
    end
    if not State.SetActiveWindow(context.Character, context.Attack.Token, now, context.Attack.Definition.Active) then
        stop(context, true)
        return false
    end
    context.Elapsed = context.Attack.Definition.SampleInterval
    return true
end

local function validContext(context, now)
    local root, humanoid = living(context.Character)
    if not root or not humanoid or not State.IsCurrent(context.Character, context.Attack.Token, now) then
        return false
    end
    local weapon, tool = equippedWeapon(context.Character)
    if not weapon or tool ~= context.Tool or weapon ~= context.Weapon then
        return false
    end
    if root.Anchored or humanoid.Sit or root.AssemblyLinearVelocity.Magnitude > Config.MaxLinearSpeed then
        return false
    end
    return State.UpdateMovement(context.Character, root.Position, now)
end

local function update(dt)
    local now = os.clock()
    for _, context in pairs(active) do
        if context.Stopped then
            continue
        end
        if now > context.Timing.Deadline or not validContext(context, now) then
            stop(context, true)
            continue
        end
        local timeline = context.Timing
        if timeline.Phase == "Pending" then
            openWindow(context, now, false)
        end
        if timeline.Phase == "Active" then
            if now >= timeline.EndAt then
                stop(context, false)
                continue
            end
            context.Elapsed += dt
            if context.Elapsed >= context.Attack.Definition.SampleInterval then
                context.Elapsed = 0
                if not scan(context, now) or context.Hits >= context.Attack.Definition.MaxTargets then
                    stop(context, false)
                end
            end
        end
    end
    if heartbeat and next(active) == nil then
        heartbeat:Disconnect()
        heartbeat = nil
    end
end

local function ensureHeartbeat()
    if not heartbeat then
        heartbeat = RunService.Heartbeat:Connect(update)
    end
end

local function attachAnimation(context, humanoid, action)
    local folder = context.Tool:FindFirstChild("CombatAnimations")
    if not folder then
        context.Timing.FallbackAt = context.Timing.PlannedStart
        return
    end
    local animationName = action == "Light" and "Light" .. tostring(context.Attack.Combo) or "Heavy"
    local animation = folder:FindFirstChild(animationName)
    local animator = humanoid:FindFirstChildOfClass("Animator")
    if not animation or not animation:IsA("Animation") or not animator then
        context.Timing.FallbackAt = context.Timing.PlannedStart
        return
    end
    local loaded, track = pcall(function()
        return animator:LoadAnimation(animation)
    end)
    if not loaded or not track then
        context.Timing.FallbackAt = context.Timing.PlannedStart
        return
    end
    context.Track = track
    context.Connections[#context.Connections + 1] = track:GetMarkerReachedSignal("HitStart"):Connect(function()
        local now = os.clock()
        if validContext(context, now) then
            openWindow(context, now, true)
        else
            stop(context, true)
        end
    end)
    context.Connections[#context.Connections + 1] = track:GetMarkerReachedSignal("HitEnd"):Connect(function()
        if context.Timing.Phase == "Active" then
            stop(context, false)
        end
    end)
    context.Connections[#context.Connections + 1] = track.Stopped:Connect(function()
        if context.Timing.Phase == "Active" then
            stop(context, false)
        elseif not context.Stopped then
            context.Timing.FallbackAt = context.Timing.PlannedStart
        end
    end)
    local played = pcall(function()
        track:Play(0.04)
    end)
    if not played then
        context.Timing.FallbackAt = context.Timing.PlannedStart
        for _, connection in ipairs(context.Connections) do
            connection:Disconnect()
        end
        table.clear(context.Connections)
        context.Track = nil
    end
end

function Combat.Request(player, action)
    if typeof(player) ~= "Instance" or not player:IsA("Player") or not player.Parent then
        return false, "Invalid player"
    end
    if type(action) ~= "string" or (action ~= "Light" and action ~= "Heavy" and action ~= "GuardStart" and action ~= "GuardEnd") then
        return false, "Invalid action"
    end
    local now = os.clock()
    if now - (lastRemote[player] or -math.huge) < 0.03 then
        return false, "Rate limited"
    end
    lastRemote[player] = now
    local character = player.Character
    local root, humanoid = living(character)
    if not root or root.Anchored or humanoid.Sit or root.AssemblyLinearVelocity.Magnitude > Config.MaxLinearSpeed then
        return false, "Invalid character"
    end
    if action == "GuardEnd" then
        State.EndGuard(character, now)
        return true, "Guard released"
    end
    local allowed, reason = State.CanRequest(character, now)
    if not allowed then
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
    local attack, attackReason = State.BeginAttack(character, action, weapon, now)
    if not attack then
        return false, attackReason
    end
    local overlap = OverlapParams.new()
    overlap.FilterType = Enum.RaycastFilterType.Include
    overlap.RespectCanCollide = false
    overlap.MaxParts = 0
    local raycast = RaycastParams.new()
    raycast.FilterType = Enum.RaycastFilterType.Exclude
    raycast.FilterDescendantsInstances = { character }
    raycast.IgnoreWater = true
    local context = {
        Character = character,
        Tool = tool,
        Weapon = weapon,
        Attack = attack,
        Timing = Timeline.New(attack, now, Config),
        Overlap = overlap,
        Raycast = raycast,
        IndexVersion = -1,
        Seen = {},
        Candidates = {},
        Hits = 0,
        Elapsed = 0,
        Track = nil,
        Connections = {},
        Stopped = false,
    }
    local older = active[character]
    if older then
        stop(older, true)
    end
    active[character] = context
    local setupOk = pcall(attachAnimation, context, humanoid, action)
    if not setupOk then
        for _, connection in ipairs(context.Connections) do
            connection:Disconnect()
        end
        table.clear(context.Connections)
        if context.Track then
            pcall(function()
                context.Track:Stop(0)
            end)
            context.Track = nil
        end
        context.Timing.FallbackAt = context.Timing.PlannedStart
    end
    ensureHeartbeat()
    return true, table.freeze({ Action = action, Combo = attack.Combo, StartsAt = context.Timing.PlannedStart, EndsAt = attack.EndsAt })
end

function Combat.Cancel(character)
    local context = active[character]
    if context then
        stop(context, true)
    end
end

function Combat.Cleanup(character)
    Combat.Cancel(character)
    State.Cleanup(character)
end

return Combat
