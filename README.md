# Foallow, Roblox & Audio Portfolio

Full static site built around Foallow's Roblox scripting, systems, VFX and SFX projects.

## Publish to the existing website

Extract this ZIP. Upload its contents directly to the root of `nishinorblx-sys/nishino-portfolio` on GitHub, preserving the `assets` directory. Commit the files on `main`. Vercel should automatically deploy to the existing linked project.

The former `management.html` URL now redirects to `contact.html` so older links do not expose obsolete management text.

## Customize

- `assets/data.js`: project data, video IDs, navigation, copy, Discord username
- `assets/app.js`: layouts, contact interaction, YouTube players
- `assets/foallow-theme.css`: brand colors, video and contact styling
- `assets/sounds.js`: background interface audio, loading/hover/click

## Showcase videos

- SFX 01: https://youtu.be/34SKzpWsx5g
- SFX 02: https://youtu.be/ykqqHQ9Fcwc
- SFX 03: https://youtu.be/fZO_idRM3Bk
- Combat System and Zombie Wave: https://youtu.be/MckUlpPrPH0
- Car Driving System: https://youtu.be/7JPqTRmJWTI

YouTube videos open in place when clicked. A direct YouTube link is provided in case embedding is restricted by the video's settings.

## Contact

Discord: `foallow`

The Contact page provides a copyable username and an Open Discord link. No unrelated public profile or email is listed.

The audio files are preserved under `assets/audio/` and work independently of the YouTube showcase videos.

## V10 pricing and content

The SFX page contains only the SFX video showcases. Interface sounds still work across the site, but their preview cards have been removed. The home page no longer has the slogan or the remote/worldwide text. FAQ answers were rewritten to avoid the word previously used for project extent.

Edit `assets/data.js` under `pricingCatalog` to adjust quoted prices. The extra service and policy layout is in `assets/app.js`, with styling in `assets/pricing-v10.css`.

Advertised price examples are intended as editable starting rates, not binding offers.

## V11 Pricing Update

Pricing cards now show only a minimum starting price for each service. Higher-priced tiers and SFX/VFX maximums are no longer displayed. Final prices depend on complexity and work required; the agreed custom quote is supplied before development begins.

## V13 SFX Update

Added SFX Showcase 03, https://youtu.be/fZO_idRM3Bk, to the SFX page. The third video card uses the same design and click-to-play YouTube player as the first two videos.

## V17: Updated Portfolio Project Videos

- **Zombie Wave** is a separate project using the original YouTube video at https://youtu.be/MckUlpPrPH0.
- **Combat System** is a standalone project with `assets/media/zombie-combat-showcase.mp4` and its gameplay thumbnail.
- **Boss Battle + NPC Dialogue UI** remains one project with its recorded video.
- **Anime Abilities** contains eight selectable YouTube ability demonstrations inside one project popup. Each video can be opened individually.
- **FPS Weapon & Target Demo** remains a standalone project in the portfolio with an embedded MP4.
- **Inventory Systems** now includes the supplied 15-second recorded interface video and a frame extracted as its project thumbnail.
- Project thumbnails use video stills or matching YouTube thumbnails when media is available.
- The portfolio now has 13 project cards. The eight anime ability videos are grouped inside one card rather than counted as eight separate projects.

### Upload update archive

Unzip `Foallow-V17-Project-Videos-GitHub-Update.zip` into your repository root, overwriting `assets/data.js`, `assets/app.js`, and `assets/foallow-theme.css` while adding the two Inventory Systems media files under `assets/media/`.

Do not delete the existing `assets/media/` files. The previously uploaded Combat System, Boss Battle, Shop UI, Skill Trees and FPS MP4s are still used by the website.

## V18: Five source-code examples on Proof

The Proof page has five original, downloadable Roblox Luau ModuleScript examples in `assets/code/`, together with a syntax-highlighted preview, source expansion and copy/download controls.

- `CombatHitboxService.luau` is a server-owned box-hit query with configured damage, attack cooldowns, humanoid deduplication and capped queries. Call `Perform(player, attackName)` from validated server gameplay flow.
- `AbilityRunner.luau` registers server callbacks and executes them through a re-entrancy guard, cooldown check and `pcall`. Register each ability once, then call `Execute(player, abilityName)` on the server.
- `InventoryService.luau` handles session item counts, stack limits, allowlisted IDs and immutable snapshots. Call `Open(player)` when the player's inventory session is created; connect a real datastore and purchase validation before shipping.
- `NPCTargetSelector.luau` caches player targets and refreshes at controlled intervals. Use `GetNearest(npcModel, maxDistance)` from the AI decision loop and `Forget(npcModel)` when removing an NPC.
- `DeltaReplicator.luau` tracks selected player state values and sends changed fields over one server-owned `RemoteEvent` at 10 Hz. Call `Track`, `Set` and `Sync` from trusted server logic. Clients must listen to `FoallowStateDelta` and request a snapshot from a separately validated join/ready flow.

Place the modules as ModuleScripts in `ServerScriptService` or another server-only container and connect them to your own game services. They are reference implementations, not drop-in complete games or a claim of measured production benchmarks. They have not been run inside Roblox Studio in this environment. The original commissioned work and the reference website's code are not included.

To publish, upload `proof.html`, `README.md`, `assets/app.js`, `assets/proof-code.js`, `assets/proof-code.css` and all five files in `assets/code/`, preserving their paths.
