local ReplicatedStorage = game:GetService("ReplicatedStorage")

local delta = ReplicatedStorage:WaitForChild("FoallowStateDelta")
local snapshotRemote = ReplicatedStorage:WaitForChild("FoallowStateSnapshot")
local Players = game:GetService("Players")
local localPlayer = Players.LocalPlayer
local state = {}

local function publish(fields)
    for key, value in pairs(fields) do
        localPlayer:SetAttribute("Foallow_" .. key, value)
    end
end
local version = -1
local recovering = false

local function requestSnapshot()
    if recovering then
        return
    end
    recovering = true
    task.spawn(function()
        local success, response = pcall(snapshotRemote.InvokeServer, snapshotRemote)
        if success and response and type(response.Fields) == "table" and type(response.Version) == "number" and response.Version >= version then
            state = table.clone(response.Fields)
            publish(state)
            version = response.Version
        end
        recovering = false
    end)
end

delta.OnClientEvent:Connect(function(kind, sequence, fields)
    if type(fields) ~= "table" or type(sequence) ~= "number" then
        return
    end
    if kind == "Snapshot" and sequence >= version then
        state = table.clone(fields)
        publish(state)
        version = sequence
        return
    end
    if kind == "Delta" then
        if sequence ~= version + 1 then
            requestSnapshot()
            return
        end
        for key, value in pairs(fields) do
            state[key] = value
        end
        publish(fields)
        version = sequence
    end
end)

requestSnapshot()
