# Foallow Combat V25 - Verification and Review

## Source-of-truth rule

Evaluate the complete `assets/code` tree from one V25 archive, not files cherry-picked from V19 through V24. `COMBAT-V25-MANIFEST.md` lists the exact current code with SHA-256 hashes. Install all server combat dependencies together. Use `COMBAT-SETUP.md` to identify Roblox Script and ModuleScript placement.

## Exact controls and request path

- Mouse Button 1 sends `Light`, server selects the current weapon's combo index. TrainingSword has 5 light attacks; HeavySword has 4.
- Mouse Button 2 sends `Parry`; `Combat.Request` authorizes `Parry`, then invokes `CombatState.BeginParry`. The combat server broadcasts `ParryStarted` only after acceptance.
- G sends `Heavy`; F sends `GuardStart`, repeated `GuardKeepAlive`, and `GuardEnd` on release.
- The server rejects malformed actions. `GuardKeepAlive` only works for a held guard with an eligible character, authorized weapon and trusted movement. It cannot extend a Parry guard lease. `GuardEnd` remains available regardless of movement or throttling.

## Movement contract

- Normal movement uses `CombatMovementBudget` with finite, gradually regenerated tolerance. It does not award a full fixed slack allowance every Heartbeat.
- Authorized impulses and gradual travel consume a bounded extra-distance allowance and may require a direction. They do not replenish the budget automatically.
- `AuthorizeTeleport(character, destination, radius, ttl)` is **only** for an immediate, server-owned relocation. The destination has to be reached within the authorized radius and deadline. An incomplete tween does not inherit a teleport exemption. For gradual movement call `AuthorizeTravel` before starting the movement, with a finite total distance, duration and direction.
- Rejected movement retains the last accepted location, attempts server-side correction and temporarily quarantines the character. PvP zone selection uses tracked trusted coordinates rather than an invalid root position.

## What the profiler measures

`CombatHitboxService.Diagnostics` reports scan CPU time (the overlap query, candidate selection, raycasts and resolver) and per-attack Heartbeat processing CPU time (step validation, scan, state transitions and attack cleanup). `CombatLoadProfiler.server.luau` prints `avgSample`, `p95Sample`, `avgProcessing`, `p95Processing`, `totalProcessing`, and `p95HeartbeatInterval`. The last value is **not** combat CPU time. Values are measured with `os.clock` inside the real processing path.

The profiler creates server-owned NPCs for four load scenarios (1/1, 5/10, 10/25 and 20/50 attackers/targets) and may include live Studio players. It requires actual accepted requests, query samples, target resolutions and zero internal faults. CPU timings here exclude renderer, network transfer and client effects, so real network/multiplayer performance remains to be measured separately.

## Studio tests and reproducible evidence

1. Use a clean isolated Studio place and install all V25 modules per `COMBAT-SETUP.md`.
2. Run `CombatMovementBudgetTests.luau`, `CombatSmokeTests.luau`, and `CombatRegressionTests.server.luau` with test entities and cleanup enabled.
3. Run `CombatPvPIntegrationTests.server.luau` with two actual Studio players. Record hit, block, parry, clash, guardbreak, safe-zone rejection, cooldown, PvP flag and interruption results.
4. Run the opt-in `CombatLiveE2E.server.luau` + `CombatLiveE2E.client.luau` pair with one Studio player. Set the Workspace attribute `FoallowRunE2E` to `true` before starting. This sends real RemoteEvents and observes server acceptance plus NPC damage. It programmatically exercises the network input path; a manual M1/M2/G/F control test is still required.
5. Run `CombatLoadProfiler.server.luau` on an isolated server, record each scenario's actual output and MicroProfiler traces, and repeat under realistic latency and concurrent ability load.
6. Reproduce stun, death, respawn, unequip, missing markers, mid-attack cancellation, old-token rejection, invalid safe-zone movement and authorized dash/teleport recovery. Fix any failures and preserve regression cases.

## Verification status at packaging time

- ZIP/source-path and version-manifest consistency: static audit completed.
- JavaScript parsing (`node --check`): completed.
- Roblox Studio execution of the Luau tests: **not run here**.
- Recorded pass/fail output from Studio: **not available**.
- Real multiplayer profiling and lead-level evaluation: **pending**.

Do not present these scripts as benchmark-proven or guaranteed to pass a senior programmer evaluation. The next review should be based on one synchronized source set plus actual Studio test and profiler output.
