local Config = require(script.Parent.CombatConfig)
local State = require(script.Parent.CombatState)
local Policy = require(script.Parent.CombatPolicy)
local Resolver = {}

local function facing(attackerRoot, defenderRoot)
    local offset = attackerRoot.Position - defenderRoot.Position
    local horizontal = Vector3.new(offset.X, 0, offset.Z)
    if horizontal.Magnitude < 0.01 then
        return false
    end
    local forward = defenderRoot.CFrame.LookVector
    local direction = Vector3.new(forward.X, 0, forward.Z)
    return direction:Dot(horizontal.Unit) >= Config.Guard.FacingDot
end

function Resolver.Apply(attacker, defender, attackerRoot, defenderRoot, humanoid, definition, now)
    if humanoid.Health <= 0 then
        return "Invalid", 0
    end
    local permitted, consequence = Policy.Authorize(attacker, defender, attackerRoot, defenderRoot)
    if not permitted then
        return "Forbidden", 0
    end
    local defenderState = State.Defense(defender, now)
    local defended = defenderState.Guarding and now >= defenderState.DisabledUntil and facing(attackerRoot, defenderRoot)
    if defended and now <= defenderState.ParryUntil then
        State.Interrupt(attacker, now + Config.Guard.StunOnParry)
        return "Parried", 0
    end
    if State.IsActive(defender, now) and facing(attackerRoot, defenderRoot) and facing(defenderRoot, attackerRoot) then
        State.Interrupt(attacker, now + Config.Guard.ClashStun)
        State.Interrupt(defender, now + Config.Guard.ClashStun)
        return "Clashed", 0
    end
    if defended then
        local broken = State.DrainGuard(defender, definition.PostureDamage, now)
        if broken then
            local overflowDamage = math.floor(definition.Damage * 0.25)
            if overflowDamage > 0 then
                local before = humanoid.Health
                humanoid:TakeDamage(overflowDamage)
                overflowDamage = math.max(0, before - humanoid.Health)
            end
            Policy.RecordConsequence(consequence, overflowDamage, "GuardBroken")
            return "GuardBroken", overflowDamage
        end
        Policy.RecordConsequence(consequence, 0, "Blocked")
        return "Blocked", 0
    end
    local multiplier = defender:GetAttribute("CombatDamageTakenMultiplier")
    if type(multiplier) ~= "number" or multiplier ~= multiplier then
        multiplier = 1
    end
    multiplier = math.clamp(multiplier, 0, 3)
    local damage = math.max(0, math.floor(definition.Damage * multiplier + 0.5))
    if damage > 0 then
        local before = humanoid.Health
        humanoid:TakeDamage(damage)
        damage = math.max(0, before - humanoid.Health)
    end
    Policy.RecordConsequence(consequence, damage, "Hit")
    return "Hit", damage
end

return Resolver
