local Players = game:GetService("Players")
local CollectionService = game:GetService("CollectionService")
local Config = require(script.Parent.CombatConfig)
local Combat = require(script.Parent.CombatHitboxService)
local Movement = require(script.Parent.CombatMovementGuard)

local scenarios = {
    { Attackers = 1, Targets = 1 },
    { Attackers = 5, Targets = 10 },
    { Attackers = 10, Targets = 25 },
    { Attackers = 20, Targets = 50 },
}

local function npc(position, index)
    local model = Instance.new("Model")
    model.Name = "LoadTarget" .. index
    local root = Instance.new("Part")
    root.Name = "HumanoidRootPart"
    root.Anchored = true
    root.CanCollide = false
    root.CanQuery = true
    root.CFrame = CFrame.new(position)
    root.Parent = model
    local humanoid = Instance.new("Humanoid")
    humanoid.MaxHealth = 100000
    humanoid.Health = 100000
    humanoid.RequiresNeck = false
    humanoid.Parent = model
    model.Parent = workspace
    CollectionService:AddTag(model, Config.NPCTag)
    Movement.Track(model)
    return model
end

local function runScenario(scenario)
    local users = Players:GetPlayers()
    if #users < scenario.Attackers then
        warn(string.format("Skipping %d attackers / %d targets: requires %d Studio clients, found %d", scenario.Attackers, scenario.Targets, scenario.Attackers, #users))
        return
    end
    local tools, targets = {}, {}
    for index = 1, scenario.Attackers do
        local player = users[index]
        local character = player.Character
        if not character or not character:FindFirstChild("HumanoidRootPart") then
            warn("Skipping scenario: missing character root")
            return
        end
        Combat.Cleanup(character)
        local tool = Instance.new("Tool")
        tool.Name = "LoadTrainingSword"
        tool.RequiresHandle = false
        tool:SetAttribute("CombatWeaponId", "TrainingSword")
        tool.Parent = character
        CollectionService:AddTag(tool, Config.WeaponTag)
        tools[#tools + 1] = tool
    end
    for index = 1, scenario.Targets do
        local player = users[((index - 1) % scenario.Attackers) + 1]
        local root = player.Character.HumanoidRootPart
        local location = root.Position + root.CFrame.LookVector * (2.7 + (index % 3) * 0.6) + root.CFrame.RightVector * (((index % 5) - 2) * 0.5)
        targets[#targets + 1] = npc(location, index)
    end
    task.wait(0.25)
    Combat.Diagnostics(true)
    debug.profilebegin("FoallowCombatPipeline")
    local started = os.clock()
    local accepted = 0
    for index = 1, scenario.Attackers do
        local allowed = Combat.Request(users[index], "Light")
        if allowed then
            accepted += 1
        end
    end
    task.wait(1)
    local elapsed = os.clock() - started
    local diagnostics = Combat.Diagnostics(false)
    debug.profileend()
    print(string.format("Combat load | attackers=%d targets=%d accepted=%d requests=%d scans=%d queries=%d rays=%d resolved=%d hits=%d peak=%d avg=%.3fms p95=%.3fms faults=%d elapsed=%.3fs", scenario.Attackers, scenario.Targets, accepted, diagnostics.Requests, diagnostics.Scans, diagnostics.Queries, diagnostics.Rays, diagnostics.Resolutions, diagnostics.Hits, diagnostics.ActivePeak, diagnostics.AverageMs, diagnostics.P95Ms, diagnostics.Faults, elapsed))
    for _, model in ipairs(targets) do
        Movement.Forget(model)
        model:Destroy()
    end
    for _, tool in ipairs(tools) do
        tool:Destroy()
    end
    for index = 1, scenario.Attackers do
        Combat.Cleanup(users[index].Character)
    end
    task.wait(0.25)
end

for _, scenario in ipairs(scenarios) do
    runScenario(scenario)
end
