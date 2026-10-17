# NISHINO — Solar Amber Portfolio

A fully editable dark orange-and-gold Roblox developer portfolio with animations.

## Start

Open `index.html` locally, or host this static folder on any HTML hosting service. All 9 pages use the same shared styles and code.

## Edit

- `assets/data.js` contains the name, navigation, 13 showcase projects, services and contact placeholders.
- `assets/styles.css` contains layout, responsive styles and the Solar Amber palette.
- `assets/motion.css` contains the entrances, effects and animation styling.
- `assets/app.js` renders all pages.
- `assets/motion.js` handles scroll reveals, number counters, pointer tilt and transitions.

## Important

The original portfolio owner's reviews, education, clients, pricing promises and contact details have been removed. All 13 showcase project names were provided by Nishino. Descriptions are concise category-level summaries, not verified technical specifications. The icon artwork on each card is decorative and is not a gameplay screenshot. Add your own screenshots and demo links before publishing.

The primary contact target is `#contact`, and no personal Discord or email was invented. Add a real contact link before publishing.

## Pages

Home, Portfolio, Proof, Pricing, About, Clients, Reviews, FAQ, and Terms.

## Motion and accessibility

Interactive effects are disabled for users who request reduced motion.

## Portfolio — 13 projects

Zombie Wave, Combat System, Boss Battle, Shop UI, NPC Dialogue UI, Car Driving System, Skill Trees, Inventory Systems, Cutscene Abilities, Anime Abilities, Anime Transformations, Roblox Sports Physics Games, and VFX Creation.

The homepage features the first three items. Portfolio filters are generated from categories in `assets/data.js`. To change the order, title, category, subtitle or tags, edit the project objects in that file.

To attach a real screenshot, place it in a folder such as `assets/media/`, then add an `img` property to the relevant object: `"img": "assets/media/zombie-wave.webp"`. Leave it empty until you have real footage. To add an MP4 clip in the project popup, add a `video` property such as `"video": "assets/media/zombie-wave.mp4"` to that project. The file should exist in your local project. Custom thumbnails are visual placeholders, not actual project captures.

## Audio effects — V7

`assets/audio/Website1.MP3` is a faster version of your loading clip, time-compressed without raising its pitch. Its 1.54-second playback is synchronized with the loading progress. The original 2.69-second recording is preserved at `assets/audio/Website1-original.MP3`.

The first visit shows an ENTER EXPERIENCE button because web browsers require a user gesture to reliably play sound. Once entered, the short loading animation runs. Navigation between pages skips repeat splash screens entirely, using the existing animated page transition instead.

`assets/audio/Website2.MP3` plays when hovering over navigation links, portfolio category filters, project cards and category-style links. Its long silent tail has been removed, and its cooldown is now 45 milliseconds instead of 150 milliseconds. The original recording is preserved at `assets/audio/Website2-original.MP3`. Two audio voices limit overlap during rapid hovering.

`assets/audio/Website3.MP3` plays when clicking anywhere on the website. The SOUND ON/OFF toggle is retained and saved in your browser.

You can change the hover cooldown at `minimumGap.hover` in `assets/sounds.js`. Browser reduced-motion preferences are respected.
