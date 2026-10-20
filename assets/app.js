const S = window.SITE;
const showcaseIcons = {
  "wave": "<path d=\"M4 23h56M11 23v-9l8-5 8 5v9m6 0V10l8-5 8 5v13M17 34h29M17 42h29M17 50h18\"/><path d=\"M9 6l5 5m35-6-5 5\"/>",
  "combat": "<path d=\"M9 8l20 20m6 6 20 20M21 8l34 34M48 8L8 48m-1 7 9-9M42 8l14 14\"/><circle cx=\"32\" cy=\"32\" r=\"23\"/>",
  "boss": "<path d=\"M7 47l7-30 12 12 6-20 6 20 12-12 7 30H7Zm5 0 5 9h30l5-9M23 39h4m10 0h4\"/>",
  "shop": "<path d=\"M10 22h44l-4-12H14l-4 12Zm3 0v31h38V22M24 53V33h16v20M8 53h48\"/>",
  "dialogue": "<path d=\"M9 10h46v34H29L17 54V44H9V10Zm10 14h26M19 31h17\"/>",
  "car": "<path d=\"M9 38 15 24h34l6 14M6 38v13h10v-6h32v6h10V38l-7-8H13l-7 8Zm13 0h9m8 0h9M18 24l5-11h18l5 11\"/>",
  "skills": "<circle cx=\"32\" cy=\"11\" r=\"7\"/><circle cx=\"14\" cy=\"45\" r=\"7\"/><circle cx=\"50\" cy=\"45\" r=\"7\"/><path d=\"M32 18v10M14 38V28h36v10M14 52v5m36-5v5\"/>",
  "inventory": "<rect x=\"9\" y=\"9\" width=\"46\" height=\"46\" rx=\"3\"/><path d=\"M9 25h46M9 41h46M25 9v46m16-46v46\"/>",
  "cutscene": "<rect x=\"9\" y=\"15\" width=\"46\" height=\"35\" rx=\"2\"/><path d=\"M9 25h46m-35-10 7 10m8-10 7 10m-10 8 10 6-10 6zM17 8h29\"/>",
  "anime": "<path d=\"m35 5-20 30h14l-5 24 25-35H34l1-19Z\"/><path d=\"M13 12 7 5m44 47 6 7M7 51l7-7\"/>",
  "transform": "<circle cx=\"32\" cy=\"32\" r=\"14\"/><path d=\"M32 3v9m0 40v9M3 32h9m40 0h9M11 11l7 7m28 28 7 7m0-42-7 7M18 46l-7 7\"/><path d=\"m32 23 5 9-5 9-5-9z\"/>",
  "sports": "<circle cx=\"32\" cy=\"32\" r=\"24\"/><path d=\"m32 17 12 9-5 14H25l-5-14 12-9Zm0-9v9M10 22l10 4m34-4-10 4M16 49l9-9m23 9-9-9\"/>",
  "vfx": "<path d=\"m32 4 5 19 19-5-11 14 12 14-20-4-5 18-5-18-20 4 12-14L8 18l19 5 5-19Z\"/><circle cx=\"32\" cy=\"32\" r=\"5\"/>"
};

const currentPage = (() => {
  const name = location.pathname.split('/').pop() || 'index.html';
  return name.replace('.html','') || 'index';
})();
const svg = (name, size=18) => {
  const p = {
    arrow: '<path d="M5 12h14m-6-6 6 6-6 6"/>',
    diagonal: '<path d="M7 17 17 7M7 7h10v10"/>',
    chevron: '<path d="m9 18 6-6-6-6"/>',
    close: '<path d="M18 6 6 18M6 6l12 12"/>',
    menu: '<path d="M4 7h16M4 12h16M4 17h16"/>',
    plus: '<path d="M12 5v14M5 12h14"/>',
    check: '<path d="m5 12 4 4L19 6"/>',
    play: '<path d="m8 5 11 7-11 7z"/>',
    code: '<path d="m8 8-4 4 4 4m8-8 4 4-4 4m-3-13-2 18"/>',
    star: '<path d="m12 2 3 6 7 1-5 5 1.3 7L12 17.7 5.7 21 7 14l-5-5 7-1z"/>',
    copy: '<rect x="8" y="8" width="12" height="12" rx="2"/><path d="M16 8V6a2 2 0 0 0-2-2H6a2 2 0 0 0-2 2v8a2 2 0 0 0 2 2h2"/>'
  };
  return `<svg width="${size}" height="${size}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.65" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${p[name] || p.arrow}</svg>`;
};
const a = (text, href, className='text-link') => `<a class="${className}" href="${href}">${text}</a>`;
const cta = (text='Start a project') => `<a class="button button-primary" href="contact.html">${text} ${svg('diagonal',16)}</a>`;
const eyebrow = (label, num='') => `<div class="eyebrow"><span class="eyebrow-line"></span>${label}${num ? `<span class="eyebrow-num">${num}</span>` : ''}</div>`;
const pageIntro = (eyetext, title, description) => `<section class="page-intro wrap"><div class="page-intro-inner">${eyebrow(eyetext)}<h1>${title}</h1><p>${description}</p></div><div class="page-intro-art" aria-hidden="true"><span></span><span></span><span></span></div></section>`;
const sectionHead = (eyetext,title,extra='',link='') => `<div class="section-heading"><div>${eyebrow(eyetext)}<h2>${title}</h2>${extra?`<p class="section-subline">${extra}</p>`:''}</div>${link}</div>`;
function header() {
  return `<div class="top-strip"><span class="top-strip-left">INDEPENDENT ROBLOX DEVELOPMENT & SOUND DESIGN</span></div>
  <header class="site-header"><div class="wrap header-inner"><a class="brand" href="index.html"><span class="brand-mark">F<span class="brand-slash">/</span></span><span><b class="brand-word">FOAL<span class="brand-strong">LOW</span></b><small>SCRIPTING · VFX · AUDIO</small></span></a>
  <nav class="desktop-nav" aria-label="Main navigation">${S.navigation.map(([name,url]) => `<a href="${url}" ${((currentPage === 'index' && url==='index.html') || url===`${currentPage}.html`)?'class="active" aria-current="page"':''}>${name}</a>`).join('')}</nav>
  <div class="header-actions"><a href="${S.discord}" class="header-hire"><span class="status-dot"></span>Hire me <span class="header-hire-name">↗</span></a><button class="menu-toggle" aria-label="Toggle navigation" aria-expanded="false" id="menuToggle">${svg('menu',23)}</button></div></div>
  <nav class="mobile-nav" id="mobileNav" aria-label="Mobile navigation">${S.navigation.map(([name,url])=>`<a href="${url}">${name}${svg('arrow',16)}</a>`).join('')}</nav></header>`;
}
function footer() {
  const smallLinks = ['Combat systems','Movement','Abilities','UI scripting','Sound design','VFX creation','Game architecture'];
  return `<section class="contact-band" id="contact"><div class="wrap contact-band-inner"><div>${eyebrow('YOUR NEXT PROJECT STARTS HERE')}<h2>Build something<br><em>extraordinary.</em></h2><p>Have a game idea, a complex mechanic, or a whole experience in mind? Let’s give it a shape worth playing.</p></div><div class="contact-side"><a class="button button-primary" href="contact.html">Message Foallow ${svg('diagonal',16)}</a><span class="contact-email">Discord / @foallow</span></div></div></section>
  <footer class="footer"><div class="wrap"><div class="footer-top"><div class="footer-brand"><div class="brand footer-logo"><span class="brand-mark">F<span class="brand-slash">/</span></span><span><b class="brand-word">FOAL<span class="brand-strong">LOW</span></b><small>SCRIPTING · VFX · AUDIO</small></span></div><p>Independent Roblox creator working across scripts, game design, effects and audio.</p><span class="footer-status"><i class="status-dot"></i> ${S.availability}</span></div>
  <div class="footer-links"><h4>Explore</h4>${S.navigation.slice(1).map(([n,u])=>a(n,u)).join('')}</div><div class="footer-links"><h4>Expertise</h4>${smallLinks.map(n=>a(n,'pricing.html')).join('')}</div><div class="footer-links"><h4>Get in touch</h4>${a('Discord · @foallow', 'contact.html')}${a('View portfolio ↗','portfolio.html')}${a('About Foallow ↗','about.html')}${a('Discord contact ↗','contact.html')}</div></div><div class="footer-bottom"><span>© 2026 FOALLOW · ${S.location}</span><span>BUILT WITH INTENTION. ENGINEERED TO PLAY.</span><a href="#top" class="to-top" aria-label="Back to top">↑</a></div></div></footer>`;
}
function cover(project, extra='') {
  const symbol=showcaseIcons[project.icon]||showcaseIcons.vfx;
  return `<div class="project-cover tone-${project.tone} ${extra}"><div class="cover-scene"><span class="scene-orb"></span><span class="scene-grid"></span><span class="scene-box box-1"></span><span class="scene-box box-2"></span><span class="scene-box box-3"></span></div><div class="showcase-visual" aria-hidden="true"><span class="showcase-visual-ring"></span><svg viewBox="0 0 64 64" fill="none" stroke="currentColor" stroke-width="2.4" stroke-linejoin="round" stroke-linecap="round">${symbol}</svg><span class="showcase-visual-sheen"></span></div>${project.img?`<img src="${project.img}" alt="Project media: ${project.name}" loading="lazy" onerror="this.remove()">`:``}<span class="cover-type">${project.type}</span><span class="cover-code">${project.code} / FOALLOW</span><span class="cover-title">${project.name}</span><span class="cover-arrow">${svg('diagonal',22)}</span></div>`;
}
function featuredGames() {
  return `<div class="featured-games-grid">${S.featuredGames.map((game, index) => `<a class="featured-game-card game-${game.tone}" href="${game.url}" target="_blank" rel="noopener noreferrer" aria-label="Open ${game.name} on Roblox"><div class="featured-game-art"><span class="featured-game-mark" aria-hidden="true">${game.name.slice(0,2).toUpperCase()}</span><img src="https://www.roblox.com/asset-thumbnail/image?assetId=${game.placeId}&width=768&height=432&format=png" alt="${game.name} Roblox experience artwork" loading="lazy" onerror="this.remove()"><span class="featured-game-number">0${index+1} / ROBLOX</span><span class="featured-game-icon">${svg('diagonal',20)}</span></div><div class="featured-game-info"><span class="featured-game-genre">${game.genre}</span><h3>${game.name}</h3><p>Developed / contributed to</p><span class="featured-game-visit">View experience ${svg('arrow',16)}</span></div></a>`).join('')}</div>`;
}
function games() {
  return `${pageIntro('FOALLOW / GAME CREDITS', 'Games I\'ve <em>worked on.</em>', 'Roblox experiences I have developed or contributed to. Select any title to view its Roblox game page.')}
    <section class="section wrap">${sectionHead('01 / PUBLISHED EXPERIENCES', 'Crafted for gameplay.', 'Four experiences from my Roblox development work.')}${featuredGames()}</section>`;
}
function projectCard(project) {
  return `<button class="project-card" data-project="${S.projects.indexOf(project)}" aria-label="View ${project.name}">${cover(project)}<div class="project-bottom"><div><span class="card-kicker">${project.category}</span><h3>${project.name}</h3><p>${project.desc}</p></div><div class="project-bottom-meta"><span>${project.focus.slice(0,2).join(' / ')}</span><span>${project.code} / ${S.projects.length}</span></div></div></button>`;
}
function home() {
  return `<section class="hero wrap" id="top"><div class="hero-copy"><div class="hero-overline"><span class="status-dot"></span>${S.availability}<span class="hero-overline-tail">/ ROBLOX DEVELOPMENT</span></div><h1>Hey, I'm <em>Foallow.</em><br>Scripts, visuals<br><span class="hero-muted">and sound.</span></h1><p class="hero-desc">${S.description}</p><div class="hero-ctas">${cta('Let’s build something')}<a href="portfolio.html" class="button button-outline">Explore projects ${svg('arrow',16)}</a><a href="portfolio.html#ability-collection" class="button button-ghost-clip">Ability showcases ${svg('play',15)}</a></div></div>
  <div class="hero-side"><div class="identity-card"><div class="identity-top"><span class="identity-no">// 001</span><span class="identity-chip">FOALLOW / CREATOR PROFILE ${svg('diagonal',13)}</span></div><div class="identity-art"><div class="identity-circle"></div><div class="identity-vector">F<span>✦</span></div><div class="identity-grid"></div><div class="identity-bracket bracket-one">[</div><div class="identity-bracket bracket-two">]</div></div><div class="identity-caption"><div><span class="identity-label">FOALLOW PORTFOLIO</span><h3>Foallow</h3></div><span class="status-pill"><i class="status-dot"></i> BUILDING</span></div></div><div class="credentials-row"><div><span>01 / SPECIALITY</span><b>Gameplay systems</b></div><div><span>02 / PLATFORM</span><b>Roblox Studio</b></div><div><span>03 / LANGUAGE</span><b>Luau</b></div></div></div></section>
  <section class="metrics-section"><div class="wrap metrics-grid">${S.metrics.map((m,i)=>`<div class="metric"><div class="metric-top"><span>${String(i+1).padStart(2,'0')} / 04</span><span>${m.icon}</span></div><strong>${m.value}</strong><h3>${m.label}</h3><p>${m.detail}</p></div>`).join('')}</div></section>
  <section class="section wrap">${sectionHead('01 / PUBLISHED GAMES','Crafted for gameplay.','Roblox experiences I have developed or contributed to.',a(`View game credits ${svg('arrow',16)}`,'games.html','section-link'))}
  ${featuredGames()}</section>
  <section class="section section-separated wrap">${sectionHead('02 / EXPLORE THE WORK','Everything in one place.','A deeper look into systems, workflow and what comes next.')}
  <div class="route-grid">${[['Portfolio','See real projects and systems from my showcase.','portfolio.html','01'],['Games','Experiences I developed or contributed to.','games.html','09'],['SFX','Watch Foallow’s SFX showreels.','sfx.html','07'],['Contact','Discuss a commission directly with Foallow on Discord.','contact.html','08'],['Proof','Code and implementation details.','proof.html','02'],['Pricing','Browse services and pricing.','pricing.html','03'],['About','My focus and how I build.','about.html','04'],['Reviews','Space for authentic client feedback.','reviews.html','05'],['Terms','Ownership and delivery details.','terms.html','06']].map(([n,d,u,k])=>`<a class="route-tile" href="${u}"><span class="route-index">${k}, EXPLORE</span><h3>${n}<span>${svg('diagonal',22)}</span></h3><p>${d}</p></a>`).join('')}</div></section>
  <section class="section section-separated wrap">${sectionHead('03 / SELECTED BUILDS','Projects in focus.','A selection of Roblox experiences I’ve built.',a(`All projects ${svg('arrow',16)}`,'portfolio.html','section-link'))}<div class="projects-grid home-projects">${S.projects.slice(0,3).map(projectCard).join('')}</div><div class="feature-showcase"><div class="feature-cover"><div class="feature-cover-number">F/</div><p>BUILT TO BE PLAYED</p><strong>FOALLOW · CREATIVE SYSTEMS</strong></div><div class="feature-info"><span class="tag">MY APPROACH</span><h3>Good systems.<br>Great game feel.</h3><p>Thoughtful interaction, responsive movement and polished presentation are what turn a simple feature into something players remember.</p><a href="portfolio.html" class="inline-arrow">See the work ${svg('arrow',18)}</a></div></div></section>
  <section class="section section-separated wrap">${sectionHead('04 / HOW I WORK','Built with purpose.','Every detail should move the experience forward.')}
  <div class="education-grid"><div class="education-card"><span>01 / DISCOVER</span><h3>Understand the vision</h3><p>Translate ideas and references into a practical gameplay plan.</p><b>PLAN</b></div><div class="education-card"><span>02 / CREATE</span><h3>Build with structure</h3><p>Reusable systems, thoughtful architecture and clean integrations.</p><b>CREATE</b></div><div class="education-card"><span>03 / REFINE</span><h3>Make it feel right</h3><p>Iterate on responsiveness, performance, UX and visual polish.</p><b>POLISH</b></div></div></section>
  <section class="section section-separated wrap">${sectionHead('05 / FEEDBACK','The next chapter.','Client feedback can be added here as genuine projects are delivered.',a(`Reviews page ${svg('arrow',16)}`,'reviews.html','section-link'))}<div class="testimonial-empty"><span>✦</span><h3>Real results deserve real words.</h3><p>This section is ready for your own verified reviews and project testimonials.</p><a href="reviews.html" class="inline-arrow">See review layout ${svg('arrow',16)}</a></div></section>
  <section class="section section-separated wrap">${sectionHead('06 / MY PROCESS','Designed to evolve.','The building blocks behind every experience.')}<div class="personal-grid">${[['01','Concept'],['02','Prototype'],['03','Iterate'],['04','Launch']].map(([n,d],i)=>`<div class="personal-tile"><span>0${i+1}</span><strong>${n}</strong><small>${d}</small></div>`).join('')}</div></section>
  <section class="section section-separated wrap">${sectionHead('07 / COLLABORATION','Code. Effects. Sound.','Everything here is created by Foallow, from playable systems to audio feedback.')}<div class="dual-cards"><a class="info-card foallow-explore-card" href="sfx.html"><span>SFX / VIDEO SHOWCASES</span><h3>Listen to the craft.</h3><p>Watch my original SFX design reels.</p><strong>Explore SFX ${svg('diagonal',16)}</strong></a><a class="info-card foallow-explore-card" href="contact.html"><span>CONTACT / DISCORD</span><h3>Work directly with Foallow.</h3><p>From the initial concept to the final polish, reach the creator directly on Discord.</p><strong>Get in touch ${svg('diagonal',16)}</strong></a></div></section>`;
}

function sfx() {
  return `${pageIntro('FOALLOW / SOUND DESIGN','Sound that <em>hits.</em>','Three showcase videos featuring Foallow’s sound design work.')}
  <section class="section wrap foallow-video-section">${sectionHead('01 / SOUND DESIGN SHOWREELS','SFX showcase.','Watch the sound design showcases below.')}
  <div class="foallow-video-grid">${S.media.sfx.map((video,i)=>videoCard(video,'SOUND DESIGN',i+1)).join('')}</div></section>`;
}
function contact() {
  return `${pageIntro('GET IN TOUCH / DISCORD','Let’s make <em>something.</em>','One creator. One direct contact. Reach Foallow on Discord for commissions, questions, and collaborations.')}
  <section class="section wrap foallow-contact-section"><div class="foallow-contact-panel"><div class="foallow-contact-info"><span class="foallow-kicker">FOALLOW / DISCORD CONTACT</span><div class="foallow-contact-mark">F<span>✦</span></div><h2>Message me on Discord.</h2><p>Whether it’s a combat system, complete Roblox game, cinematic VFX or custom sound design, let’s talk about your idea and what it needs.</p><div class="foallow-discord-tag"><span class="foallow-discord-badge">DISCORD</span><strong>@foallow</strong><span class="foallow-discord-online">OPEN FOR INQUIRIES</span></div><div class="foallow-contact-actions"><button class="button button-primary" type="button" id="copyDiscord">${svg('copy',17)} <span>Copy username</span></button><a class="button button-outline" href="https://discord.com/app" target="_blank" rel="noopener noreferrer">Open Discord ${svg('diagonal',16)}</a></div><p class="foallow-copy-status" id="discordCopyStatus" role="status" aria-live="polite">Add <strong>foallow</strong> on Discord to send a message.</p></div><div class="foallow-contact-aside"><span>BEFORE REACHING OUT</span><h3>What to send</h3><div class="foallow-contact-steps"><p><b>01 / The idea</b><span>A short description of the game, feature or audio you want.</span></p><p><b>02 / References</b><span>Videos, images or examples that show the result you have in mind.</span></p><p><b>03 / Budget & timeline</b><span>Your budget, deadline, and any systems or assets already prepared.</span></p></div></div></div></section>`;
}
function videoCard(item, category, order) {
  const watch = `https://www.youtube.com/watch?v=${item.id}`;
  return `<article class="foallow-video-card"><div class="foallow-video-meta"><span>${String(order).padStart(2,'0')} / ${category}</span><span>VIDEO SHOWCASE ↗</span></div><div class="foallow-video-frame" data-video-frame="${item.id}"><img src="https://i.ytimg.com/vi/${item.id}/hqdefault.jpg" loading="lazy" alt="${item.title} video thumbnail" onerror="this.remove()"><button class="foallow-video-launch" type="button" data-video-launch="${item.id}" aria-label="Play ${item.title}">${svg('play',26)}</button><span class="foallow-video-mark">FOALLOW / SHOWREEL</span></div><div class="foallow-video-foot"><div><h3>${item.title}</h3><p>${item.subtitle}</p></div><a href="${watch}" target="_blank" rel="noopener noreferrer">Watch on YouTube ${svg('diagonal',16)}</a></div></article>`;
}
function localVideoCard(item, order) {
  return `<article class="foallow-video-card"><div class="foallow-video-meta"><span>${String(order).padStart(2,'0')} / ROBLOX SCRIPTING</span><span>ORIGINAL GAMEPLAY FILE</span></div><div class="foallow-video-frame foallow-video-local"><video controls playsinline preload="metadata" poster="${item.poster}" aria-label="${item.title}"><source src="${item.video}" type="video/mp4">Your browser does not support the video player.</video></div><div class="foallow-video-foot"><div><h3>${item.title}</h3><p>${item.subtitle}</p></div><span class="foallow-local-label">PLAY ON THIS PAGE</span></div></article>`;
}
function reviewCard(name,quote) { return `<article class="review-card"><div class="review-stars">✦✦✦✦✦</div><blockquote>“${quote}”</blockquote><div class="review-person"><span class="review-avatar">${name.charAt(0).toUpperCase()}</span><div><strong>${name}</strong><small>Client review</small></div></div></article>`; }
function portfolio() {
  return `${pageIntro('FOALLOW / PROJECT SHOWCASE','The <em>portfolio.</em>','Explore '+S.projects.length+' Roblox showcases across gameplay, UI, scripting, combat, FPS mechanics and visual effects. Filter projects or play a demonstration.')}
  <section class="section wrap portfolio-section">${sectionHead('01 / HIGHLIGHTS','Selected work','Three projects from my showcase.')}
  <div class="projects-grid highlight-grid">${S.projects.slice(0,3).map(projectCard).join('')}</div></section>
  <section class="section section-separated wrap foallow-video-section">${sectionHead('02 / GAMEPLAY FOOTAGE','See it in motion.','Actual video demonstrations of Foallow’s zombie survival and vehicle systems.')}
  <div class="foallow-video-grid">${S.media.gameplay.map((video,i)=>videoCard(video,'ROBLOX GAMEPLAY',i+1)).join('')}</div></section>
  <section class="section section-separated wrap foallow-video-section" id="ability-collection">${sectionHead('03 / FEATURED COLLECTIONS','Abilities and FPS.','Eight anime ability demonstrations grouped together, plus a standalone FPS weapon project.')}
  <div class="projects-grid foallow-collections-grid">${[S.projects.find(p=>p.name==='Anime Abilities'),S.projects.find(p=>p.name==='FPS Weapon & Target Demo')].filter(Boolean).map(projectCard).join('')}</div></section>
  <section class="section section-separated wrap">${sectionHead('04 / THE ARCHIVE','All projects','All '+S.projects.length+' projects, organized by discipline.')}
  <div class="filter-row" id="filters" role="group" aria-label="Filter projects">${['All',...new Set(S.projects.map(p=>p.category))].map((x,i)=>`<button class="filter-btn ${!i?'selected':''}" data-filter="${x}" aria-pressed="${!i}">${x}</button>`).join('')}</div><div class="projects-grid" id="projectGrid">${S.projects.slice(0,8).map(projectCard).join('')}</div><div class="load-more-wrap"><span id="showingCount">Showing ${Math.min(8,S.projects.length)} of ${S.projects.length} projects</span><button class="button button-outline" id="loadMore">Load more projects ${svg('arrow',16)}</button></div></section>`;
}
function pricing() {
  const priceCard = item => `<article class="rate-card"><div class="rate-card-top"><span>${item.type}</span><span>CUSTOM PRICING</span></div><h3>${item.name}</h3><p class="rate-description">${item.desc}</p><ul class="rate-features">${item.features.map(feature=>`<li>${feature}</li>`).join('')}</ul><div class="rate-minimum"><span>MINIMUM STARTING PRICE</span><strong>${item.starting} <small>USD</small></strong><p>Final pricing varies with the complexity and amount of work required.</p></div><div class="rate-bottom"><a href="contact.html">Request a quote</a><a href="portfolio.html">See projects</a><a href="contact.html" class="rate-arrow" aria-label="Request a ${item.name} quote">${svg('arrow',20)}</a></div></article>`;
  const pricingSections = S.pricingCatalog.map((group,i)=>`<section class="section wrap rate-section"><div class="rate-heading"><div><span class="rate-number">${String(i+2).padStart(2,'0')}</span><div><div class="rate-overline">${String(i+2).padStart(2,'0')} / SERVICES</div><h2>${group.group}</h2><p>${group.caption}</p></div></div></div><div class="rate-grid">${group.items.map(priceCard).join('')}</div></section>`).join('');
  return `${pageIntro('FOALLOW / PRICING','Simple, <em>clear pricing.</em>','All displayed amounts are minimum starting prices in USD, not maximum prices or fixed packages. Final quotes vary depending on complexity, required features, and the amount of work involved.')}
  <section class="section wrap rate-intro"><div class="rate-heading"><div><span class="rate-number">01</span><div><div class="rate-overline">01 / COMMISSION PROCESS</div><h2>How commissions work.</h2><p>Four straightforward steps from first contact to delivery.</p></div></div></div><div class="rate-process">${[['01','Message Foallow','Contact me on Discord with the project idea and any reference videos.'],['02','Share your requirements','Describe the features, visuals, timeline, and what you already have ready.'],['03','Receive a price','We agree on deliverables, milestones, revisions, payment arrangements and the timeline.'],['04','Build and deliver','I develop the work, test it, share progress and deliver what we agreed on.']].map(([n,title,description])=>`<div class="rate-step"><b>${n}</b><h3>${title}</h3><p>${description}</p></div>`).join('')}</div></section>
  ${pricingSections}
  <section class="section wrap rate-section"><div class="rate-heading"><div><span class="rate-number">05</span><div><div class="rate-overline">05 / OPTIONAL SERVICES</div><h2>Faster delivery and consultation.</h2><p>Additional options when you need priority handling or planning advice.</p></div></div></div><div class="rate-options"><article class="rate-option"><span>PRIORITY DELIVERY</span><h3>Need it sooner?</h3><p><strong>${S.rushPolicy.priority}</strong> for priority delivery, usually ${S.rushPolicy.priorityTime}.</p><p><strong>${S.rushPolicy.dropAll}</strong> for drop-all priority, subject to availability.</p><small>Rush delivery must be agreed on before work begins.</small></article><article class="rate-option"><span>DEVELOPMENT CONSULTATION</span><h3>Need a plan?</h3><p><strong>${S.rushPolicy.consult}</strong> for ${S.rushPolicy.consultTime.toLowerCase()} of discussion, architecture advice or review.</p><p>Short initial questions and basic price estimates are free.</p><small>Contact Foallow on Discord to arrange a session.</small></article></div></section>
  <section class="section wrap rate-section rate-payment"><div class="rate-heading"><div><span class="rate-number">06</span><div><div class="rate-overline">06 / BEFORE YOU HIRE</div><h2>Payment and expectations.</h2><p>Clarity from the first message.</p></div></div></div><div class="rate-payment-content"><p>All listed prices are <strong>minimum starting rates in USD</strong>, not maximum prices. The total depends on the complexity, features, integrations, effects, revisions and work required. After reviewing your requirements, Foallow will provide a personalized quote before development begins.</p><p>Payment arrangements and delivery stages are agreed in writing before a commission starts. Send your budget and references, and I can suggest an approach that fits.</p><a class="button button-primary" href="contact.html">Contact Foallow on Discord ${svg('diagonal',16)}</a></div></section>`;
}
function proof() {
  return `${pageIntro('ENGINEERING / ORIGINAL CODE','The <em>code.</em>','Five Luau engineering examples, including a modular combat engine with server validation, timed hit windows and unified damage rules.')}
  <section class="section wrap proof-code-section">${sectionHead('01 / OPEN SOURCE EXAMPLES','Read the implementation.','Five systems and their source code, including the combat architecture and integration files.')}
  <div class="proof-code-overview"><strong>FIVE SYSTEMS / FULL SOURCE AVAILABLE</strong></div>
  <div id="proofCodeGallery" class="proof-code-gallery" aria-label="Five Luau code system demonstrations"></div></section>
  <section class="section section-separated wrap">${sectionHead('02 / TECHNICAL SKILLS','How the systems fit.','The underlying principles that make game systems maintainable.')}
  <div class="proof-grid"><div class="proof-card"><div class="proof-icon">${svg('code',25)}</div><span>TECH STACK / LUAU</span><h3>Server-owned gameplay</h3><p>Combat, cooldowns, economy and state changes are decided on the server, with validation before any action is processed.</p><div class="proof-chips"><span>Luau</span><span>Validation</span><span>Game systems</span></div><a href="portfolio.html">Explore gameplay projects ${svg('diagonal',17)}</a></div>
  <div class="proof-card"><div class="proof-icon">${svg('code',25)}</div><span>TECH STACK / ROBLOX</span><h3>Predictable performance</h3><p>Skip unnecessary frame loops, reuse state, cap expensive searches and only replicate changed data.</p><div class="proof-chips"><span>Efficiency</span><span>Networking</span><span>Clean state</span></div><a href="portfolio.html">View game showcases ${svg('diagonal',17)}</a></div></div></section>
  <section class="section section-separated wrap">${sectionHead('03 / CAPABILITIES','Systems & services','More areas represented in the project portfolio.')}<div class="studio-table">${S.studios.slice(0,8).map((s,i)=>`<a href="clients.html" class="studio-row"><span class="rank">${String(i+1).padStart(2,'0')}</span><span class="studio-name">${s[0]}</span><span class="studio-visits"><small>${s[1]}</small></span><span class="studio-arrow">${svg('diagonal',17)}</span></a>`).join('')}</div></section>`;
}
function about() {
  return `${pageIntro('THE DEVELOPER / FOALLOW','About <em>me.</em>','Game systems, thoughtful interaction and experiences worth playing.')}
  <section class="section wrap"><div class="split-section"><div>${eyebrow('01 / THE PERSON')}<h2>Developer.<br>Builder.<br>Creator.</h2></div><div class="split-copy"><p>I’m Foallow. I build Roblox games and interactive experiences across scripting, combat, movement, sports physics, interfaces, VFX and sound design.</p><p>I bring the parts together myself, gameplay logic, visual presentation and the audio details that make each action feel satisfying.</p>${cta('Start a conversation')}</div></div></section>
  <section class="section section-separated wrap"><div class="split-section"><div>${eyebrow('02 / THE PROCESS')}<h2>Structure meets<br>creativity.</h2></div><div class="split-copy"><p>Start with a clear gameplay goal. Build the underlying systems. Then refine the moment-to-moment feel through testing, animation, visual feedback and iteration.</p><p>Strong organization makes complex game features easier to maintain and extend.</p><div class="mini-tags"><span>Luau</span><span>Roblox Studio</span><span>VFX</span><span>Sound Design</span><span>UI</span></div></div></div></section>
  <section class="section section-separated wrap">${sectionHead('03 / APPROACH','How I build.','A workflow that scales with the ambition of the project.')}<div class="timeline">${[['01','Discover the vision','Understand the game, references and expected player experience.'],['02','Create the foundation','Build structured systems with well-defined behavior.'],['03','Test the details','Refine movement, interactions and feedback.'],['04','Keep evolving','Expand features and polish the experience.']].map(([when,title,desc])=>`<div class="timeline-item"><span>${when}</span><div><h3>${title}</h3><p>${desc}</p></div>${svg('diagonal',16)}</div>`).join('')}</div></section>`;
}
function clients() {
  return `${pageIntro('WORK / CAPABILITIES','What I <em>create.</em>','Game development capabilities today, with room for verified studio credits and collaborations as you add them.')}
  <section class="section wrap">${sectionHead('01 / SPECIALTIES','Built around gameplay.','Ten disciplines spanning game systems, effects and sound.')}<div class="client-grid">${S.studios.map(([name,category],i)=>`<article class="client-card"><div class="client-card-top"><span class="client-monogram">${name.substring(0,1).toUpperCase()}</span><span>${String(i+1).padStart(2,'0')} / ${String(S.studios.length).padStart(2,'0')}</span></div><h3>${name}</h3><div><strong>${category}</strong><small>Development area</small></div></article>`).join('')}</div></section>`;
}
function reviews() {
  return `${pageIntro('TESTIMONIALS / YOUR STORY','Client <em>reviews.</em>','A dedicated space for real feedback from people you have worked with.')}
  <section class="section wrap">${sectionHead('01 / WORDS THAT MATTER','Let the work speak.','Add genuine testimonials, names and links when you have permission to publish them.')}<div class="testimonial-empty testimonial-empty-large"><span>✦</span><h3>Great work deserves an honest review.</h3><p>Your own client testimonials will live here. The layout is ready, no borrowed quotes, fake names or invented ratings.</p></div></section>`;
}
function faq() {
  return `${pageIntro('FAQ / QUESTIONS & ANSWERS','Questions, <em>answered.</em>','Find information about collaboration, prices, payments, revisions and ongoing support.')}
  <section class="section wrap faq-section"><div class="faq-layout"><aside class="faq-aside"><span>JUMP TO CATEGORY</span>${S.faqs.map((g,i)=>`<a href="#faq-${i}">${String(i+1).padStart(2,'0')} ${g.group}</a>`).join('')}</aside><div class="faq-main">${S.faqs.map((g,i)=>`<section class="faq-group" id="faq-${i}">${sectionHead(`0${i+1} / HELP`,g.group,`${g.items.length} questions`)}<div class="accordion">${g.items.map(([q,a])=>`<details class="faq-item"><summary>${q}<span>${svg('plus',20)}</span></summary><p>${a}</p></details>`).join('')}</div></section>`).join('')}</div></div></section>`;
}
function terms() {
  return `${pageIntro('SERVICE AGREEMENT / PLEASE READ','Terms of <em>engagement.</em>','A starter framework for project terms. Customize and legally review before publishing.')}
  <section class="section wrap"><div class="terms-layout"><aside><span>SERVICE AGREEMENT</span><p>Template language only. Edit these policies to match your actual process before publication.</p></aside><div class="terms-content">${[
    ['01','Agreed deliverables','All deliverables should be clearly recorded in a written Game Design Document (GDD). Additional features and substantial changes may be handled as new work.'],
    ['02','Milestones & payment','Projects are broken into defined milestones with agreed prices and deliverables. Payment methods, timing, refunds and processing fees must be specified in writing before work begins.'],
    ['03','Assets & responsibilities','The client provides requirements, references, existing assets and access needed for the agreed work. Foallow can create scripting, UI, VFX and SFX where those deliverables are included in the agreed requirements.'],
    ['04','Delivery & revisions','Each milestone should have clear acceptance criteria, a revision process and a defined bug-fix window.'],
    ['05','Intellectual property','Ownership of commissioned game-specific work and licensing of underlying reusable tools should be expressly set out in the written contract.'],
    ['06','Communication','Foallow is the direct contact for all project questions. Agree in writing on updates, response expectations, deadlines and how issues are resolved.'],
    ['07','Security & performance','Secure server-authoritative development can reduce risk, but guarantees should be restricted to the agreed requirements and testing requirements.']
  ].map(([n,t,d])=>`<article class="term-entry"><span>${n} / POLICY</span><h2>${t}</h2><p>${d}</p></article>`).join('')}</div></div></section>`;
}
const pages = { index:home,games,portfolio,sfx,contact,pricing,proof,about,clients,reviews,faq,terms };
const app = document.getElementById('app');
app.innerHTML = `${header()}<main id="top">${(pages[currentPage]||home)()}</main>${footer()}<dialog id="projectModal" class="project-modal"><button class="dialog-close" aria-label="Close project" id="closeModal">${svg('close',21)}</button><div id="modalContent"></div></dialog>`;
const menuToggle = document.getElementById('menuToggle');
menuToggle.addEventListener('click',()=>{
  const opened = document.body.classList.toggle('nav-open');
  menuToggle.setAttribute('aria-expanded',String(opened));
  menuToggle.innerHTML = svg(opened?'close':'menu',23);
});
const modal = document.getElementById('projectModal');
function abilityGallery(project) {
  const items = project.abilities || [];
  if (!items.length) return '';
  const first = items[0];
  return `<section class="foallow-ability-gallery" aria-label="Anime ability video collection"><div class="foallow-ability-heading"><div><span>ABILITY SHOWCASE COLLECTION</span><h3>${items.length} recorded abilities</h3><p>Select a video below to view that ability demonstration.</p></div><span class="foallow-ability-count">${String(items.length).padStart(2,'0')} CLIPS</span></div><div class="foallow-ability-player" id="abilityPlayer"><button class="foallow-ability-start" type="button" data-ability-video="${first.id}" aria-label="Play ${first.title}"><img src="https://i.ytimg.com/vi/${first.id}/hqdefault.jpg" alt="Preview of ${first.title}"><span class="foallow-ability-play">${svg('play',28)}</span><span class="foallow-ability-start-label">PLAY SHOWCASE</span></button></div><div class="foallow-ability-grid" role="group" aria-label="Select an ability clip">${items.map((item,i)=>`<button type="button" class="foallow-ability-choice ${i===0?'selected':''}" data-ability-video="${item.id}" aria-pressed="${i===0}" aria-label="Watch ${item.title}"><img src="https://i.ytimg.com/vi/${item.id}/mqdefault.jpg" alt="" loading="lazy"><span><b>${String(i+1).padStart(2,'0')}</b>${item.title}</span></button>`).join('')}</div><a class="foallow-ability-youtube" id="abilityYouTube" target="_blank" rel="noopener noreferrer" href="https://www.youtube.com/watch?v=${first.id}">Watch selected clip on YouTube ${svg('diagonal',15)}</a></section>`;
}
function showProject(idx) {
  const p = S.projects[idx];
  if(!p) return;
  document.getElementById('modalContent').innerHTML = `${cover(p,'modal-cover')}<div class="modal-body"><span class="tag">${p.type} · ${p.category}</span><h2>${p.name}</h2><p>${p.desc}</p>${p.abilities?.length?abilityGallery(p):p.youtube?`<div class="modal-video foallow-modal-video"><iframe src="https://www.youtube-nocookie.com/embed/${p.youtube}?rel=0" title="${p.name} showcase" loading="lazy" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe><a href="https://www.youtube.com/watch?v=${p.youtube}" target="_blank" rel="noopener noreferrer">Watch showcase on YouTube ↗</a></div>`:p.video?`<div class="modal-video"><video controls preload="metadata" ${p.img?`poster="${p.img}"`:``}><source src="${p.video}" type="video/mp4">Your browser does not support embedded video.</video></div>`:``}<div class="modal-focus"><span>PROJECT FOCUS</span><div>${p.focus.map(tag=>`<span>${tag}</span>`).join('')}</div></div><div class="modal-stats"><div><small>PROJECT CATEGORY</small><strong>${p.category}</strong></div><div><small>PLATFORM</small><strong>Roblox</strong></div></div><a class="button button-primary" href="${S.discord}">Discuss a similar project ${svg('diagonal',16)}</a></div>`;
  modal.showModal();
  document.body.classList.add('modal-open');
}
document.addEventListener('click',event=>{
  const button=event.target.closest('[data-ability-video]');
  if (!button || !modal.contains(button)) return;
  const id=button.dataset.abilityVideo;
  if (!/^[A-Za-z0-9_-]{11}$/.test(id)) return;
  const player=document.getElementById('abilityPlayer');
  if (!player) return;
  player.innerHTML=`<iframe src="https://www.youtube-nocookie.com/embed/${id}?autoplay=1&rel=0" title="Foallow anime ability demonstration" allow="autoplay; encrypted-media; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>`;
  document.querySelectorAll('.foallow-ability-choice').forEach(choice=>{
    const selected=choice.dataset.abilityVideo===id;
    choice.classList.toggle('selected',selected);
    choice.setAttribute('aria-pressed',String(selected));
  });
  const watch=document.getElementById('abilityYouTube');
  if (watch) watch.href=`https://www.youtube.com/watch?v=${id}`;
});
document.addEventListener('click',e=>{
  const project=e.target.closest('[data-project]');
  if(project) showProject(Number(project.dataset.project));
});
document.getElementById('closeModal').addEventListener('click',()=>modal.close());
modal.addEventListener('click',e=>{if(e.target===modal) modal.close()});
modal.addEventListener('close',()=>{document.body.classList.remove('modal-open');document.getElementById('modalContent').replaceChildren()});
if(currentPage==='portfolio') {
  let category='All', visible=8;
  const grid=document.getElementById('projectGrid'), count=document.getElementById('showingCount'), more=document.getElementById('loadMore');
  const render=()=>{
    const filtered=S.projects.filter(p=>category==='All'||p.category===category);
    grid.innerHTML=filtered.slice(0,visible).map(projectCard).join('');
    count.textContent=`Showing ${Math.min(visible,filtered.length)} of ${filtered.length} projects`;
    more.hidden=visible>=filtered.length;
  };
  document.querySelectorAll('.filter-btn').forEach(button=>button.addEventListener('click',()=>{
    category=button.dataset.filter;visible=8;
    document.querySelectorAll('.filter-btn').forEach(b=>{b.classList.toggle('selected',b===button);b.setAttribute('aria-pressed',String(b===button))});
    render();
  }));
  more.addEventListener('click',()=>{visible+=8;render()});
}

document.addEventListener('click', async event => {
  const copy = event.target.closest('#copyDiscord');
  if (copy) {
    const status = document.getElementById('discordCopyStatus');
    try {
      if (navigator.clipboard && window.isSecureContext) await navigator.clipboard.writeText('foallow');
      else {
        const input = document.createElement('textarea');
        input.value = 'foallow';
        input.style.position = 'fixed';
        input.style.opacity = '0';
        document.body.append(input);
        input.select();
        if (!document.execCommand('copy')) throw new Error('Copy unavailable');
        input.remove();
      }
      if (status) status.textContent = 'Copied! Paste foallow into Discord’s Add Friend search.';
      const label = copy.querySelector('span');
      if (label) label.textContent = 'Copied!';
    } catch {
      if (status) status.textContent = 'Copy foallow manually and search the username on Discord.';
    }
  }
  const play = event.target.closest('[data-video-launch]');
  if (play) {
    const id = play.dataset.videoLaunch;
    if (!/^[a-zA-Z0-9_-]{11}$/.test(id)) return;
    const frame = play.closest('.foallow-video-frame');
    if (!frame) return;
    frame.innerHTML = `<iframe src="https://www.youtube-nocookie.com/embed/${id}?autoplay=1&rel=0" title="Foallow showcase video" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture; web-share" referrerpolicy="strict-origin-when-cross-origin" allowfullscreen></iframe>`;
  }
});
