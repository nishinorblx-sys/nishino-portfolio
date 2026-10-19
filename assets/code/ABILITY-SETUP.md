# Foallow Ability Lifecycle and Shared Combat Integration

## Installation

Install `AbilityRunner`, `AbilityDefinitions`, `CombatState`, `CombatMovementGuard`, `CombatResolver`, `CombatPolicy`, `CombatConfig`, and `CombatHurtboxIndex` as ModuleScripts in a server-only `Combat` folder. Install `AbilityServer.server.luau` as a Script in that same folder. Keep the existing combat server entry point and dependencies installed. Run `AbilityStateTests.luau` as a separate temporary Studio test Script. Optionally run `AbilityIntegrationTests.server.luau` during a Play Solo Studio session; it is guarded by `RunService:IsStudio()` and must not be shipped enabled in production.

Clients invoke `ReplicatedStorage.AbilityNet.Request:FireServer("EmberStrike")` or `:FireServer("Focus")`. The client supplies only an allowlisted ability name. It never sends damage, targets, positions, resource totals, hit times, or weapon IDs. Server registration and the weapon configuration are authoritative. `AbilityServer.server.luau` initializes Essence to 100 in this standalone example. Replace that initialization with your server-owned progression/Essence service when integrating into a real game.

## Ownership and lifecycle

`CombatState` is the single gate for combat actions, guard requests and abilities. It rejects overlapping actions rather than accidentally allowing them by ability name. It owns a character action token, status restrictions, recovery and the server-side Essence balance. `AbilityRunner` stores cooldowns per Player, so respawning does not clear an ability cooldown. No client attribute is accepted as a trusted resource update. MovementGuard continuously samples trusted server positions, and ability execution no longer resets movement validation when it starts.

`State.BeginAbility` reserves Essence and an action token before the registered `Run` callback is invoked. `context:Commit()` marks that the ability actually began and charges cooldown. `Run` must register any cleanup handlers before starting externally visible effects and return promptly. Every subsequent timer and signal callback checks that the original character, token, weapon requirement, status, and duration are still valid. The ability remains active after `Run` returns, until `Complete`, `Cancel`, interruption, death, unequip or the duration deadline. A shared temporary Heartbeat checks the active contexts and disconnects when there are none.

Before commit, any failure cancels the context and refunds the reserved Essence without starting cooldown. After commit, an error or interruption stops the context and invokes registered cleanups but keeps the spent Essence and cooldown. This is a deliberate non-refundable-start policy. Change it explicitly if your design refunds a cancelled ability. External game mutations are not transactionally rolled back unless their owner registers compensating cleanup handlers. A hit or damage already applied is not automatically undone.

`context:After(seconds, callback)` and `context:Connect(signal, callback)` wrap callbacks in protected calls. Both invalidate work on cancellation. `context:OnCleanup(fn)` runs cleanup in reverse registration order. Abilities should not create untracked delayed tasks, unmanaged status effects, or local combat rule paths. The example `EmberStrike` opens a bounded active window, calls `context:Hit`, and completes after recovery; `Focus` demonstrates a different ability using the same global action gate.

## PvP and damage integration

`context:Hit(targetModel)` accepts a server-selected target only while the ability has an active hit window. It checks range, facing, line of sight and target validity, then calls the shared `CombatResolver.Apply`. This is the same resolver used by normal attacks, so parry, clash, guard meter, guardbreak, safe zones, Yellow-zone opt-in, and server-owned PvP consequences are not duplicated. Every ability definition owns its damage and reach; the client never supplies them. The sample area scan filters to registered character roots; its actual density must still be profiled under realistic loads.

## Test cases

Use `AbilityStateTests.luau` to validate shared action exclusion, Essence reservation, hit-window exclusivity, recovery and interruption tokens. The optional `AbilityIntegrationTests.server.luau` executes the real runner against a Studio player to exercise failures before and after commit, active locks and cooldown persistence. It has not been run here. Then test with at least two real Studio clients, both with the configured weapon and zone volumes:

1. Activate `EmberStrike` and immediately request `Focus`, Light, Heavy and GuardStart. All competing actions must be denied until the first ability completes and recovery ends.
2. Spam the Ability RemoteEvent, send non-string names, unknown names, extra arguments and rapidly switch ability IDs. Cooldown and global action ownership must remain server-authoritative.
3. Trigger stun, knockdown, death, respawn or weapon unequip during windup and during the active window. No old hit may occur after cancellation, and tracked resources/connections must be released.
4. Break an initialization callback before it commits. Essence must be refunded and cooldown must remain ready. Break an asynchronous callback after commit. Essence/cooldown remain charged, cleanup runs and the action lock must release.
5. Test two concurrent attackers and defenders in Safe, Yellow, Red and Dark zones. Verify parry, clash, guardbreak and PvP flags using the shared resolver rather than implementing those rules inside ability callbacks.
6. Profile ability scan cost, timers, network spam and cleanup under 20 or more moving targets with Studio MicroProfiler. Do not infer performance ratings from source inspection.

This package includes deterministic state tests and source for the server request path. Actual Luau execution, multi-client integration, PvP gameplay and latency benchmarks have not been performed in this environment.
