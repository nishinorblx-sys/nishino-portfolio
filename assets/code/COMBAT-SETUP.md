# Foallow: server-side combat architecture

## Install the complete module graph

In `ServerScriptService`, create a folder named `Combat`. Put `CombatServer.server.luau` into it as a Script. Install the following eight files as ModuleScripts, removing the `.luau` extension from their Instance names: `CombatConfig`, `CombatState`, `CombatTimeline`, `CombatHurtboxIndex`, `CombatPolicy`, `CombatResolver`, `CombatHitboxService`, and `CombatZoneConsequences`. The ninth script, `CombatSmokeTests.luau`, is a separate executable Script for Studio testing and should be disabled outside a test place. The server entry point and every dependency are included in this folder and can be viewed on the Proof page.

The other four Proof page modules, `AbilityRunner`, `InventoryService`, `NPCTargetSelector`, and `DeltaReplicator`, are independent examples.

## Server-owned weapons and character tracking

Equip a server-issued Tool with the CollectionService tag `CombatWeapon`, set `CombatWeaponId` to `TrainingSword`, and configure any other weapons exclusively in `CombatConfig`. Client requests never specify damage, hit positions, target models, or timestamps. For NPCs, tag their Model as `CombatNPC` and give them a living Humanoid and a `HumanoidRootPart`. Player character roots are registered automatically. Only registered root parts participate in overlap queries, so limb-heavy rigs and decorative geometry do not create large part result sets. Roots must remain queryable. Collision group and CanQuery settings must be checked in the test place.

The target-root list is rebuilt only after a tracked character changes. Attackers remain excluded by character identity when evaluating candidate roots. The service samples on one shared Heartbeat connection while attacks exist; it disconnects when idle. A swing stores its own seen-target set and cumulative hit cap. Candidates are distance-sorted after the overlap query, so the module does not silently bias its hits toward an arbitrary first-128-parts result. In very dense encounters the number of target roots still matters: profile it under your actual player and NPC density before choosing larger encounter limits.

## Client requests and server rules

`CombatServer.server.luau` creates `ReplicatedStorage.CombatNet.Action`. Clients send only `"Light"`, `"Heavy"`, `"GuardStart"`, and `"GuardEnd"`. The server verifies the live character, equipped Tool tag, configured weapon, movement plausibility, action locks, guard state, combo stage, and cooldowns. It also revalidates weapon and character state while a hit window is pending or active. An attacker who dies, unequips, changes weapon, becomes stunned, or moves implausibly has the pending swing cancelled. Separate attributes for trusted knockdowns, dodges, and stuns must be set by server gameplay systems, not clients.

`CombatPolicy` is the only PvP permission gateway called by `CombatResolver`. Tag anchored regions as `CombatZone` with `ZoneType` set to `Safe`, `Yellow`, `Red`, or `Dark`. PvP is blocked outside eligible zones and when either player is protected. Yellow requires server-issued `PvPEnabled` on both players. Enemy NPCs require the server-issued `CombatNPC` tag. The `CombatZoneConsequences` adapter demonstrates PvP flags; replace those example flags with your actual game rules before deployment. `CombatResolver` owns the parry, clash, guard, guardbreak, and damage decisions. Individual weapons never call `Humanoid:TakeDamage()`.

## Timing, missing markers, and cancellations

The server reserves the swing before requesting an animation and owns all attack timing. If `CombatAnimations` is absent, the action opens at its configured windup. If a folder exists but its animation or Animator is missing, loading fails, or playback cannot start, the same configured fallback is used. Successful animation loading allows a `HitStart` marker within the bounded early/late interval to open the active hitbox; if the marker never arrives, an independent watchdog opens a window at the configured windup plus 90 ms. After the first window opens, late markers cannot open another window. `HitEnd` closes a started window. A stopped track before the first marker still uses the configured fallback if character state remains legal. Combat cancellation via `Combat.Cancel()` or `State.Interrupt()` prevents fallback hits after a stun or unequip.

The animation marker does not allow the client to choose the hitbox timing. The active interval stays bounded by `MaxAttackLifetime`, and the current attack token is checked before every scan. Completion and cancellation both disconnect marker connections and release the active context. Cooldowns and recovery locks are preserved when an attack is cancelled.

AttackStarted replication from the server publishes the nominal window for presentation, not permission to apply damage. When a marker shifts the actual start within the tolerance, the server's damage window remains authoritative. For exact animation synchronization on clients, add a separate server `HitWindowStarted` presentation event with the actual accepted marker time.

## Tests and remaining verification

Run `CombatSmokeTests.luau` as a Script in Studio to check combo locks, pending windows, marker timing decisions, timeout fallback, interruption invalidation, guard state, and NPC permissions. Then run integration tests with real players and configured animations: no animation, missing animation, `LoadAnimation()` failure, missing `HitStart`, early `HitStart`, normal `HitStart`/`HitEnd`, `Stopped` before the first hit, unequip, death, stun, respawn, GuardStart/GuardEnd spam, PvP zones, walls, simultaneous hits, crowded NPCs, and high ping. Verify no duplicates across the fallback and marker paths and no lingering Heartbeat or marker connections.

This source has not been executed inside Roblox Studio or benchmarked under load in this environment. It is an inspectable implementation, not proof of a production-ready lead-programmer candidate or a guaranteed review score.

## V21: Shared ability action state

The combat and ability pipelines now share one `CombatState`. An active ability blocks new Light/Heavy requests and GuardStart until completion or interruption, while an active weapon attack blocks a new ability. The state token invalidates pending ability callbacks after stun, death, character removal or cancellation. Ability hit windows use `CombatResolver.Apply` to preserve the existing PvP, parry, guardbreak and clash rules. Install `AbilityRunner`, `AbilityDefinitions`, `AbilityServer.server.luau` and `AbilityStateTests.luau` beside the combat modules. See `ABILITY-SETUP.md` for resource reservation, commit semantics and tests.
