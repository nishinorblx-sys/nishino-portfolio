local Players = game:GetService("Players")
local RunService = game:GetService("RunService")

if not RunService:IsStudio() then
    return
end

local State = require(script.Parent.CombatState)
local Runner = require(script.Parent.AbilityRunner)

Runner.Register("TestBeforeCommit", {
    Cooldown = 1,
    Duration = 0.6,
    Recovery = 0.05,
    Cost = 6,
    Run = function()
        error("Intentional precommit failure")
    end,
})

Runner.Register("TestAfterCommit", {
    Cooldown = 1.5,
    Duration = 0.6,
    Recovery = 0.05,
    Cost = 8,
    Run = function(context)
        assert(context:Commit())
        context:After(0.1, function()
            error("Intentional postcommit failure")
        end)
    end,
})

Runner.Register("TestHold", {
    Cooldown = 0.5,
    Duration = 0.75,
    Recovery = 0.1,
    Cost = 5,
    Run = function(context)
        assert(context:Commit())
        context:After(0.5, function(session)
            session:Complete()
        end)
    end,
})

local function test(player)
    local character = player.Character or player.CharacterAdded:Wait()
    task.wait(0.2)
    State.SetEssence(character, 50)
    local accepted = Runner.Execute(player, "TestBeforeCommit")
    assert(not accepted)
    assert(State.GetEssence(character) == 50)
    assert(Runner.GetRemaining(player, "TestBeforeCommit") == 0)

    task.wait(0.1)
    accepted = Runner.Execute(player, "TestHold")
    assert(accepted)
    assert(State.GetEssence(character) == 45)
    assert(not State.CanAttack(character, os.clock()))
    task.wait(0.15)
    assert(not State.CanAttack(character, os.clock()))
    assert(not Runner.Execute(player, "TestAfterCommit"))
    task.wait(0.5)
    assert(State.CanAttack(character, os.clock()))

    accepted = Runner.Execute(player, "TestAfterCommit")
    assert(accepted)
    task.wait(0.2)
    assert(State.CanAttack(character, os.clock()))
    assert(State.GetEssence(character) == 37)
    assert(Runner.GetRemaining(player, "TestAfterCommit") > 0)
    print("AbilityIntegrationTests passed for", player.Name)
end

local launched = false
local function launch(player)
    if launched then
        return
    end
    launched = true
    task.spawn(function()
        local ok, result = pcall(test, player)
        if not ok then
            error("AbilityIntegrationTests failed: " .. tostring(result))
        end
    end)
end

for _, player in ipairs(Players:GetPlayers()) do
    launch(player)
end
Players.PlayerAdded:Connect(launch)
