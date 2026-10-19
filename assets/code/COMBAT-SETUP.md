# Foallow Combat Framework: Installation and Verification

## Module arrangement

In ServerScriptService create a folder named Combat. Install these as server ModuleScripts: CombatConfig, CombatState, CombatMovementBudget, CombatMovementGuard, CombatTimeline, CombatHurtboxIndex, CombatPolicy, CombatZoneConsequences, CombatResolver, CombatHitboxService, AbilityRunner, AbilityDefinitions. Install CombatServer.server.luau and AbilityServer.server.luau as Scripts. Roblox Instance names should omit the .luau extension. StarterPlayerScripts can use CombatClientInput.client.luau as a sample LocalScript.

Tag server-authorized weapons CombatWeapon. Give each Tool a CombatWeaponId attribute matching CombatConfig.Weapons, such as TrainingSword. Add Animation children inside CombatAnimations on each weapon Tool if available. HitStart and HitEnd marker timing is optional; the server timeline owns fallback timing. Player and tagged CombatNPC models need a Humanoid and HumanoidRootPart. Set combat zone parts to the CombatZone tag and set ZoneType to Safe, Yellow, Red or Dark.

M1 triggers Light (five hits with TrainingSword, four with HeavySword), M2 triggers Parry, G triggers Heavy, and F holds guard through GuardStart, GuardKeepAlive and GuardEnd. The game client only sends action names over ReplicatedStorage.CombatNet.Action: Light, Heavy, Parry, GuardStart, GuardKeepAlive and GuardEnd. Light/Heavy actions must pass live-character, equipment, timing, movement and shared-state checks. GuardEnd deliberately bypasses movement restrictions and request throttling. GuardKeepAlive is sent while a guard key remains held and extends the server-side guard lease. If keepalives stop, the lease expires automatically when guard state is refreshed.

## Combat movement and side effects

CombatMovementGuard tracks character roots from spawn and samples positions on the server, not solely on attack requests. A failed movement check does not overwrite the last accepted position. A server-controlled teleport must call Movement.AuthorizeTeleport(character, expectedPosition, toleranceStuds, ttlSeconds) before changing the root transform. A legitimate knockback system must call Movement.AuthorizeImpulse(character, extraDistance, ttlSeconds) before applying it. Do not expose these grants to the client. Moving vehicles, custom movement and lag compensation require integration-specific validation and are not automatically trusted.

CombatResolver calls CombatPolicy to check factions, teams, zone rules and the target type. On player-on-player contact it writes combat consequences before resolution, including when the attack is blocked, parried, clashed or guardbroken. If flagging fails, the player-on-player action is denied. The more dangerous participant zone controls flag length: Yellow 12 seconds, Red 35 seconds, Dark 50 seconds. Safe regions block combat. Both players are combat-flagged by the example consequences adapter. NPC combat uses the same permission pathway but does not apply player-on-player flags.

Health damage is applied in one resolver with the defender's damage multiplier. Guardbreak overflow goes through the same multiplier. State.IsActive and guard creation share stun, knockdown, dodge, blocking and action restrictions. Each melee context has its own protected server update, cancellation tokens, deadline and marker connections so a failure aborts that context instead of leaving a stale attack active.

## Ability integration

AbilityRunner shares CombatState tokens, recovery locks and Essence reservation with melee combat. Server-side registered abilities commit their cooldown when activation actually starts. Before that point the reserved resource is refunded if initialization fails. After commit, failure cancels pending callbacks and invokes registered cleanup, but already-applied damage is not retroactively reversed. AbilityDefinitions includes usage examples; avoid creating untracked timers or effects in registered abilities.

## Studio verification

1. Run CombatSmokeTests as a Studio Script to exercise combo, marker timeline and state transitions.
2. Run CombatRegressionTests.server.luau in an isolated test place to validate rejection baselines, server-authorized teleport, parrying, guardbreak and damage multipliers.
3. Run CombatPvPIntegrationTests.server.luau with at least two Studio players, in a clean test place, to verify mixed Red/Dark zones, Safe restrictions and both combat flags.
4. Run AbilityStateTests.luau and AbilityIntegrationTests.server.luau as test Scripts for ability locks, resource failure policy and interruption cleanup.
5. Run CombatLoadProfiler.server.luau after adding realistic NPC and player counts. Capture MicroProfiler and the console's query durations across several loads and latency settings.
6. Manually test missing animations and markers, weapon unequip, respawn, animation stopped, guard release while seated/anchored, server-authorized dash/knockback and flood attempts.

See COMBAT-REVIEW-AND-TESTING.md for specific rules, failure policies and the release checklist.

The code is not independently Studio-tested or benchmarked here. Production approval requires passing the scripts in a real place and documenting measured outcomes.

See COMBAT-V23-VERIFICATION.md for the current specification, test sequence, expected results, and acceptance evidence.
