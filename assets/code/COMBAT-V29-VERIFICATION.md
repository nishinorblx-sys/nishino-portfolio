# Foallow Combat Proof V29: Review and Studio Verification

## What is included

The downloadable combat pipeline contains `CombatHitboxService.luau`, `CombatWindowScheduler.luau`, `CombatSweepPlanner.luau`, `CombatMovementGuard.luau`, `CombatMovementBudget.luau`, `CombatTimeline.luau`, `CombatResolver.luau`, `CombatPolicy.luau`, `CombatState.luau`, the NPC/player hitbox index, combat configuration, the server entrypoint, the client action bindings, test files, and the load profiler. `COMBAT-V29-MANIFEST.md` records the SHA-256 digest of every Luau file in this exact release.

## 1. Scheduling and hit windows

The first scan occurs synchronously when the active server window opens. `CombatWindowScheduler.New()` starts from that opening time. `CombatWindowScheduler.Step()` computes time from its last observed timestamp, retains fractional interval remainder, caps missed catch-up work to one sample on a Heartbeat, reports skipped samples, and closes only once. A late final scan is allowed only when its lateness is within `MaxFinalSampleLateness` and the previous sample was sufficiently old. The client never supplies hit times or contact results.

Run `CombatWindowSchedulerTests.luau` in Roblox Studio. Record the printed output. Check additional short windows with Heartbeat intervals of 1/30, 1/60, 1/120 seconds and a simulated 200ms hitch. Inspect whether valid hit windows remain hittable and already-hit targets remain deduplicated.

## 2. Trusted positions and zone integrity

`CombatMovementGuard.TrustedPosition` revalidates the character through the server-owned movement budget and refuses missing roots, stale measurements, quarantine windows, or unacceptable deviations between actual and accepted positions. Before any resolution, the attacker and defender are both checked. `CombatPolicy.Authorize` uses the same accepted positions when applying Safe/Yellow/Red/Dark zones. A corrected or quarantined defender is not eligible for a damage event until validation succeeds.

Run `CombatMovementTrustTests.server.luau` in an isolated Studio session to test movement correction, quarantine and recovery. Studio test scenarios: player teleports into a Safe zone without server authorization, player exceeds the finite impulse budget, defender is being position-corrected, attacker crosses a zone boundary while swinging, and authorized dashes/knockback remain valid. Confirm damage is rejected during invalid movement without granting unintended PvP protection.

## 3. Swept hitboxes

`CombatSweepPlanner.Plan` returns a bounded number of intermediate segments from both displacement and yaw difference. The hitbox queries the interpolated placements plus the current position, collecting each target once. If the previous and current placement differ by more than `MaxHitboxSweep`, `MaxSweepAnglePerStep * MaxSweepSteps`, or the number of steps allowed, the scan fails closed and the current attack is canceled. It never skips an intermediate query while accepting a clearly unsupported long jump. This is a bounded approximation, not continuous mesh or blade collision.

Run `CombatSweepPlannerTests.luau`. In Studio compare contact accuracy under rapid dashes, 90-degree turns, 30/60/144 FPS and rotation during a server hitch. Review both missed and unexpected hits.

## 4. Animation ownership and cleanup

Animation `HitStart` may open a single server-controlled window only inside the validated marker tolerance. Duplicate markers cannot open a second window. `HitEnd` is recorded but does not move the authoritative end time. The `Stopped` event will not cancel an otherwise valid active attack simply because an asset naturally stops early. The server must use `Combat.Cancel` or `State.Interrupt` when a deliberate stun, weapon swap, or other external interruption should terminate the action. Character death, invalid weapon, lost ownership, and expired tokens also terminate the attack during validation. All animation callbacks are disconnected during `stop` and cannot reopen an older context after it has been replaced.

Test short animation assets, asset load failure, missing/duplicated/early/late markers, animation replacement, weapon removal, respawn, character destruction, server stuns, and rapid action requests.

## 5. Diagnostics and accounting

`Requests`, `Accepted`, and `Rejected` are request-level counts, including failed `State.CanRequest`, guard, parry, and `State.BeginAttack` paths. `RejectedContacts`, `RejectedSweeps`, and `RejectedUntrusted` are separate runtime safety counters. `Contacts` counts successful combat contact resolution, while `DamagingHits` and `Hits` count positive actual damage. `FrameSamples` represent combat Heartbeat execution CPU time, not raw Heartbeat `dt`. Per-context processing and per-scan measurements are also exposed, with average and p95 latency in milliseconds. The test profiler reports the new counters and no fabricated benchmark results.

Run `CombatRequestDiagnosticsTests.server.luau` in an isolated Studio test. Then run the four load scenarios in `CombatLoadProfiler.server.luau`: 1/1, 5/10, 10/25 and 20/50 attackers/targets. Record each scenario's scans, queries, rays, damage, contacts, request rejections, sweep rejections, untrusted positions, faults, p95 combat frame CPU time and p95 scan CPU time. Re-run at least three times in the same device configuration.

## 6. Verification status

The code and linked files can be checked statically outside Studio. No Roblox Studio test output or frame-time profile results have been obtained in this environment. Reviewers should not award performance or production-readiness credit solely because the profiler or test scripts exist. Actual testing of net latency, collision, interrupt ownership and load remains required.
