local RunService = game:GetService("RunService")
local Movement = require(script.Parent.CombatMovementGuard)
local Config = require(script.Parent.CombatConfig)

if not RunService:IsStudio() then
    return
end

local model = Instance.new("Model")
model.Name = "MovementTrustFixture"
local root = Instance.new("Part")
root.Name = "HumanoidRootPart"
root.Size = Vector3.new(2, 3, 2)
root.Anchored = true
root.CanCollide = false
root.CFrame = CFrame.new(0, 15000, 0)
root.Parent = model
local humanoid = Instance.new("Humanoid")
humanoid.RequiresNeck = false
humanoid.Parent = model
model.Parent = workspace

local ok, err = xpcall(function()
    Movement.Track(model)
    local baseline = Movement.TrustedPosition(model, os.clock())
    assert(baseline ~= nil)
    root.Position += Vector3.new(400, 0, 0)
    assert(Movement.TrustedPosition(model, os.clock()) == nil)
    assert((root.Position - baseline).Magnitude < 0.01)
    task.wait(Config.Movement.Quarantine + 0.1)
    assert(Movement.TrustedPosition(model, os.clock()) ~= nil)
end, debug.traceback)

Movement.Forget(model)
model:Destroy()
assert(ok, err)
print("CombatMovementTrustTests passed")
