local RunService = game:GetService("RunService")
local Workspace = game:GetService("Workspace")
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")

local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Movement = require(script.Parent.CombatMovementGuard)
local Resolver = require(script.Parent.CombatResolver)
local Timeline = require(script.Parent.CombatTimeline)
local Scheduler = require(script.Parent.CombatWindowScheduler)
local Hurtboxes = require(script.Parent.CombatHurtboxIndex)

local Combat = {}
local active = {}
local heartbeat = nil
local lastRemote = setmetatable({}, { __mode = "k" })
local metrics = { Requests = 0, Accepted = 0, Rejected = 0, Scans = 0, Queries = 0, Rays = 0, Resolutions = 0, Contacts = 0, Hits = 0, DamagingHits = 0, Blocked = 0, Parried = 0, Clashed = 0, GuardBroken = 0, Faults = 0, ActivePeak = 0, AnimationFallbacks = 0, SkippedSamples = 0, LateSamplesSkipped = 0, Samples = {}, SampleIndex = 0, ProcessingSamples = {}, ProcessingIndex = 0, ProcessingTotal = 0, FrameSamples = {}, FrameSampleIndex = 0, FrameProcessingTotal = 0 }

local function measureSample(elapsed)
    metrics.SampleIndex = metrics.SampleIndex % 2048 + 1
    metrics.Samples[metrics.SampleIndex] = elapsed * 1000
end

local function describe(values)
    local ordered = table.clone(values)
    table.sort(ordered)
    local total = 0
    for _, value in ipairs(ordered) do
        total += value
    end
    return #ordered > 0 and total / #ordered or 0, #ordered > 0 and ordered[math.ceil(#ordered * 0.95)] or 0
end

function Combat.Diagnostics(reset)
    local scanAverage, scanP95 = describe(metrics.Samples)
    local processingAverage, processingP95 = describe(metrics.ProcessingSamples)
    local frameAverage, frameP95 = describe(metrics.FrameSamples)
    local result = {
        Requests = metrics.Requests,
        Accepted = metrics.Accepted,
        Rejected = metrics.Rejected,
        Scans = metrics.Scans,
        Queries = metrics.Queries,
        Rays = metrics.Rays,
        Resolutions = metrics.Resolutions,
        Contacts = metrics.Contacts,
        Hits = metrics.Hits,
        DamagingHits = metrics.DamagingHits,
        Blocked = metrics.Blocked,
        Parried = metrics.Parried,
        Clashed = metrics.Clashed,
        GuardBroken = metrics.GuardBroken,
        AnimationFallbacks = metrics.AnimationFallbacks,
        SkippedSamples = metrics.SkippedSamples,
        LateSamplesSkipped = metrics.LateSamplesSkipped,
        Faults = metrics.Faults,
        ActivePeak = metrics.ActivePeak,
        P95Ms = scanP95,
        AverageMs = scanAverage,
        P95ProcessingMs = processingP95,
        AverageProcessingMs = processingAverage,
        TotalProcessingMs = metrics.ProcessingTotal,
        ProcessingSamples = #metrics.ProcessingSamples,
        AverageFrameProcessingMs = frameAverage,
        P95FrameProcessingMs = frameP95,
        TotalFrameProcessingMs = metrics.FrameProcessingTotal,
        FrameProcessingSamples = #metrics.FrameSamples,
    }
    if reset then
        for key, value in pairs(metrics) do
            metrics[key] = type(value) == "table" and {} or 0
        end
    end
    return table.freeze(result)
end

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

local function trusted(character, root, now)
    local accepted = Movement.TrustedPosition(character, now)
    if not accepted or (root.Position - accepted).Magnitude > Config.MaxTrustedPositionDeviation then
        return nil
    end
    return accepted
end

local function scan(context, now)
    local started = os.clock()
    metrics.Scans += 1
    local character = context.Character
    local root = living(character)
    if not root then
        return false
    end
    if not trusted(character, root, now) then
        metrics.Rejected += 1
        return false
    end
    local definition = context.Attack.Definition
    local roots, version = Hurtboxes.Snapshot()
    if context.IndexVersion ~= version then
        context.Overlap.FilterDescendantsInstances = roots
        context.IndexVersion = version
    end
    if #roots == 0 then
        measureSample(os.clock() - started)
        return true
    end
    local geometry = definition.Hitbox
    local base = root.CFrame * CFrame.Angles(0, geometry.Yaw, 0)
    local center = base * CFrame.new(geometry.Lateral, geometry.Vertical, -(definition.Reach * 0.5 + geometry.Forward))
    local region = Vector3.new(definition.Width, definition.Height, definition.Reach)
    local candidates = context.Candidates
    local collected = context.Collected
    table.clear(candidates)
    table.clear(collected)
    local maximumDistance = (definition.Reach + Config.MaxTargetRadiusAllowance) ^ 2
    local function collect(at)
        local parts
        if geometry.Shape == "Sphere" then
            parts = Workspace:GetPartBoundsInRadius(at.Position, math.max(region.X, region.Y, region.Z) * 0.5, context.Overlap)
        else
            parts = Workspace:GetPartBoundsInBox(at, region, context.Overlap)
        end
        metrics.Queries += 1
        for _, part in ipairs(parts) do
            local candidate = part.Parent
            if candidate and candidate:IsA("Model") and candidate ~= character and not context.Seen[candidate] and not collected[candidate] then
                local humanoid = candidate:FindFirstChildOfClass("Humanoid")
                if humanoid and humanoid.Health > 0 then
                    local offset = part.Position - root.Position
                    local distance = offset:Dot(offset)
                    if distance <= maximumDistance and offset:Dot(root.CFrame.LookVector) >= -0.25 then
                        collected[candidate] = true
                        candidates[#candidates + 1] = { Character = candidate, Root = part, Humanoid = humanoid, Distance = distance }
                    end
                end
            end
        end
    end
    local previous = context.PreviousHitbox
    local displacement = previous and (center.Position - previous.Position).Magnitude or 0
    if previous and displacement >= geometry.SweepDistance and displacement <= Config.MaxHitboxSweep then
        collect(previous:Lerp(center, 0.5))
    end
    collect(center)
    context.PreviousHitbox = center
    table.sort(candidates, function(a, b)
        if a.Distance == b.Distance then
            return Hurtboxes.Rank(a.Character) < Hurtboxes.Rank(b.Character)
        end
        return a.Distance < b.Distance
    end)
    for _, candidate in ipairs(candidates) do
        if not context.Seen[candidate.Character] and trusted(character, root, now) and trusted(candidate.Character, candidate.Root, now) then
            metrics.Rays += 1
            if visible(root, candidate.Root, candidate.Character, context.Raycast) then
                context.Seen[candidate.Character] = true
                local outcome, amount = Resolver.Apply(character, candidate.Character, root, candidate.Root, candidate.Humanoid, definition, now)
                metrics.Resolutions += 1
                if outcome == "Hit" or outcome == "Blocked" or outcome == "Parried" or outcome == "Clashed" or outcome == "GuardBroken" then
                    context.Hits += 1
                    metrics.Contacts += 1
                    if (amount or 0) > 0 then
                        metrics.DamagingHits += 1
                        metrics.Hits += 1
                    end
                    if outcome == "Blocked" then metrics.Blocked += 1 end
                    if outcome == "Parried" then metrics.Parried += 1 end
                    if outcome == "Clashed" then metrics.Clashed += 1 end
                    if outcome == "GuardBroken" then metrics.GuardBroken += 1 end
                elseif outcome == "Forbidden" or outcome == "Invalid" then
                    metrics.Rejected += 1
                end
                if context.Hits >= definition.MaxTargets or not State.IsCurrent(character, context.Attack.Token, os.clock()) then
                    break
                end
            end
        end
    end
    measureSample(os.clock() - started)
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
    context.Cadence = Scheduler.New(context.Attack.Definition.SampleInterval, now)
    if not viaMarker then metrics.AnimationFallbacks += 1 end
    local worked, outcome = xpcall(scan, debug.traceback, context, now)
    if not worked or not outcome then
        metrics.Faults += worked and 0 or 1
        if not worked then warn("Combat initial hit scan failed:", outcome) end
        stop(context, true)
        return false
    end
    if context.Hits >= context.Attack.Definition.MaxTargets then
        stop(context, false)
    end
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
    if root.Anchored or humanoid.Sit or (root.AssemblyLinearVelocity.Magnitude > Config.MaxLinearSpeed and not Movement.IsImpulseAuthorized(context.Character, now)) then
        return false
    end
    return State.UpdateMovement(context.Character, now)
end

local function stepContext(context, now, dt)
    if now > context.Timing.Deadline or not validContext(context, now) then
        stop(context, true)
        return
    end
    local timeline = context.Timing
    if timeline.Phase == "Pending" then
        openWindow(context, now, false)
        return
    end
    if context.Stopped or timeline.Phase ~= "Active" then
        return
    end
    local due, finished, skipped = Scheduler.Step(context.Cadence, dt, now, timeline.EndAt, Config.MaxFinalSampleLateness)
    metrics.SkippedSamples += skipped
    if finished and not due and now - timeline.EndAt > Config.MaxFinalSampleLateness then
        metrics.LateSamplesSkipped += 1
    end
    if due and context.Hits < context.Attack.Definition.MaxTargets then
        if not scan(context, now) then
            stop(context, true)
            return
        end
    end
    if finished or context.Hits >= context.Attack.Definition.MaxTargets then
        stop(context, false)
    end
end

local function update(dt)
    local frameStarted = os.clock()
    local now = frameStarted
    for _, context in pairs(active) do
        if not context.Stopped then
            local processingStart = os.clock()
            local ok, err = xpcall(stepContext, debug.traceback, context, now, dt)
            if not ok then
                metrics.Faults += 1
                warn("Combat attack aborted safely:", err)
                local cleaned, cleanupErr = pcall(stop, context, true)
                if not cleaned then
                    warn("Combat cleanup failed:", cleanupErr)
                    context.Stopped = true
                    active[context.Character] = nil
                    State.Interrupt(context.Character, now + 0.2)
                end
            end
            local milliseconds = (os.clock() - processingStart) * 1000
            metrics.ProcessingTotal += milliseconds
            metrics.ProcessingIndex = metrics.ProcessingIndex % 2048 + 1
            metrics.ProcessingSamples[metrics.ProcessingIndex] = milliseconds
        end
    end
    local frameElapsed = (os.clock() - frameStarted) * 1000
    metrics.FrameProcessingTotal += frameElapsed
    metrics.FrameSampleIndex = metrics.FrameSampleIndex % 2048 + 1
    metrics.FrameSamples[metrics.FrameSampleIndex] = frameElapsed
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
        if active[context.Character] == context and not context.Stopped then
            context.EndMarkerSeen = true
        end
    end)
    context.Connections[#context.Connections + 1] = track.Stopped:Connect(function()
        if context.Stopped then return end
        if context.Timing.Phase == "Active" then
            if os.clock() + 0.005 < context.Timing.EndAt then
                stop(context, true)
            end
        else
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

local function reject(reason)
    metrics.Rejected += 1
    return false, reason
end

local function beginAttack(character, action, now, weapon, tool, humanoid)
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
        Collected = {},
        PreviousHitbox = nil,
        Cadence = nil,
        Hits = 0,
        Track = nil,
        Connections = {},
        Stopped = false,
    }
    local older = active[character]
    if older then
        stop(older, true)
    end
    active[character] = context
    local running = 0
    for _ in pairs(active) do
        running += 1
    end
    metrics.ActivePeak = math.max(metrics.ActivePeak, running)
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
    metrics.Accepted += 1
    return true, table.freeze({ Action = action, Combo = attack.Combo, StartsAt = context.Timing.PlannedStart, EndsAt = attack.EndsAt })
end

function Combat.Request(player, action)
    metrics.Requests += 1
    if typeof(player) ~= "Instance" or not player:IsA("Player") or not player.Parent then
        return reject("Invalid player")
    end
    if type(action) ~= "string" or (action ~= "Light" and action ~= "Heavy" and action ~= "Parry" and action ~= "GuardStart" and action ~= "GuardEnd" and action ~= "GuardKeepAlive") then
        return reject("Invalid action")
    end
    local now = os.clock()
    local character = player.Character
    if action == "GuardEnd" then
        if character then
            State.EndGuard(character, now)
        end
        return true, "Guard released"
    end
    if now - (lastRemote[player] or -math.huge) < 0.03 then
        return reject("Rate limited")
    end
    lastRemote[player] = now
    local root, humanoid = living(character)
    if not root then
        return reject("Invalid character")
    end
    if action == "GuardKeepAlive" then
        local weapon = equippedWeapon(character)
        local physical = not root.Anchored and not humanoid.Sit and (root.AssemblyLinearVelocity.Magnitude <= Config.MaxLinearSpeed or Movement.IsImpulseAuthorized(character, now))
        local trusted = Movement.Validate(character, now)
        if not weapon or not physical or not trusted then
            State.EndGuard(character, now)
            return reject("Guard renewal rejected")
        end
        local renewed = State.KeepGuard(character, now)
        return renewed, renewed and "Guard renewed" or "Guard not eligible"
    end
    if root.Anchored or humanoid.Sit or (root.AssemblyLinearVelocity.Magnitude > Config.MaxLinearSpeed and not Movement.IsImpulseAuthorized(character, now)) then
        return reject("Invalid character")
    end
    local allowed, reason = State.CanRequest(character, now)
    if not allowed then
        return false, reason
    end
    if not State.UpdateMovement(character, now) then
        return reject("Implausible movement")
    end
    local weapon, tool = equippedWeapon(character)
    if not weapon then
        return reject("No authorized weapon")
    end
    if action == "GuardStart" then
        return State.BeginGuard(character, now), "Guard"
    end
    if action == "Parry" then
        return State.BeginParry(character, now), "Parry"
    end
    return beginAttack(character, action, now, weapon, tool, humanoid)
end

function Combat.RequestNPC(character, action)
    metrics.Requests += 1
    if typeof(character) ~= "Instance" or not character:IsA("Model") or not character:IsDescendantOf(Workspace) or not CollectionService:HasTag(character, Config.NPCTag) then
        return reject("Unauthorized NPC")
    end
    if action ~= "Light" and action ~= "Heavy" then
        return reject("Invalid action")
    end
    local now = os.clock()
    local root, humanoid = living(character)
    if not root or root.Anchored or humanoid.Sit then
        return reject("Invalid NPC")
    end
    if not State.UpdateMovement(character, now) then
        return reject("NPC movement was not trusted")
    end
    local weapon, tool = equippedWeapon(character)
    if not weapon then
        return reject("Missing server-authorized NPC weapon")
    end
    return beginAttack(character, action, now, weapon, tool, humanoid)
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
