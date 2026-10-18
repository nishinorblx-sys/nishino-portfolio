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
- Combat System and Zombie Wave: https://youtu.be/MckUlpPrPH0
- Car Driving System: https://youtu.be/7JPqTRmJWTI

YouTube videos open in place when clicked. A direct YouTube link is provided in case embedding is restricted by the video's settings.

## Contact

Discord: `foallow`

The Contact page provides a copyable username and an Open Discord link. No unrelated public profile or email is listed.

The audio files are preserved under `assets/audio/` and work independently of the YouTube showcase videos.

## V10 pricing and content

The SFX page contains only the two video showcases. Interface sounds still work across the site, but their preview cards have been removed. The home page no longer has the slogan or the remote/worldwide text. FAQ answers were rewritten to avoid the word previously used for project extent.

Edit `assets/data.js` under `pricingCatalog` to adjust quoted prices. The extra service and policy layout is in `assets/app.js`, with styling in `assets/pricing-v10.css`.

Advertised price examples are intended as editable starting rates, not binding offers.
