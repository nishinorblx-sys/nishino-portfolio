local UserInputService = game:GetService("UserInputService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Players = game:GetService("Players")

local remote = ReplicatedStorage:WaitForChild("CombatNet"):WaitForChild("Action")
local player = Players.LocalPlayer
local holding = false

local function request(action)
    remote:FireServer(action)
end

UserInputService.InputBegan:Connect(function(input, processed)
    if processed then
        return
    end
    if input.UserInputType == Enum.UserInputType.MouseButton1 then
        request("Light")
    elseif input.UserInputType == Enum.UserInputType.MouseButton2 then
        request("Parry")
    elseif input.KeyCode == Enum.KeyCode.G then
        request("Heavy")
    elseif input.KeyCode == Enum.KeyCode.F and not holding then
        holding = true
        request("GuardStart")
        task.spawn(function()
            while holding do
                task.wait(0.7)
                if holding then
                    request("GuardKeepAlive")
                end
            end
        end)
    end
end)

UserInputService.InputEnded:Connect(function(input)
    if input.KeyCode == Enum.KeyCode.F and holding then
        holding = false
        request("GuardEnd")
    end
end)

player.CharacterRemoving:Connect(function()
    if holding then
        holding = false
        request("GuardEnd")
    end
end)
