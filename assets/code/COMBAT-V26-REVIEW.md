# Foallow Combat V26: Window Sampling, Position Trust and Diagnostics

## Attacks and hit-window policy

HitStart is accepted only inside the configured tolerance; otherwise the server fallback opens the window. The window opens at most once. The first hitbox scan runs immediately on opening. Normal sampling retains the fractional remainder across Heartbeats and executes at most one scan per server frame, even when several intervals elapse. The scheduler counts skipped intervals instead of replaying old scans against the current position.

The configured active duration controls window expiry. An early HitEnd marker never closes the window prematurely. If the animation itself stops before the active interval ends, the attack is aborted and its work invalidated. A final scan is permitted only once, and only within 40 ms of expiry and only if no recent sample has occurred. An excessively late server frame skips the final scan rather than giving the attack an unbounded extension. Already resolved targets stay deduplicated across the whole attack.

## Spatial authority and geometry

Both attacker and defender must pass the same movement validation before resolution. The current root position must remain within 0.6 studs of its server-accepted position. Zone policy reads those accepted positions; any quarantined, invalid or missing position rejects the hit.

Attack definitions own hitbox yaw and offsets, with bounded optional midpoint sweep queries on fast movement. This models swing orientation without running a mesh-level physics simulation. Only a maximum of two overlap queries can run per sample. Weapon-accurate mesh intersection remains a separate playtesting task.

## Metrics and faults

Hits and DamagingHits count successful damage events. Contacts counts all resolved contacts, including guards, parries and clashes. Other counters report rejected interactions, animation fallbacks, skipped samples, late-frame omissions and unexpected errors. Individual attack-context CPU times are reported separately from the complete combat Heartbeat callback's CPU time. Heartbeat interval is not used as a proxy for combat CPU.

## Local verification checklist

Run CombatWindowSchedulerTests in Studio. Compare low and high frame rates with ordinary attacks, slow attacks and dash attacks. Test early, late, missing and duplicated animation markers, animation stoppage, character death, respawn, unequipping, stuns, repeated inputs and zone-boundary movement. Validate a blocked target or invalid defender does not take damage. Run concurrent combat profiling and inspect the new diagnostics separately for damaging hits and other contacts.

These source changes and the bundled test scripts have not been executed inside Roblox Studio by this package builder. Do not present static validation as successful multiplayer or latency testing.
