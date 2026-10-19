local RunService = game:GetService("RunService")
local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

if not RunService:IsStudio() or workspace:GetAttribute("FoallowRunE2E") ~= true then
    return
end

local player = Players.LocalPlayer
local remote = ReplicatedStorage:WaitForChild("CombatNet"):WaitForChild("Action")
local report = ReplicatedStorage:WaitForChild("FoallowE2EResult")

local function request(action, expected, expectedAction)
    local received = false
    local errorReason = nil
    local connection = remote.OnClientEvent:Connect(function(kind, actor, value)
        if kind == expected and actor == player and (expectedAction == nil or value == expectedAction) then
            received = true
        elseif kind == "Rejected" then
            errorReason = tostring(actor)
        end
    end)
    remote:FireServer(action)
    local deadline = os.clock() + 2.5
    while not received and not errorReason and os.clock() < deadline do
        task.wait(0.02)
    end
    connection:Disconnect()
    assert(received, string.format("%s was not acknowledged: %s", action, tostring(errorReason or "timeout")))
end

local function run()
    while player:GetAttribute("FoallowE2EReady") ~= true do
        player:GetAttributeChangedSignal("FoallowE2EReady"):Wait()
    end
    task.wait(0.2)
    request("Light", "AttackStarted", "Light")
    task.wait(1.1)
    request("Parry", "ParryStarted")
    task.wait(0.95)
    request("GuardStart", "GuardChanged", true)
    task.wait(0.12)
    remote:FireServer("GuardKeepAlive")
    task.wait(0.12)
    request("GuardEnd", "GuardChanged", false)
    task.wait(0.15)
    request("Heavy", "AttackStarted", "Heavy")
    task.wait(0.65)
end

local ok, err = xpcall(run, debug.traceback)
if report.Parent then
    report:FireServer(ok and "PASS" or "FAIL", ok and "Server input acknowledgements received" or tostring(err))
end
assert(ok, err)
