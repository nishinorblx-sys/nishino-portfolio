(() => {
  const loader = document.getElementById('nsPreloader');
  const enter = document.getElementById('nsLoaderEnter');
  const percent = document.getElementById('nsLoaderPercent');
  const fill = document.getElementById('nsLoaderFill');
  const hint = document.getElementById('nsLoaderHint');
  const files = {
    loading: 'assets/audio/Website1.MP3',
    hover: 'assets/audio/Website2.MP3',
    click: 'assets/audio/Website3.MP3'
  };
  const volumes = { loading: .53, hover: .28, click: .42 };
  const minimumGap = { loading: 300, hover: 45, click: 70 };
  const lastPlay = { loading: -Infinity, hover: -Infinity, click: -Infinity };
  const soundPool = {};
  const unavailable = new Set();
  let enabled = true;
  let entered = false;
  let opening = false;
  let loadingInstance = null;
  const reduce = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const getStore = (store, key) => {
    try { return store.getItem(key) } catch { return null }
  };
  const setStore = (store, key, value) => {
    try { store.setItem(key, value) } catch {}
  };
  enabled = getStore(localStorage, 'nishino-sfx') !== 'off';
  entered = getStore(sessionStorage, 'nishino-entered') === 'yes';
  const sound = (type) => {
    if (unavailable.has(type) || !files[type]) return null;
    if (!soundPool[type]) {
      soundPool[type] = Array.from({length: type === 'loading' ? 1 : type === 'hover' ? 2 : 3}, () => {
        const audio = new Audio(files[type]);
        audio.preload = 'auto';
        audio.volume = volumes[type];
        audio.addEventListener('error', () => unavailable.add(type));
        return audio;
      });
    }
    const pool = soundPool[type];
    return pool.find(audio => audio.paused || audio.ended) || pool[0];
  };
  const play = (type) => {
    if (!enabled || unavailable.has(type)) return null;
    const now = performance.now();
    if (now - lastPlay[type] < minimumGap[type]) return null;
    const audio = sound(type);
    if (!audio) return null;
    lastPlay[type] = now;
    try {
      audio.pause();
      audio.currentTime = 0;
      const result = audio.play();
      if (result && typeof result.catch === 'function') result.catch(() => {});
      if (type === 'loading') loadingInstance = audio;
      return audio;
    } catch { return null }
  };
  if (enabled) { sound('click'); sound('loading'); sound('hover'); }
  const stopLoading = () => {
    if (!loadingInstance) return;
    loadingInstance.pause();
    try { loadingInstance.currentTime = 0 } catch {}
    loadingInstance = null;
  };
  const actions = document.querySelector('.header-actions');
  if (actions) {
    const toggle = document.createElement('button');
    toggle.type = 'button';
    toggle.className = 'ns-sound-toggle';
    toggle.setAttribute('aria-label', 'Toggle interface sounds');
    toggle.innerHTML = '<svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round"><path d="M11 5 6 9H3v6h3l5 4V5Z"/><path class="ns-volume-wave" d="M15 9a5 5 0 0 1 0 6m3-9a9 9 0 0 1 0 12"/></svg><span class="ns-sound-label"></span>';
    const update = () => {
      toggle.dataset.muted = String(!enabled);
      toggle.setAttribute('aria-pressed', String(enabled));
      toggle.title = enabled ? 'Mute website sounds' : 'Enable website sounds';
      toggle.querySelector('.ns-sound-label').textContent = enabled ? 'SOUND ON' : 'SOUND OFF';
      toggle.querySelector('.ns-volume-wave').style.opacity = enabled ? '1' : '0.15';
    };
    update();
    actions.prepend(toggle);
    toggle.addEventListener('click', () => {
      enabled = !enabled;
      setStore(localStorage, 'nishino-sfx', enabled ? 'on' : 'off');
      if (!enabled) stopLoading();
      update();
      if (enabled) play('click');
    });
  }
  const hoverTargets = '.desktop-nav a,.mobile-nav a,.filter-btn,.faq-aside a,.studio-row,.route-tile,.project-card,.client-card,.proof-chips span,.mini-tags span,.footer-links a';
  document.addEventListener('pointerover', (event) => {
    if (!entered || loader && !loader.classList.contains('ns-loader-hidden')) return;
    if (event.pointerType && event.pointerType !== 'mouse' && event.pointerType !== 'pen') return;
    const target = event.target.closest(hoverTargets);
    if (!target || target.contains(event.relatedTarget)) return;
    play('hover');
  }, {passive: true});
  document.addEventListener('click', (event) => {
    if (!entered || loader && !loader.classList.contains('ns-loader-hidden')) return;
    const target = event.target;
    if (!(target instanceof Element) || target.closest('.ns-sound-toggle, [disabled], [aria-disabled="true"]')) return;
    play('click');
  }, {capture: true});
  let finishing = false;
  const finish = () => {
    if (!loader || finishing) return;
    finishing = true;
    percent.textContent = '100%';
    fill.style.width = '100%';
    loader.classList.add('ns-loader-hidden');
    document.body.classList.remove('ns-loading-active');
    stopLoading();
    setTimeout(() => loader.remove(), 360);
  };
  const start = () => {
    if (opening) return;
    opening = true;
    entered = true;
    setStore(sessionStorage, 'nishino-entered', 'yes');
    loader.dataset.stage = 'loading';
    document.body.classList.add('ns-loading-active');
    hint.textContent = 'INITIALIZING THE EXPERIENCE';
    const audio = reduce ? null : play('loading');
    const duration = reduce ? 180 : enabled ? 1540 : 520;
    const started = performance.now();
    if (audio) audio.addEventListener('ended', finish, {once: true});
    const animate = (now) => {
      if (finishing) return;
      const t = Math.min(1, (now - started) / duration);
      const eased = 1 - Math.pow(1 - t, 2.3);
      const value = Math.min(100, Math.round(eased * 100));
      percent.textContent = `${value}%`;
      fill.style.width = `${value}%`;
      if (t < 1) requestAnimationFrame(animate);
    };
    requestAnimationFrame(animate);
    setTimeout(finish, duration + 130);
  };
  if (loader && enter) {
    if (entered) {
      loader.remove();
      document.body.classList.remove('ns-loading-active');
    } else {
      loader.dataset.stage = 'enter';
      document.body.classList.add('ns-loading-active');
      enter.addEventListener('click', () => { play('click'); start(); }, {once: true});
    }
  }
})();
