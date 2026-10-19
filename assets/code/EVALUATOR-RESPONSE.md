# Engineering changes for the latest combat review

## Changes made

**Movement validation** now uses a separate CombatMovementGuard that seeds a trusted root position when the server sees character creation. Continuous server-side samples update that baseline only on valid movement. Rejected movement leaves the trusted position intact. Server-owned teleport and impulse grants permit expected displacement without allowing the client to self-authorize it.

**PvP consequences** are recorded before combat effects across hits, blocks, parries, clashes and guardbreaks. If the consequences handler fails, the player-versus-player action is denied. Both participants are flagged. Zone severity has an explicit rule: Safe blocks everything, then Dark > Red > Yellow for flag duration.

**Guard release** now bypasses request throttling and movement checks. Guarding is lease-based; a missing release cannot leave a character guarding indefinitely once state is refreshed. Beginning or maintaining guard reuses status and action restrictions.

**Resolver failure handling** is isolated per active swing, with cleanup and state invalidation after unexpected exceptions. A bad resolver update cannot leave a single attack indefinitely active or prevent other attack contexts from processing.

**Damage rules** consistently apply the defender multiplier to direct hits and guardbreak overflow. Ability resource inputs are validated even when directly calling the shared state module.

**Other proof systems** include atomic versioned inventory transactions, NPC targeting with line-of-sight and shared permission checks, and versioned delta replication with a client-side snapshot recovery path.

## What this does not prove

Correct source structure does not prove safe remote behavior under high latency, exploit resistance against movement ownership tricks, frame-time budgets during densely populated encounters, or a reliable release build. COMBAT-REVIEW-AND-TESTING.md contains executable test scripts and the remaining Studio release gates. Ratings should be based on running those tests, actual failures found and measured results rather than the number of modules.
