# Server-side combat system

## Files

Place `CombatServer.server.luau` as a server Script under a dedicated folder in ServerScriptService. Place `CombatConfig`, `CombatState`, `CombatPolicy`, `CombatResolver`, `CombatHitboxService`, and `CombatZoneConsequences` in that same folder as ModuleScripts with the exact names shown. `CombatSmokeTests.luau` is a separate test Script that can be run manually in a test place.

The original `AbilityRunner`, `InventoryService`, `NPCTargetSelector`, and `DeltaReplicator` remain separate demonstrations and do not need to be installed for combat.

## Server weapon setup

Equip a server-provisioned Tool tagged `CombatWeapon` using CollectionService. Set its server-owned `CombatWeaponId` attribute to `TrainingSword`, which is the provided example profile. Define additional weapons only in `CombatConfig`. Damage, range, combo stage, recovery and cooldown are selected on the server, never supplied by the client.

For animated weapons, add a `CombatAnimations` folder containing Animation instances named `Light1`, `Light2`, `Light3` and `Heavy`. Put `HitStart` and `HitEnd` markers in each track. The server plays these animations and honors their hit windows. If there is no `CombatAnimations` folder, the server uses the configured windup and active durations. If a folder exists but its required animation or markers are missing, that action cannot produce a hit. The gameplay animation asset must be authorized for the experience.

## Networking

`CombatServer.server.luau` creates `ReplicatedStorage.CombatNet.Action`. The client requests only `"Light"`, `"Heavy"`, `"GuardStart"`, or `"GuardEnd"` using `FireServer`. The server validates the player's live character, server-equipped weapon, movement, action state, cooldown and combo progression. Successful attacks produce `AttackStarted` notifications for synchronized visual feedback. Guard state changes produce `GuardChanged`. Rejections are returned to the requesting player. No client-provided hit targets, damage, range, timestamps or stage numbers are trusted.

## Combat policy

Tag anchored region Parts as `CombatZone` and set their `ZoneType` attribute to `Safe`, `Yellow`, `Red` or `Dark`. The most protective overlapping volume takes priority. PvP is denied in safe zones or outside configured zones. Yellow requires server-set `PvPEnabled` on both players; Red and Dark allow combat between opposing teams. An equipped attacker must always pass this policy before a player receives damage. Tag eligible enemy character Models `CombatNPC`; untagged non-player models cannot be hit. Use `CombatFaction` on Models to disable friendly fire between NPC factions.

`CombatZoneConsequences` demonstrates separate server-owned combat flags for Yellow, Red and Dark. The provided durations are examples, not claims about Soul Seas' actual reputation, bounty, bounty-loss or criminality rules. Customize this single adapter to match those rules before deployment. External stuns, knockdowns, blocks and dodges should update the server state or trusted character attributes. Call `CombatState.ResetMovement` after a server-approved teleport to avoid treating it as exploit-like displacement.

## Hit detection and performance

The server samples hitboxes only during active attack windows. Each swing shares a deduplication map and cumulative target limit. A box beginning at the root has a front edge at the configured Reach, not Reach plus a hidden offset. Targets are sorted by distance so dense crowds are not biased by part enumeration order. Per-target Euclidean distance and a wall raycast supplement the overlap query. Candidate queries do not truncate the first 128 parts. No permanent global Heartbeat loop runs when no attack is active.

Configure collision groups and character body/hurtbox parts appropriately. Complex boss rigs may require an adjusted size allowance or dedicated hurtboxes. The script cannot guarantee protection from every client movement exploit; integrate your game's movement authority and auditing. Profile performance using Roblox's MicroProfiler under high NPC density and network latency before adopting the values in production.

## Verification

Run `CombatSmokeTests.luau` as a test Script in Studio. Then test the following manually: no weapon, malformed client requests, missing and interrupted animations, no zone, safe zones, Yellow without opt-in, Red/Dark with allowed PvP, team damage prevention, NPC tags, blocking from the front and back, parry timing, guardbreak recovery, clashes, hitboxes blocked by walls, crowded target selection, rapid Light/Heavy alternating, and respawn cleanup. Add automated integration tests using actual Players, replicated movement and animation assets in your own test place.
