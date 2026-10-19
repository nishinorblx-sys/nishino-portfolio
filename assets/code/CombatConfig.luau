local function attack(damage, posture, reach, width, windup, active, recovery, cooldown, maxTargets)
    return table.freeze({
        Damage = damage,
        PostureDamage = posture,
        Reach = reach,
        Width = width,
        Height = 5,
        Windup = windup,
        Active = active,
        Recovery = recovery,
        Cooldown = cooldown,
        MaxTargets = maxTargets,
        SampleInterval = 0.05,
    })
end

local TrainingSword = table.freeze({
    ComboReset = 1.05,
    Light = table.freeze({
        attack(10, 14, 5, 4.2, 0.12, 0.14, 0.18, 0.34, 3),
        attack(11, 15, 5, 4.2, 0.13, 0.14, 0.19, 0.36, 3),
        attack(15, 22, 5.4, 4.4, 0.18, 0.17, 0.32, 0.53, 4),
    }),
    Heavy = attack(25, 39, 6.5, 5, 0.32, 0.2, 0.48, 1.15, 5),
})

local Config = {
    Weapons = table.freeze({ TrainingSword = TrainingSword }),
    Guard = table.freeze({ Max = 100, Regeneration = 16, ParryWindow = 0.16, ParryRearm = 0.75, BreakStun = 1.25, StunOnParry = 0.9, ClashStun = 0.35, FacingDot = 0.2 }),
    MaxRequestRate = 0.06,
    MaxLinearSpeed = 100,
    MaxDisplacementSpeed = 72,
    DisplacementAllowance = 7,
    MaxTargetRadiusAllowance = 2.7,
    MaxAttackLifetime = 2.0,
    AnimationMarkerGrace = 0.09,
    AnimationEarlyTolerance = 0.08,
    AnimationLateTolerance = 0.09,
    ZoneTag = "CombatZone",
    WeaponTag = "CombatWeapon",
    NPCTag = "CombatNPC",
}

return table.freeze(Config)
