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

local function damageMultiplier(defender)
    local value = defender:GetAttribute("CombatDamageTakenMultiplier")
    if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
        value = 1
    end
    return math.clamp(value, 0, 3)
end

local function deal(humanoid, base, defender)
    local amount = math.max(0, math.floor(base * damageMultiplier(defender) + 0.5))
    if amount == 0 then
        return 0
    end
    local before = humanoid.Health
    humanoid:TakeDamage(amount)
    return math.max(0, before - humanoid.Health)
end

function Resolver.Apply(attacker, defender, attackerRoot, defenderRoot, humanoid, definition, now)
    if not humanoid or humanoid.Health <= 0 then
        return "Invalid", 0
    end
    local permitted, consequence = Policy.Authorize(attacker, defender, attackerRoot, defenderRoot)
    if not permitted or not Policy.RecordConsequence(consequence) then
        return "Forbidden", 0
    end
    local state = State.Defense(defender, now)
    local defended = state.Guarding and now >= state.DisabledUntil and not (defender:GetAttribute("Stunned") == true or defender:GetAttribute("Knocked") == true or defender:GetAttribute("Dodging") == true) and facing(attackerRoot, defenderRoot)
    if defended and now <= state.ParryUntil then
        State.Interrupt(attacker, now + Config.Guard.StunOnParry)
        State.EndGuard(defender, now)
        return "Parried", 0
    end
    if State.IsActive(defender, now) and facing(attackerRoot, defenderRoot) and facing(defenderRoot, attackerRoot) then
        State.Interrupt(attacker, now + Config.Guard.ClashStun)
        State.Interrupt(defender, now + Config.Guard.ClashStun)
        return "Clashed", 0
    end
    if defended then
        if State.DrainGuard(defender, definition.PostureDamage, now) then
            return "GuardBroken", deal(humanoid, definition.Damage * 0.25, defender)
        end
        return "Blocked", 0
    end
    return "Hit", deal(humanoid, definition.Damage, defender)
end

return Resolver
