local Workspace = game:GetService("Workspace")
local Index = require(script.Parent.CombatHurtboxIndex)

local roots = Index.Snapshot()
local params = OverlapParams.new()
params.FilterType = Enum.RaycastFilterType.Include
params.FilterDescendantsInstances = roots
params.MaxParts = 0
local origin = CFrame.new(0, 6, 0)
local volume = Vector3.new(6, 5, 8)
local count = 400
local returned = 0

debug.profilebegin("FoallowCombatDenseOverlap")
local started = os.clock()
for _ = 1, count do
    local parts = Workspace:GetPartBoundsInBox(origin, volume, params)
    returned += #parts
end
local total = os.clock() - started
debug.profileend()
print(string.format("Indexed roots: %d | scans: %d | returned: %d | total: %.4fs | average: %.4fms", #roots, count, returned, total, total * 1000 / count))
