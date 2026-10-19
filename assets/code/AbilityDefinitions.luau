local Workspace = game:GetService("Workspace")

local Runner = require(script.Parent.AbilityRunner)
local Hurtboxes = require(script.Parent.CombatHurtboxIndex)

local Abilities = {}

function Abilities.Register()
    Runner.Register("EmberStrike", {
        Cooldown = 4.5,
        Duration = 0.9,
        Recovery = 0.25,
        Cost = 18,
        RequiredWeaponId = "TrainingSword",
        Hit = {
            Damage = 22,
            PostureDamage = 26,
            Range = 6,
            ConeDot = 0.15,
        },
        Run = function(context)
            if not context:Commit() then
                return
            end
            context:After(0.2, function(session)
                if not session:OpenHitWindow(0.18) then
                    session:Cancel("Hit window unavailable")
                    return
                end
                local character = session.Character
                local root = character:FindFirstChild("HumanoidRootPart")
                if not root then
                    session:Cancel("No root")
                    return
                end
                local roots = Hurtboxes.Snapshot()
                local overlap = OverlapParams.new()
                overlap.FilterType = Enum.RaycastFilterType.Include
                overlap.FilterDescendantsInstances = roots
                overlap.MaxParts = 0
                local parts = Workspace:GetPartBoundsInBox(root.CFrame * CFrame.new(0, 0, -3), Vector3.new(5, 5, 6), overlap)
                local scored = {}
                for _, part in ipairs(parts) do
                    local model = part.Parent
                    if model ~= character then
                        local offset = part.Position - root.Position
                        scored[#scored + 1] = { Model = model, Distance = offset:Dot(offset) }
                    end
                end
                table.sort(scored, function(a, b)
                    if a.Distance == b.Distance then
                        return a.Model:GetFullName() < b.Model:GetFullName()
                    end
                    return a.Distance < b.Distance
                end)
                local count = 0
                for _, candidate in ipairs(scored) do
                    local outcome = session:Hit(candidate.Model)
                    if outcome == "Hit" or outcome == "Blocked" or outcome == "Parried" or outcome == "Clashed" or outcome == "GuardBroken" then
                        count += 1
                    end
                    if not session:IsCurrent() or count >= 3 then
                        break
                    end
                end
            end)
            context:After(0.55, function(session)
                session:Complete()
            end)
        end,
    })

    Runner.Register("Focus", {
        Cooldown = 6,
        Duration = 1.1,
        Recovery = 0.2,
        Cost = 10,
        Run = function(context)
            local character = context.Character
            local previous = character:GetAttribute("FocusActive")
            context:OnCleanup(function()
                if character:GetAttribute("FocusToken") == context.Token then
                    character:SetAttribute("FocusActive", previous)
                    character:SetAttribute("FocusToken", nil)
                end
            end)
            character:SetAttribute("FocusToken", context.Token)
            character:SetAttribute("FocusActive", true)
            if not context:Commit() then
                return
            end
            context:After(0.75, function(session)
                session:Complete()
            end)
        end,
    })
end

return Abilities
