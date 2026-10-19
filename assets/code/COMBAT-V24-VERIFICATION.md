# Foallow Combat V24: Review Corrections and Evidence Plan

## What was corrected

- Movement tolerance is a finite reserve that regenerates gradually instead of being replenished at each Heartbeat. Impulse distance is also consumed after each accepted movement sample. Server-authorized impulses can optionally supply a direction; movement outside that direction cannot freely use the extra budget.
- The movement tracker retains a pending server-authorized teleport until arrival or expiry. An ordinary movement sample no longer discards the authorization before the teleport occurs. Rejected positions never become the trusted baseline, and the server attempts to restore the accepted CFrame.
- CombatSmokeTests and CombatRegressionTests now track all created fixtures and clean them up after failures, as well as after success. Character fixtures have Humanoid and HumanoidRootPart, live Workspace parents and the CombatNPC tag.
- CombatPvPIntegrationTests uses two real Studio clients placed within melee range in an isolated test location. It calls CombatResolver.Apply for hit, block, parry, clash, guardbreak, Safe-zone rejection and Yellow-zone opt-out, verifies separate two-sided flags for each case, and restores characters and temporary zones after a failure.
- CombatHitboxService has a server-only RequestNPC entry point that follows the same shared attack-window, indexed hitbox, target visibility and resolver pipeline as player attacks. It never accepts client-provided target identities or damage values.
- CombatLoadProfiler creates 1, 5, 10 and 20 NPC attackers with increasing tagged targets, exercises live timed attack contexts, and measures actual scans, queries, raycasts, resolutions, accepted/rejected requests, faults, mean and p95 scan time, and server Heartbeat p95. When Studio players are present, up to two may be temporarily included as target fixtures. Test characters and gravity are restored after each run.

## How to run

1. In an isolated Roblox Studio test place, install the ModuleScripts described in COMBAT-SETUP.md. Names of ModuleScript instances must omit the `.luau` filename suffix.
2. Run CombatMovementBudgetTests and CombatSmokeTests from server Scripts. Save the full Output window. These are isolated state and movement tests, not full network tests.
3. Run CombatRegressionTests.server.luau in a clean server session. Save assertions and Output logs.
4. Start a separate isolated **two-player** local Studio session, and run CombatPvPIntegrationTests.server.luau. The test temporarily moves the two tester characters to an isolated 25,000-stud altitude arena, anchors their roots, suspends defender spawn protection, and restores original state. Do not run this against a production game or other active gameplay scripts.
5. In another isolated Studio session, run CombatLoadProfiler.server.luau. This uses real server-side NPC attack requests, temporarily sets gravity to zero, optionally includes up to two local Studio players as targets, and restores everything after the run. Capture Output logs plus MicroProfiler traces.
6. Separately test movement thresholds under real jumping, dash, geppo, knockback, moving-platform, teleport and simulated latency workloads. Integrate the authorization API into each actual server movement mechanic. Do not loosen anti-teleport rules solely to make a failing test pass.
7. Manually reproduce missing animation assets/markers, early stop, unequip, parry/clash overlap, guard release while stunned and under request floods, respawn, team/faction checks and safe-zone changes.

## Review evidence and known limits

| Evidence | Status in this package |
| --- | --- |
| Source files and module references | Included; static checks run |
| Server movement budget tests | Included; **not executed in Roblox Studio here** |
| Smoke and regression suites | Included; **not executed in Roblox Studio here** |
| Full resolver PvP integration cases | Included; **not executed in Roblox Studio here** |
| Multi-NPC combat profiling harness | Included; **no measured Studio values available** |
| Studio Output logs | **Pending actual run** |
| MicroProfiler screenshot and load results | **Pending actual run** |
| Production sign-off | **Not granted** |

Do not show expected log lines as observed results. Record the precise output, Studio environment, date, concurrent player count and any failed assertions when tests are actually run. A 9/10 score must come from an evaluator reviewing passing tests and observed performance, not merely from having these test scripts present.
