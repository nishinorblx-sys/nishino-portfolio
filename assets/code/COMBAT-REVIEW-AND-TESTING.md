# Combat architecture decisions and verification plan

## Fixed failure paths

- CombatMovementGuard tracks each character from spawn and samples movement independently of requests. CombatMovementBudget enforces a finite speed allowance, regenerating tolerance and one-time consumable impulse distance. Suspicious movement never advances the accepted baseline. The server restores the accepted CFrame, temporarily owns the root assembly where supported, and quarantines combat briefly. CombatPolicy uses the trusted position rather than the currently untrusted root location for zones. Server scripts must explicitly authorize teleports and impulse distance.
- GuardEnd is processed before movement validation or rate limiting. GuardKeepAlive renews a 2.25-second lease, while an abandoned guard expires. M2 triggers a separate short parry action; F holds ordinary guard. Both actions respect stun, dodge, knockdown and shared action locks.
- PvP takes the highest-severity valid zone for consequences when both players are in combat-allowed zones: Dark overrides Red and Red overrides Yellow; Safe blocks PvP. Both participants receive combat flags. NPC-versus-player fights pass the same authorization function but do not mark a PvP attacker flag.
- CombatPolicy.RecordConsequence is invoked before hit, block, guardbreak, parry, or clash resolution. If the consequence handler fails, player-on-player resolution is denied. Every combat action uses CombatResolver.
- Guardbreak overflow applies the same damage multiplier as normal hits.
- Every active melee context is separately error-isolated; a failed scan aborts its own attack and disconnects marker connections, while other attackers continue.
- AbilityRunner reserves Essence and shared action ownership, commits cooldown only on activation, invalidates timers/callbacks on cancellation, and uses CombatResolver for damage. Invalid durations and resource costs are rejected within CombatState.

## Intended product rules

- PvP is available only in eligible zone volumes for player-versus-player encounters. Yellow requires both users to opt in. A Safe-zone participant cannot attack or be attacked, including by NPCs.
- The more dangerous participant's zone determines combat-flag length: Yellow 12 seconds, Red 35 seconds, Dark 50 seconds. Both users receive a flag on a valid interaction, even if it ends in a parry or clash.
- Validated NPC models can attack players and NPCs using the same combat permissions and resolver. The NPC AI scheduler and navigation controller are still separate.
- The server retains a failed or interrupted attack's committed cooldown; it prevents client retry spam. An ability that fails before explicit Commit refunds its reserved Essence. Once committed, cleanup runs but Essence and cooldown remain spent.

## Studio setup

Install the ModuleScripts in ServerScriptService/Combat, including CombatMovementBudget and CombatMovementGuard. Run CombatServer.server.luau as a Script in that folder. Place CombatClientInput.client.luau as a LocalScript in StarterPlayerScripts for manual input: Mouse1 Light, Mouse2 Parry, G Heavy, F held Guard. Server-issued Tools must be tagged CombatWeapon with CombatWeaponId set to a configured ID. Tagged CombatNPC Models require Humanoid and HumanoidRootPart. CombatZone-tagged BaseParts require ZoneType Safe, Yellow, Red or Dark.

For server-driven teleports call Movement.AuthorizeTeleport(character, destination, radius, 0.5) before repositioning. For scripted knockback call Movement.AuthorizeImpulse(character, distanceBudget, duration) before applying force. These APIs must never be exposed as client-provided movement exemptions. Make sure legitimate scripted movement systems use explicit allowances, otherwise they can be denied.

## Executable checks

1. Run CombatMovementBudgetTests and CombatSmokeTests as Studio test Scripts for bounded movement, finite impulse distance, five-hit and four-hit weapon combos, timed windows and read-only state snapshots.
2. Run CombatRegressionTests.server.luau in a test place to check the actual CombatResolver against NPC dummies, plus rejected movement baselines, authorized teleport, guard/parry, guardbreak and multiplier validation.
3. Run CombatPvPIntegrationTests.server.luau with at least two Studio players in an isolated place. Confirm both players receive flags on authorized Red-versus-Dark combat, and Safe-zone interactions are rejected.
4. Run AbilityIntegrationTests.server.luau for pre-commit refunds, post-commit cleanup, ability exclusion and cooldowns.
5. Run InventoryConsistencyTests.server.luau to verify that multi-item updates are atomic, replay requests are not double-charged, stale versions fail, and failed transactions leave state unchanged.
6. Run CombatLoadProfiler.server.luau with Studio clients and nearby tagged NPCs. It exercises live attacks and reports accepted requests, scans, overlap queries, rays, resolved hits, failures, average and p95 processing cost. Client counts that are not available are explicitly skipped. Capture MicroProfiler frames and network latency separately before making performance claims.

## Additional release gates

Test missing/early/late animation markers, invalid Animator, cancellation and unequip during hit windows; guard release when anchored, seated and moving rapidly; guard lease expiry after client disconnect; clashes, parries and all PvP zone combinations; authorized knockback versus unauthorized teleport; NPCs in and outside Safe zones; remote spam; respawn and prolonged server stalls. Record server logs, test outcomes and frame-time samples.

This implementation has not been run in Roblox Studio in this environment. Static code and path checks cannot establish an 8/10 rating or zero bugs. A lead-programmer approval also requires evidence from integration tests, profiling and a live technical review.


For the current comprehensive acceptance criteria, read COMBAT-V23-VERIFICATION.md.
