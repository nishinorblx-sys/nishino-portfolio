local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Workspace = game:GetService("Workspace")

local Config = require(script.Parent.CombatConfig)
local Combat = require(script.Parent.CombatHitboxService)
local Movement = require(script.Parent.CombatMovementGuard)
local Hurtboxes = require(script.Parent.CombatHurtboxIndex)

if not RunService:IsStudio() then
    return
end

local scenarios = {
    { Attackers = 1, Targets = 1 },
    { Attackers = 5, Targets = 10 },
    { Attackers = 10, Targets = 25 },
    { Attackers = 20, Targets = 50 },
}

local oldGravity = Workspace.Gravity
local created = {}
local replaced = {}
local measuredFrames = {}
local frameConnection = nil
local origin = Vector3.new(0, 21000, 0)

local function percentile(values, fraction)
    if #values == 0 then
        return 0
    end
    table.sort(values)
    return values[math.ceil(#values * fraction)]
end

local function npc(name, position, look, attacker)
    local model = Instance.new("Model")
    model.Name = name
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Size = Vector3.new(2, 3, 2)
    root.Anchored = not attacker
    root.CanCollide = false
    root.CanQuery = true
    root.CFrame = CFrame.lookAt(position, position + look)
    root.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 100000
    humanoid.Health = 100000
    humanoid.RequiresNeck = false
    humanoid.Parent = model
    model.Parent = Workspace
    created[#created + 1] = model
    CollectionService:AddTag(model, Config.NPCTag)
    Movement.Track(model)
    Hurtboxes.Track(model)
    if attacker then
        local tool = Instance.new("Tool")
        tool.Name = "ProfileTrainingSword"
        tool.RequiresHandle = false
        tool:SetAttribute("CombatWeaponId", "TrainingSword")
        tool.Parent = model
        CollectionService:AddTag(tool, Config.WeaponTag)
        pcall(function()
            root:SetNetworkOwner(nil)
        end)
    end
    return model, root
end

local function restorePlayers()
    for player, item in pairs(replaced) do
        if player.Character == item.Character and item.Root.Parent == item.Character then
            item.Root.CFrame = item.CFrame
            item.Root.Anchored = item.Anchored
            if item.Humanoid and item.Humanoid.Parent then
                item.Humanoid.MaxHealth = item.MaxHealth
                item.Humanoid.Health = math.min(item.MaxHealth, item.Health)
            end
            Movement.Forget(item.Character)
            Movement.Track(item.Character)
        end
        replaced[player] = nil
    end
end

local function cleanup()
    if frameConnection then
        frameConnection:Disconnect()
        frameConnection = nil
    end
    restorePlayers()
    for _, model in ipairs(created) do
        Combat.Cleanup(model)
        Movement.Forget(model)
        Hurtboxes.Forget(model)
        model:Destroy()
    end
    table.clear(created)
    Workspace.Gravity = oldGravity
end

local function placeStudioPlayers(attackerRoot)
    local count = 0
    for _, player in ipairs(Players:GetPlayers()) do
        if count >= 2 then
            break
        end
        local character = player.Character
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        if root and humanoid and humanoid.Health > 0 then
            replaced[player] = {
                Character = character,
                Root = root,
                Humanoid = humanoid,
                CFrame = root.CFrame,
                Anchored = root.Anchored,
                Health = humanoid.Health,
                MaxHealth = humanoid.MaxHealth,
            }
            root.Anchored = true
            root.CFrame = CFrame.lookAt(attackerRoot.Position + Vector3.new(0, 0, -3.4), attackerRoot.Position)
            humanoid.MaxHealth = 100000
            humanoid.Health = 100000
            Movement.Forget(character)
            Movement.Track(character)
            count += 1
        end
    end
    return count
end

local function runScenario(scenario)
    local base = origin + Vector3.new(scenario.Attackers * 80, 0, 0)
    local attackers = {}
    for index = 1, scenario.Attackers do
        local position = base + Vector3.new(index * 12, 0, 0)
        local model, root = npc("ProfileAttacker" .. index, position, Vector3.new(0, 0, -1), true)
        attackers[#attackers + 1] = { Model = model, Root = root }
    end
    for index = 1, scenario.Targets do
        local owner = attackers[(index - 1) % scenario.Attackers]
        local lateral = (index % 3 - 1) * 0.9
        local position = owner.Root.Position + Vector3.new(lateral, 0, -3.1 - (index % 2) * 0.3)
        npc("ProfileTarget" .. index, position, Vector3.new(0, 0, 1), false)
    end
    task.wait(0.3)
    local playersIncluded = placeStudioPlayers(attackers[1].Root)
    measuredFrames = {}
    frameConnection = RunService.Heartbeat:Connect(function(dt)
        measuredFrames[#measuredFrames + 1] = dt * 1000
    end)
    Combat.Diagnostics(true)
    local accepted = 0
    local rejected = 0
    debug.profilebegin("FoallowCombatPipeline")
    for _, item in ipairs(attackers) do
        local ok, reason = Combat.RequestNPC(item.Model, "Light")
        if ok then
            accepted += 1
        else
            rejected += 1
            warn("Combat load request rejected:", reason)
        end
    end
    task.wait(0.65)
    debug.profileend()
    local diagnostics = Combat.Diagnostics(false)
    frameConnection:Disconnect()
    frameConnection = nil
    local frameP95 = percentile(measuredFrames, 0.95)
    local status = accepted == scenario.Attackers and diagnostics.Scans > 0 and diagnostics.Queries > 0 and diagnostics.Resolutions > 0 and diagnostics.ProcessingSamples > 0 and diagnostics.TotalProcessingMs > 0 and diagnostics.Faults == 0
    print(string.format("Combat load %s | attackers=%d npcTargets=%d playerTargets=%d accepted=%d rejected=%d scans=%d queries=%d rays=%d resolutions=%d hits=%d activePeak=%d avgSample=%.3fms p95Sample=%.3fms avgProcessing=%.3fms p95Processing=%.3fms totalProcessing=%.3fms p95HeartbeatInterval=%.3fms faults=%d", status and "PASS" or "FAIL", scenario.Attackers, scenario.Targets, playersIncluded, accepted, rejected, diagnostics.Scans, diagnostics.Queries, diagnostics.Rays, diagnostics.Resolutions, diagnostics.Hits, diagnostics.ActivePeak, diagnostics.AverageMs, diagnostics.P95Ms, diagnostics.AverageProcessingMs, diagnostics.P95ProcessingMs, diagnostics.TotalProcessingMs, frameP95, diagnostics.Faults))
    assert(status, "Combat profiler reported missing real resolutions, rejected attacks or faults")
    restorePlayers()
    for _, item in ipairs(attackers) do
        Combat.Cleanup(item.Model)
    end
    for _, model in ipairs(created) do
        Movement.Forget(model)
        Hurtboxes.Forget(model)
        model:Destroy()
    end
    table.clear(created)
    task.wait(0.25)
end

local function run()
    Workspace.Gravity = 0
    for _, scenario in ipairs(scenarios) do
        runScenario(scenario)
    end
    print("CombatLoadProfiler PASS: four real pipeline scenarios completed")
end

local ok, err = xpcall(run, debug.traceback)
cleanup()
assert(ok, err)
