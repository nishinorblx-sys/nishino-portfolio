local Config = require(script.Parent.CombatConfig)
local Movement = require(script.Parent.CombatMovementGuard)

local states = setmetatable({}, { __mode = "k" })
local State = {}

local function get(character)
    local state = states[character]
    if not state then
        state = {
            Guard = Config.Guard.Max,
            GuardAt = os.clock(),
            Guarding = false,
            GuardMode = nil,
            ParryUntil = 0,
            ParryReadyAt = 0,
            DisabledUntil = 0,
            LockUntil = 0,
            HeavyUntil = 0,
            LightUntil = 0,
            ComboIndex = 0,
            ComboExpiresAt = 0,
            Token = 0,
            ActiveFrom = 0,
            ActiveUntil = 0,
            Action = nil,
            RequestedAt = 0,
            Recovery = 0,
            LastRequest = -math.huge,
            GuardLeaseUntil = 0,
            Essence = nil,
        }
        states[character] = state
    end
    return state
end

local function refreshGuard(state, now)
    if state.Guarding and (now >= state.GuardLeaseUntil or state.Guard <= 0) then
        state.Guarding = false
        state.GuardMode = nil
        state.ParryUntil = 0
        state.GuardAt = math.min(now, state.GuardLeaseUntil)
    end
    if not state.Guarding then
        state.Guard = math.min(Config.Guard.Max, state.Guard + math.max(0, now - state.GuardAt) * Config.Guard.Regeneration)
    end
    state.GuardAt = now
end

local function snapshot(state)
    return table.freeze({
        Guard = state.Guard,
        Guarding = state.Guarding,
        GuardMode = state.GuardMode,
        ParryUntil = state.ParryUntil,
        ParryReadyAt = state.ParryReadyAt,
        DisabledUntil = state.DisabledUntil,
        LockUntil = state.LockUntil,
        ComboIndex = state.ComboIndex,
        ComboExpiresAt = state.ComboExpiresAt,
        Token = state.Token,
        Action = state.Action,
        ActiveFrom = state.ActiveFrom,
        ActiveUntil = state.ActiveUntil,
        Essence = state.Essence,
    })
end

function State.Get(character)
    return snapshot(get(character))
end

function State.Cleanup(character)
    states[character] = nil
end

function State.CanRequest(character, now)
    local state = get(character)
    if now - state.LastRequest < Config.MaxRequestRate then
        return false, "Request rate exceeded"
    end
    state.LastRequest = now
    return true
end

function State.ResetMovement(character)
    Movement.Reset(character)
end

function State.UpdateMovement(character, now)
    return Movement.Validate(character, now)
end

local function disabled(character)
    return character:GetAttribute("Stunned") == true or character:GetAttribute("Knocked") == true or character:GetAttribute("Dodging") == true or character:GetAttribute("Blocking") == true
end

local function finite(value, minimum, maximum)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge and value >= minimum and value <= maximum
end

local function scheduleGuardExpiry(character, lease)
    task.delay(math.max(0, lease - os.clock()), function()
        local current = states[character]
        if current and current.Guarding and os.clock() >= current.GuardLeaseUntil then
            refreshGuard(current, os.clock())
        end
    end)
end

function State.BeginGuard(character, now)
    local state = get(character)
    refreshGuard(state, now)
    if state.Guarding or state.Action ~= nil or now < state.DisabledUntil or now < state.LockUntil or state.Guard <= 0 or disabled(character) then
        return false
    end
    state.Guarding = true
    state.GuardMode = "Hold"
    state.GuardLeaseUntil = now + 2.25
    scheduleGuardExpiry(character, state.GuardLeaseUntil)
    state.ParryUntil = 0
    return true
end

function State.BeginParry(character, now)
    local state = get(character)
    if not finite(now, 0, math.huge) then
        return false
    end
    refreshGuard(state, now)
    if state.Guarding or state.Action ~= nil or now < state.DisabledUntil or now < state.LockUntil or now < state.ParryReadyAt or state.Guard <= 0 or disabled(character) then
        return false
    end
    state.Guarding = true
    state.GuardMode = "Parry"
    state.GuardLeaseUntil = now + Config.Guard.ParryWindow
    state.ParryUntil = state.GuardLeaseUntil
    state.ParryReadyAt = now + Config.Guard.ParryRearm
    scheduleGuardExpiry(character, state.GuardLeaseUntil)
    return true
end

function State.KeepGuard(character, now)
    local state = get(character)
    refreshGuard(state, now)
    if not finite(now, 0, math.huge) or not state.Guarding or state.GuardMode ~= "Hold" or state.Action ~= nil or now < state.DisabledUntil or disabled(character) then
        State.EndGuard(character, now)
        return false
    end
    state.GuardLeaseUntil = now + 2.25
    scheduleGuardExpiry(character, state.GuardLeaseUntil)
    return true
end

function State.EndGuard(character, now)
    local state = get(character)
    refreshGuard(state, now)
    state.Guarding = false
    state.GuardMode = nil
    state.ParryUntil = 0
    state.GuardLeaseUntil = 0
end

function State.CanAttack(character, now)
    local state = get(character)
    refreshGuard(state, now)
    return state.Action == nil and not state.Guarding and now >= state.DisabledUntil and now >= state.LockUntil and not disabled(character)
end

function State.BeginAttack(character, kind, weapon, now)
    local state = get(character)
    if not State.CanAttack(character, now) then
        return nil, "Busy or disabled"
    end
    local definition
    local combo
    if kind == "Light" then
        if now < state.LightUntil then
            return nil, "Light cooldown"
        end
        local nextCombo = now > state.ComboExpiresAt and 1 or state.ComboIndex % #weapon.Light + 1
        combo = nextCombo
        definition = weapon.Light[nextCombo]
        state.LightUntil = now + definition.Cooldown
        state.ComboIndex = nextCombo
        state.ComboExpiresAt = now + weapon.ComboReset
    elseif kind == "Heavy" then
        if now < state.HeavyUntil then
            return nil, "Heavy cooldown"
        end
        definition = weapon.Heavy
        state.HeavyUntil = now + definition.Cooldown
        state.ComboIndex = 0
        state.ComboExpiresAt = 0
    else
        return nil, "Invalid attack"
    end
    state.Token += 1
    local token = state.Token
    state.Action = kind
    state.RequestedAt = now
    state.Recovery = definition.Recovery
    local plannedStart = now + definition.Windup
    local plannedEnd = plannedStart + definition.Active
    state.ActiveFrom = math.huge
    state.ActiveUntil = 0
    state.LockUntil = plannedEnd + definition.Recovery + Config.AnimationMarkerGrace
    return table.freeze({ Definition = definition, Token = token, Combo = combo or 0, StartsAt = plannedStart, EndsAt = plannedEnd }), nil
end

function State.IsCurrent(character, token, now)
    local state = get(character)
    return state.Token == token and state.Action ~= nil and not state.Guarding and now >= state.DisabledUntil and not disabled(character)
end

function State.SetActiveWindow(character, token, startTime, duration)
    local state = get(character)
    if not finite(startTime, 0, math.huge) or not finite(duration, 0.01, Config.MaxAttackLifetime) or state.Token ~= token or state.Action == nil or startTime > state.RequestedAt + Config.MaxAttackLifetime - duration - state.Recovery then
        return false
    end
    state.ActiveFrom = startTime
    state.ActiveUntil = startTime + duration
    state.LockUntil = math.max(state.LockUntil, state.ActiveUntil + state.Recovery)
    return true
end

function State.EndActiveWindow(character, token, now)
    local state = get(character)
    if state.Token == token then
        state.ActiveUntil = math.min(state.ActiveUntil, now)
    end
end

function State.IsActive(character, now)
    local state = get(character)
    return state.Action ~= nil and not state.Guarding and now >= state.ActiveFrom and now <= state.ActiveUntil and now >= state.DisabledUntil and not disabled(character)
end

function State.CompleteAttack(character, token)
    local state = get(character)
    if state.Token == token then
        state.Action = nil
        state.ActiveFrom = math.huge
        state.ActiveUntil = 0
        return true
    end
    return false
end

function State.AbortAttack(character, token)
    local state = get(character)
    if state.Token ~= token then
        return false
    end
    state.Token += 1
    state.Action = nil
    state.ActiveFrom = math.huge
    state.ActiveUntil = 0
    state.ComboIndex = 0
    state.ComboExpiresAt = 0
    return true
end

function State.Interrupt(character, untilTime)
    local state = get(character)
    state.Token += 1
    state.Action = nil
    state.ActiveUntil = 0
    state.LockUntil = math.max(state.LockUntil, untilTime)
    state.DisabledUntil = math.max(state.DisabledUntil, untilTime)
    state.Guarding = false
    state.GuardMode = nil
    state.ParryUntil = 0
    state.GuardLeaseUntil = 0
    state.ComboIndex = 0
    state.ComboExpiresAt = 0
end

local function essence(state, character)
    if state.Essence == nil then
        local value = character:GetAttribute("Essence")
        if type(value) ~= "number" or value ~= value or math.abs(value) == math.huge then
            value = 0
        end
        state.Essence = math.clamp(value, 0, 100000)
    end
    return state.Essence
end

function State.SetEssence(character, amount)
    assert(type(amount) == "number" and amount == amount and amount >= 0 and amount <= 100000)
    local state = get(character)
    state.Essence = amount
    character:SetAttribute("Essence", amount)
end

function State.GetEssence(character)
    return essence(get(character), character)
end

function State.BeginAbility(character, duration, cost, now)
    local state = get(character)
    if not finite(duration, 0.1, 10) or not finite(cost, 0, 100000) or not finite(now, 0, math.huge) then
        return nil, "Invalid ability parameters"
    end
    if not State.CanAttack(character, now) then
        return nil, "Action locked"
    end
    if essence(state, character) < cost then
        return nil, "Insufficient Essence"
    end
    state.Essence -= cost
    character:SetAttribute("Essence", state.Essence)
    state.Token += 1
    state.Action = "Ability"
    state.RequestedAt = now
    state.Recovery = 0
    state.ActiveFrom = math.huge
    state.ActiveUntil = 0
    state.LockUntil = now + duration
    return state.Token
end

function State.OpenAbilityWindow(character, token, now, duration)
    local state = get(character)
    if not finite(now, 0, math.huge) or not finite(duration, 0.01, 0.5) or not State.IsAbilityCurrent(character, token, now) or state.ActiveFrom ~= math.huge or now + duration > state.LockUntil then
        return false
    end
    state.ActiveFrom = now
    state.ActiveUntil = now + duration
    return true
end

function State.IsAbilityCurrent(character, token, now)
    local state = get(character)
    return state.Token == token and state.Action == "Ability" and now >= state.DisabledUntil and character:GetAttribute("Stunned") ~= true and character:GetAttribute("Knocked") ~= true and character:GetAttribute("Dodging") ~= true and character:GetAttribute("Blocking") ~= true
end

function State.EndAbility(character, token, now, recovery)
    local state = get(character)
    if state.Token ~= token or state.Action ~= "Ability" then
        return false
    end
    state.Token += 1
    state.Action = nil
    state.ActiveFrom = math.huge
    state.ActiveUntil = 0
    if not finite(recovery, 0, 5) then
        recovery = 0
    end
    state.LockUntil = math.max(state.DisabledUntil, now + recovery)
    return true
end

function State.RefundEssence(character, amount)
    if not finite(amount, 0, 100000) then
        return false
    end
    local state = get(character)
    state.Essence = math.min(100000, essence(state, character) + amount)
    character:SetAttribute("Essence", state.Essence)
    return true
end

function State.Defense(character, now)
    local state = get(character)
    refreshGuard(state, now)
    return snapshot(state)
end

function State.DrainGuard(character, amount, now)
    local state = get(character)
    refreshGuard(state, now)
    state.Guard = math.max(0, state.Guard - amount)
    if state.Guard <= 0 then
        State.Interrupt(character, now + Config.Guard.BreakStun)
        return true
    end
    return false
end

return State
