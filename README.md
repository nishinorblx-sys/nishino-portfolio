# Nishino — Solar Amber Portfolio V8

An editable, animated Roblox developer portfolio. Version 8 adds an SFX preview page, Management by Foallow, and improved interaction audio.

## Upload this update to GitHub

1. Extract `Nishino-Solar-Amber-V8-Update.zip` on your computer.
2. Open `https://github.com/nishinorblx-sys/nishino-portfolio`.
3. Select **Add file → Upload files** and drag the **contents** of the extracted update folder into the repository root. Keep the `assets` folder structure. Do not upload the ZIP itself or add an extra enclosing folder.
4. Review the changed files and commit them to the `main` branch. Your connected Vercel project should deploy the commit automatically.
5. Open `https://nishino-portfolio.vercel.app`, refresh, and check the SFX and Management pages.

The separate **Full Website** ZIP includes every site file and its audio assets for a complete replacement or backup. You only need the **Update** ZIP if your GitHub repository still contains the original V7 assets.

## New pages

- `sfx.html` — three interactive playback samples using the existing loading, hover and click MP3s.
- `management.html` — Foallow's responsibilities, developer/management role separation, commission workflow and two contact cards.
- `assets/sections.css` — matching Solar Amber styles and mobile layouts.

The site includes the original thirteen project entries in `assets/data.js`, along with the existing animations and page transitions.

## Contact information to fill in

Update the `contacts` object near the start of `assets/data.js`:

- `contacts.developer` currently links to the confirmed public GitHub handle `@nishinorblx-sys`.
- `contacts.manager` is **not a verified contact link** yet. Replace `label`, `platform` and `url` with Foallow's correct Discord, email, or social profile. When `url` is nonempty, the card automatically shows a working contact button.

The portfolio avoids inventing unverified contact information. The homepage and hiring buttons now lead to the management contact area.

## Audio behavior

- `Website1.MP3` plays with the 1.54-second loading sequence after the visitor enters the experience.
- `Website2.MP3` is the quick category/navigation hover sound, with a 35ms limiter.
- `Website3.MP3` plays on site clicks; dynamic project cards and the added pages are supported.
- Short hover and click sounds use decoded Web Audio buffers when available, with an HTML Audio fallback. Temporary decoding or playback errors do not permanently disable a sound.
- Audio playback still depends on user gestures and the browser's autoplay policy.
- The header SOUND ON/OFF control persists the visitor's preference. If sound is silent, make sure it displays SOUND ON.

## Project media

Actual footage and images are not included. The graphic portfolio covers are visual placeholders, not gameplay captures. Each project may define an `img` and `video` path inside `assets/data.js` when those files are added.

## Scope and management expectations

Foallow coordinates communication, disputes, payments and relationships. Nishino remains responsible for the technical work and deliverables. No fixed fee, refund policy, escrow arrangement, or guaranteed timeline has been invented; those belong in the individual written agreement.
