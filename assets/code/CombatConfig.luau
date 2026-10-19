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
        attack(12, 16, 5.2, 4.2, 0.14, 0.14, 0.2, 0.38, 3),
        attack(13, 18, 5.2, 4.2, 0.16, 0.16, 0.22, 0.4, 4),
        attack(18, 26, 5.4, 4.4, 0.18, 0.19, 0.36, 0.55, 4),
    }),
    Heavy = attack(25, 39, 6.5, 5, 0.32, 0.2, 0.48, 1.15, 5),
})

local HeavySword = table.freeze({
    ComboReset = 1.2,
    Light = table.freeze({
        attack(17, 21, 5.5, 4.6, 0.22, 0.17, 0.26, 0.44, 3),
        attack(18, 22, 5.5, 4.6, 0.24, 0.18, 0.27, 0.46, 3),
        attack(20, 25, 5.8, 4.8, 0.26, 0.18, 0.3, 0.49, 4),
        attack(26, 34, 6, 5, 0.32, 0.2, 0.4, 0.64, 4),
    }),
    Heavy = attack(35, 48, 7, 5.5, 0.42, 0.22, 0.52, 1.3, 5),
})

local Config = {
    Weapons = table.freeze({ TrainingSword = TrainingSword, HeavySword = HeavySword }),
    Movement = table.freeze({ MaxSpeed = 72, Tolerance = 2, ToleranceRegen = 0.5, MaxSampleElapsed = 0.25, MaxImpulse = 120, MaxImpulseDuration = 2, MaxTeleportRadius = 32, Quarantine = 0.2, NetworkRecovery = 0.35 }),
    Guard = table.freeze({ Max = 100, Regeneration = 16, ParryWindow = 0.16, ParryRearm = 0.75, BreakStun = 1.25, StunOnParry = 0.9, ClashStun = 0.35, FacingDot = 0.2 }),
    MaxRequestRate = 0.06,
    MaxLinearSpeed = 100,
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
