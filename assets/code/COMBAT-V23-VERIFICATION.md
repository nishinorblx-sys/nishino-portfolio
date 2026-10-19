# Combat V23: Correction and Studio Acceptance Plan

## Source architecture

CombatConfig owns attack timing, five-light TrainingSword combos, four-light HeavySword combos, and movement budgets. CombatMovementBudget performs deterministic finite-distance accounting. CombatMovementGuard samples and corrects server-observed motion. CombatPolicy resolves zones from trusted movement positions. CombatState exposes read-only state snapshots and controlled transitions. CombatHitboxService owns timed attack contexts and instrumentation. CombatResolver governs hits, blocks, parries, clashes, guardbreaks, PvP policy and consequences.

## Gameplay inputs

M1 requests Light. M2 requests Parry. G requests Heavy. F presses GuardStart, refreshes GuardKeepAlive while held, and sends GuardEnd on release. The client never specifies a combo index, successful hit, target, damage, PvP rule or movement exemption. The server validates each request.

## Server-owned movement grants

Call CombatMovementGuard.AuthorizeTeleport(character, destination, radius, ttlSeconds) immediately before a server-controlled teleport. Call CombatMovementGuard.AuthorizeImpulse(character, extraDistance, duration) before a scripted dash or knockback. Impulse distance is consumed rather than being granted again each frame, and each character has a capped tolerance reserve that regenerates slowly. A rejected position never becomes the accepted baseline and the server restores the previously accepted CFrame; a short correction window is applied. Players and NPCs share this tracker. No grant API is exposed through RemoteEvents.

The correction policy is intentionally strict. Integrate gravity, vehicles, moving platforms and legitimate custom movement through explicit server-authorized motion policies, and validate how correction and network ownership behave for your rig under latency.

## Tests to execute in an isolated Studio place

Run CombatMovementBudgetTests as a server Script. It checks sustained 72 studs/s movement, excessive speed, teleport-like jumps, finite impulse exhaustion and consumed tolerance.

Run CombatSmokeTests as a server Script. It checks the five- and four-hit combo definitions, timeline fallback single-use, read-only state snapshots, permissions and parry/guard separation.

Run CombatRegressionTests.server.luau with the modules alongside it. It checks correction to the trusted baseline, safe-zone integrity under untrusted movement, authorized teleport, invalid ability parameters, hit, block, parry and guardbreak with damage modifiers.

Run CombatPvPIntegrationTests.server.luau in an isolated Studio session with at least two players. Spawn them at least 20 studs apart, with no overlapping production CombatZone volumes, and ensure no other production CombatServer or PvP tests modify the same state. The script exercises the real Resolver.Apply pathway for Hit, Blocked, Parried, Clashed, GuardBroken and Forbidden outcomes, and checks combat flagging for both players.

Run CombatLoadProfiler.server.luau in a separate session with 1, 5, 10 and 20 Studio clients when available. It attaches temporary tagged training weapons and indexed NPCs, requests real Light attacks, and reports accepted attacks, scans, overlaps, rays, resolutions, hits, peak contexts, average cost, p95 sample time, and faults. Unsupported client counts print skipped, never fabricated performance data.

Test rapid RemoteEvent spam, bad action types, weapon swap, character respawn, canceled or missing animations, missing HitStart markers, guard release while seated, player knockback, cross-zone PvP and NPC aggression manually in a dedicated test place. Record each failure, its fix, and a repeated successful test.

## Acceptance evidence

A 9/10 quality claim requires a dated Studio run with the complete source and fixtures installed, captured test results, real MicroProfiler traces at multiple player loads, client/server roundtrip measurements under simulated lag, a reproducible security abuse checklist and sign-off on the game's actual zone, input and ability specifications.

No Studio execution, performance capture or production certification is included in this archive. File-level checks alone do not establish a passing acceptance score.
