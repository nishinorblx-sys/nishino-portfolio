(() => {
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  document.documentElement.classList.add('motion-enabled');
  const progress = document.createElement('div');
  progress.className = 'scroll-progress';
  progress.setAttribute('aria-hidden', 'true');
  document.body.append(progress);
  const curtain = document.createElement('div');
  curtain.className = 'page-curtain';
  curtain.setAttribute('aria-hidden', 'true');
  document.body.append(curtain);
  const hero = document.querySelector('.hero');
  if (hero) {
    const title = hero.querySelector('h1');
    if (title) {
      title.innerHTML = `<span class="hero-line"><span>Hey, I'm <em>Foallow.</em></span></span><span class="hero-line"><span>Scripts, visuals</span></span><span class="hero-line"><span class="hero-muted">and sound.</span></span>`;
    }
    const art = hero.querySelector('.identity-art');
    if (art) {
      const decor = document.createElement('div');
      decor.innerHTML = '<div class="motion-orbit"><i></i></div><div class="motion-orbit alt"><i></i></div><span class="motion-crosshair c1"></span><span class="motion-crosshair c2"></span>';
      art.append(...decor.children);
    }
    const metrics = document.querySelector('.metrics-section');
    if (metrics) {
      const ticker = document.createElement('div');
      ticker.className = 'motion-ticker';
      ticker.setAttribute('aria-hidden', 'true');
      const sequence = ['ROBLOX DEVELOPMENT', 'LUAU SCRIPTING', 'COMBAT SYSTEMS', 'VFX & UI', 'SOUND DESIGN', 'BUILT TO SHIP'];
      const piece = sequence.map((item,i)=>`<span class="motion-ticker-piece"><i></i>${i%2===0?`<b>${item}</b>`:item}</span>`).join('');
      ticker.innerHTML = `<div class="motion-ticker-track">${piece}${piece}${piece}${piece}</div>`;
      metrics.before(ticker);
    }
  }
  let scrollQueued = false;
  const updateScroll = () => {
    scrollQueued = false;
    const maxScroll = Math.max(1,document.documentElement.scrollHeight-window.innerHeight);
    progress.style.transform = `scaleX(${Math.min(1,scrollY/maxScroll)})`;
    document.body.classList.toggle('has-scrolled',scrollY>40);
  };
  addEventListener('scroll',()=>{
    if (!scrollQueued) {
      scrollQueued = true;
      requestAnimationFrame(updateScroll);
    }
  },{passive:true});
  updateScroll();
  if (!reduce) {
    const groups = ['.section-heading','.sfx-card','.foallow-video-card','.foallow-contact-panel','.metric','.studio-row','.route-tile','.project-card','.featured-game-card','.feature-showcase','.education-card','.review-card','.personal-tile','.split-section','.timeline-item','.client-card','.pricing-card','.step','.proof-card','.faq-item','.term-entry','.info-card','.stats-showcase > div','.review-summary','.faq-group','.dual-cards','.rate-card','.rate-step','.rate-option'];
    const observed = new WeakSet();
    const observer = 'IntersectionObserver' in window ? new IntersectionObserver(entries=>{
      entries.forEach(entry=>{
        if (entry.isIntersecting) {
          entry.target.classList.add('is-visible');
          observer.unobserve(entry.target);
          if (entry.target.classList.contains('metric')) animateNumber(entry.target.querySelector('strong'));
        }
      });
    },{rootMargin:'0px 0px -45px 0px',threshold:.09}) : null;
    const attachReveals = (root=document) => {
      const elements = root.querySelectorAll(groups.join(','));
      const ordered = new Map();
      elements.forEach(el=>{
        if (observed.has(el)) return;
        observed.add(el);
        const parent = el.parentElement;
        const siblingIndex = ordered.get(parent)||0;
        ordered.set(parent,siblingIndex+1);
        el.style.setProperty('--reveal-delay', `${Math.min(siblingIndex%6,5)*90}ms`);
        el.classList.add('motion-reveal');
        if (observer) observer.observe(el);
        else el.classList.add('is-visible');
      });
    };
    const animateNumber = el => {
      if(!el || el.dataset.counted) return;
      el.dataset.counted = 'yes';
      const raw = el.textContent.trim();
      const found = raw.match(/^(\d[\d,.]*)(.*)$/);
      if (!found) return;
      const num = Number(found[1].replace(/,/g,''));
      if (!Number.isFinite(num)) return;
      const decimals = found[1].includes('.') ? found[1].split('.')[1].length : 0;
      const suffix = found[2];
      const start = performance.now();
      const duration = Math.min(1800,Math.max(1000,500+String(num).length*160));
      const render = now => {
        const t = Math.min((now-start)/duration,1);
        const eased = 1-Math.pow(1-t,4);
        const val = num*eased;
        el.textContent = val.toLocaleString('en-US',{minimumFractionDigits:decimals,maximumFractionDigits:decimals})+suffix;
        if (t<1) requestAnimationFrame(render);
        else el.textContent=raw;
      };
      requestAnimationFrame(render);
    };
    attachReveals();
    const tiltSelector = '.identity-card,.project-card,.route-tile,.pricing-card,.sfx-card,.management-card,.management-contact-card,.role-panel,.client-card,.step,.education-card,.review-card,.personal-tile,.proof-card';
    const finePointer = matchMedia('(hover:hover) and (pointer:fine)').matches;
    let tiltEl = null;
    if (finePointer) {
      document.addEventListener('pointermove',e=>{
        const hit = e.target.closest(tiltSelector);
        if (tiltEl && tiltEl!==hit) {
          tiltEl.style.removeProperty('--tilt-x');
          tiltEl.style.removeProperty('--tilt-y');
        }
        tiltEl=hit;
        if (hit) {
          hit.classList.add('tilt-target');
          const rect=hit.getBoundingClientRect();
          const x=(e.clientX-rect.left)/rect.width;
          const y=(e.clientY-rect.top)/rect.height;
          hit.style.setProperty('--tilt-x', `${((.5-y)*5).toFixed(2)}deg`);
          hit.style.setProperty('--tilt-y', `${((x-.5)*5).toFixed(2)}deg`);
          hit.style.setProperty('--mouse-x', `${(x*100).toFixed(1)}%`);
          hit.style.setProperty('--mouse-y', `${(y*100).toFixed(1)}%`);
        }
        if (hero && hero.contains(e.target)) {
          const bounds = hero.getBoundingClientRect();
          hero.style.setProperty('--hero-x',`${((e.clientX-bounds.left)/bounds.width*100).toFixed(1)}%`);
          hero.style.setProperty('--hero-y',`${((e.clientY-bounds.top)/bounds.height*100).toFixed(1)}%`);
        }
      },{passive:true});
      document.addEventListener('pointerleave',()=>{
        if (tiltEl) {
          tiltEl.style.removeProperty('--tilt-x');
          tiltEl.style.removeProperty('--tilt-y');
          tiltEl=null;
        }
      });
    }
    const grid = document.getElementById('projectGrid');
    if (grid) new MutationObserver(()=>attachReveals(grid)).observe(grid,{childList:true});
    document.querySelectorAll('.stats-showcase strong').forEach(el=>{
      const own=el.closest('.stats-showcase > div');
      if (!own) return;
      const statObserver=new IntersectionObserver(entries=>{
        if(entries[0]?.isIntersecting){animateNumber(el);statObserver.disconnect()}
      },{threshold:.3});
      statObserver.observe(own);
    });
  }
  document.addEventListener('click',e=>{
    const anchor=e.target.closest('a[href]');
    if(!anchor || e.defaultPrevented || e.button !==0 || e.metaKey||e.ctrlKey||e.shiftKey||e.altKey||anchor.target||anchor.hasAttribute('download')) return;
    const dest=new URL(anchor.href,location.href);
    const isLocal=dest.origin===location.origin && /\.html$/.test(dest.pathname);
    if(!isLocal || (dest.pathname===location.pathname && dest.search===location.search)) return;
    if(reduce) return;
    e.preventDefault();
    if(document.body.classList.contains('is-leaving')) return;
    document.body.classList.add('is-leaving');
    setTimeout(()=>{location.href=dest.href},390);
  });
})();
