local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local CollectionService = game:GetService("CollectionService")

if not RunService:IsStudio() or workspace:GetAttribute("FoallowRunE2E") ~= true then
    return
end

local Config = require(script.Parent.CombatConfig)
local Combat = require(script.Parent.CombatHitboxService)
local Movement = require(script.Parent.CombatMovementGuard)
local Hurtboxes = require(script.Parent.CombatHurtboxIndex)
local State = require(script.Parent.CombatState)

local player = Players:GetPlayers()[1] or Players.PlayerAdded:Wait()
local character = player.Character or player.CharacterAdded:Wait()
local root = character:WaitForChild("HumanoidRootPart")
local humanoid = character:FindFirstChildOfClass("Humanoid")
assert(humanoid and humanoid.Health > 0)

local oldSpeed = humanoid.WalkSpeed
local tool = Instance.new("Tool")
tool.Name = "FoallowE2ETrainingSword"
tool.RequiresHandle = false
tool:SetAttribute("CombatWeaponId", "TrainingSword")
CollectionService:AddTag(tool, Config.WeaponTag)
tool.Parent = character

local target = Instance.new("Model")
target.Name = "FoallowE2ETarget"
local targetRoot = Instance.new("Part")
targetRoot.Name = "HumanoidRootPart"
targetRoot.Anchored = true
targetRoot.CanCollide = false
targetRoot.CanQuery = true
targetRoot.Size = Vector3.new(2, 3, 2)
targetRoot.CFrame = CFrame.new(root.Position + root.CFrame.LookVector * 3, root.Position)
targetRoot.Parent = target
local targetHumanoid = Instance.new("Humanoid")
targetHumanoid.MaxHealth = 1000
targetHumanoid.Health = 1000
targetHumanoid.RequiresNeck = false
targetHumanoid.Parent = target
target.Parent = workspace
CollectionService:AddTag(target, Config.NPCTag)
Movement.Track(target)
Hurtboxes.Track(target)

local report = Instance.new("RemoteEvent")
report.Name = "FoallowE2EResult"
report.Parent = ReplicatedStorage
local finished = false
local reported = nil
local connection = report.OnServerEvent:Connect(function(sender, state, data)
    if sender == player and not finished and (state == "PASS" or state == "FAIL") then
        finished = true
        reported = { State = state, Detail = type(data) == "string" and string.sub(data, 1, 180) or "Invalid detail" }
    end
end)

local previousTest = player:GetAttribute("FoallowE2EReady")
local function execute()
    humanoid.WalkSpeed = 0
    Combat.Diagnostics(true)
    player:SetAttribute("FoallowE2EReady", true)
    local deadline = os.clock() + 14
    while not finished and os.clock() < deadline do
        task.wait(0.05)
    end
    local diagnostics = Combat.Diagnostics(false)
    assert(reported and reported.State == "PASS", reported and reported.Detail or "Client did not report within 14 seconds")
    assert(diagnostics.Accepted >= 2, "Light and Heavy were not both accepted")
    assert(diagnostics.Queries > 0 and diagnostics.Resolutions > 0, "No live hitbox resolution occurred")
    assert(targetHumanoid.Health < targetHumanoid.MaxHealth, "Target took no damage")
    assert(not State.Get(character).Guarding, "Guard state remained active")
    print(string.format("Foallow E2E PASS: accepted=%d scans=%d resolutions=%d hits=%d faults=%d p95Process=%.3fms health=%.1f", diagnostics.Accepted, diagnostics.Scans, diagnostics.Resolutions, diagnostics.Hits, diagnostics.Faults, diagnostics.P95ProcessingMs, targetHumanoid.Health))
    assert(diagnostics.Faults == 0, "Combat pipeline reported faults")
end

local ok, err = xpcall(execute, debug.traceback)
player:SetAttribute("FoallowE2EReady", previousTest)
connection:Disconnect()
report:Destroy()
Combat.Cleanup(character)
Combat.Cleanup(target)
Movement.Forget(target)
Hurtboxes.Forget(target)
target:Destroy()
tool:Destroy()
if humanoid.Parent then
    humanoid.WalkSpeed = oldSpeed
end
assert(ok, err)
