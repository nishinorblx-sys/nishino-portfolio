# Foallow Portfolio V25

This is a single synchronized Foallow portfolio release. The site includes portfolio videos, pricing, SFX showcases, and five downloadable Luau engineering examples. The Discord contact is `foallow`.

## Publish to GitHub and Vercel

Upload this archive's contents to the root of `nishinorblx-sys/nishino-portfolio` on the `main` branch, preserving all `assets` paths. Vercel should redeploy the static website after the commit. The smaller V25 GitHub archive includes the complete current code folder and relevant website files; it does not replace unrelated website media.

## Proof section: one canonical version

Use `assets/code/COMBAT-V25-MANIFEST.md` as the source-of-truth index and hash list for the Luau modules in this release. Do not submit older module copies under the same names. `assets/code/COMBAT-SETUP.md` describes module and script placement. `assets/code/COMBAT-V25-VERIFICATION.md` defines the correctness and performance acceptance checklist. Historical versions of the test and review guides are not part of the current proof set.

V25 fixes held-guard renewal authorization and prevents a parry from being extended using the held-guard keepalive. It retains the M1 light, M2 parry, G heavy, F guard controls and the existing five/four-attack weapon definitions. `CombatHitboxService.Diagnostics` distinguishes scan CPU measurements, total per-attack processing CPU measurements and scheduler interval measurements. The Studio-only live E2E test scripts use real RemoteEvents, while requiring an explicit Workspace opt-in.

The movement API explicitly distinguishes an instant server-authorized teleport (`AuthorizeTeleport`) from budgeted gradual movement (`AuthorizeTravel` or `AuthorizeImpulse`). A gradual dash should never rely on the instantaneous teleport API.

## Important verification boundary

Source links and JavaScript syntax can be checked outside Roblox Studio. The Luau files have not been run in Roblox Studio here, and no performance or end-to-end pass results are claimed. Capture the real Studio output before presenting a rating or production-readiness conclusion.

## Other website configuration

- `assets/data.js`: project entries, videos, pricing and Discord display name
- `assets/app.js`: main page layout and project video viewers
- `assets/proof-code.js`: the five Proof samples and supporting source-file links
- `assets/sounds.js`: interface loading, hover and click sounds
- `assets/foallow-theme.css`: brand styling

Your existing project videos, SFX clips and media assets are included in the full-site archive, and not duplicated in the smaller GitHub source update.
