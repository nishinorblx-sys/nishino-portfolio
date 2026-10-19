# Combat and Ability Code Review Response

## 1. Why the original animation failure happened

The earlier combat implementation used the result of `startAnimationWindow()` to decide whether a scheduled hitbox fallback should run. It conflated “the animation setup function returned” with “an animation marker will actually open a hit window.” Missing animation assets, failed loads or missing `HitStart` markers could therefore consume an attack without creating a hitbox.

The updated design does not depend on animation success to schedule hits. `Combat.Request()` reserves one server-owned action token and creates a `CombatTimeline` with a fallback deadline before loading the animation. `CombatHitboxService.attachAnimation()` may shorten the fallback when assets are missing or playback fails. A valid `HitStart` marker can open the window early within bounded tolerance; otherwise, Heartbeat opens the watchdog fallback. `CombatTimeline.TryOpen()` is single-use. A later marker cannot open a second window.

The same context checks the current token, living character, equipped Tool, status locks and movement plausibility. Interruptions invalidate the token and release marker connections, so delayed callbacks cannot apply damage. Recovery and cooldowns are owned by the state service, not by animation playback. Animation asset failures use an explicit fallback policy; unauthorized or invalid player actions are rejected before any context is constructed.

## 2. Combat decisions have one authoritative owner

`CombatState` owns action locks, M1/M2 sequencing, guard meter, parry timing, recovery and interruption tokens. `CombatPolicy.Authorize()` enforces eligible PvP zones, opt-in and target restrictions. `CombatResolver.Apply()` routes authorized hits through parries, clashes, blocking, guardbreaks, damage modifiers and server-owned PvP consequences. The server event adapter accepts only approved action names. Weapons and abilities cannot provide client-chosen damage values or skip policy checks through the documented public APIs.

A weapon attack and an ability request share the same `CombatState` action slot, so one cannot start while the other is active. A committed ability owns an explicit hit window and routes `context:Hit()` through the same resolver. Changing weapons, dying, receiving stun, or removing the character invalidates the action. Effects outside the registered context must implement their own cleanup and remain a separate review concern.

## 3. Why callback return does not finish an ability

The earlier `AbilityRunner` released its lock immediately after `Run()` returned. This allowed animations, hitboxes or other delayed ability effects to remain active while a second ability or normal attack began. The new `AbilityRunner` reserves Essence and a global action token in `CombatState` before invoking `Run()`. `Run()` registers tracked timers, signal connections and cleanup handlers, then calls `context:Commit()` when activation actually begins.

The runner keeps the shared lock until `context:Complete()`, `context:Cancel()`, stun, knockdown, death, respawn, weapon unequip or the maximum duration deadline. Delayed work checks token ownership and status before executing. The runner does not permit accidental cross-ability concurrency; simultaneous abilities would require an explicit, separately reviewed rule.

## 4. Failure, resource and cooldown policy

Before `Commit`, an initialization error cancels the action, refunds reserved Essence and leaves cooldown available. After `Commit`, errors cancel tracked work and call registered cleanup handlers but retain the spent Essence and cooldown. This policy prevents repeatable free attempted activations; a different design can choose a refund policy explicitly. A cleanup callback can reverse temporary status effects or resources owned by that ability, but damage already dealt and untracked external effects are not automatically transactional.

`AbilityDefinitions` demonstrates `EmberStrike`, which opens a server hit window and resolves damage centrally, and `Focus`, which registers cleanup before setting its temporary status. `AbilityServer.server.luau` shows bounded RemoteEvent inputs and server-side ability registration.

## 5. Evidence and remaining validation

The full dependency graph, server event adapters, state tests, ability definitions and code viewers are included. `CombatSmokeTests` and `AbilityStateTests` assert isolated state rules. `AbilityIntegrationTests.server.luau` is an optional Studio-only integration harness testing a real Player, including rejection of simultaneous abilities and pre-/post-commit failures. The integration tests have **not** been run here.

Soul Seas-specific PvP consequence policy, real weapon/animation assets, knockback allowances, collision groups, high-latency timelines, race conditions, profiling in crowded fights and server load still require in-Studio verification before a production-readiness rating can be justified. No numeric score is claimed from source inspection alone.
