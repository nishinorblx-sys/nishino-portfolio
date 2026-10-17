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
  const volumes = { loading: .53, hover: .34, click: .44 };
  const minimumGap = { loading: 250, hover: 35, click: 55 };
  const lastPlay = { loading: -Infinity, hover: -Infinity, click: -Infinity };
  const pools = {};
  const buffers = {};
  const pending = {};
  let audioContext = null;
  let enabled = true;
  let entered = false;
  let opening = false;
  let loadingInstance = null;
  let finishing = false;
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)').matches;
  const readPreference = (store, key) => {
    try { return window[store].getItem(key) } catch { return null }
  };
  const savePreference = (store, key, value) => {
    try { window[store].setItem(key, value) } catch {}
  };
  enabled = readPreference('localStorage', 'nishino-sfx') !== 'off';
  entered = readPreference('sessionStorage', 'nishino-entered') === 'yes';
  const createContext = () => {
    if (audioContext) return audioContext;
    const Ctor = window.AudioContext || window.webkitAudioContext;
    if (!Ctor) return null;
    try { audioContext = new Ctor() } catch { return null }
    return audioContext;
  };
  const unlock = () => {
    if (!enabled) return;
    const context = createContext();
    if (!context) return;
    if (context.state === 'suspended') context.resume().catch(() => {});
    for (const type of ['hover', 'click']) {
      if (buffers[type] || pending[type]) continue;
      pending[type] = fetch(files[type])
        .then(result => {
          if (!result.ok) throw new Error('Sound unavailable');
          return result.arrayBuffer();
        })
        .then(bytes => context.decodeAudioData(bytes))
        .then(buffer => { buffers[type] = buffer })
        .catch(() => null)
        .finally(() => { delete pending[type] });
    }
  };
  const getHTMLAudio = type => {
    if (!pools[type]) {
      pools[type] = Array.from({length: type === 'loading' ? 1 : 5}, () => {
        const instance = new Audio(files[type]);
        instance.preload = 'auto';
        instance.volume = volumes[type];
        return instance;
      });
    }
    return pools[type].find(instance => instance.paused || instance.ended) || pools[type][0];
  };
  const play = (type, force = false) => {
    if (!enabled || !files[type]) return null;
    const now = performance.now();
    if (!force && now - lastPlay[type] < minimumGap[type]) return null;
    lastPlay[type] = now;
    if (type !== 'loading') {
      const context = createContext();
      if (context && context.state === 'running' && buffers[type]) {
        try {
          const source = context.createBufferSource();
          const gain = context.createGain();
          source.buffer = buffers[type];
          gain.gain.value = volumes[type];
          source.connect(gain);
          gain.connect(context.destination);
          source.start();
          return source;
        } catch {}
      }
    }
    const instance = getHTMLAudio(type);
    try {
      instance.pause();
      instance.currentTime = 0;
      const result = instance.play();
      if (result && typeof result.catch === 'function') result.catch(() => {});
      if (type === 'loading') loadingInstance = instance;
      return instance;
    } catch { return null }
  };
  for (const type of ['hover', 'click', 'loading']) getHTMLAudio(type);
  document.addEventListener('pointerdown', unlock, {capture: true, passive: true});
  document.addEventListener('keydown', unlock, {capture: true});
  document.addEventListener('visibilitychange', () => {
    if (document.visibilityState === 'visible' && enabled && audioContext?.state === 'suspended') audioContext.resume().catch(() => {});
  });
  window.NISHINO_AUDIO = { play, unlock, get enabled() { return enabled } };
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
    const sync = () => {
      toggle.dataset.muted = String(!enabled);
      toggle.setAttribute('aria-pressed', String(enabled));
      toggle.title = enabled ? 'Mute website sounds' : 'Enable website sounds';
      toggle.querySelector('.ns-sound-label').textContent = enabled ? 'SOUND ON' : 'SOUND OFF';
      toggle.querySelector('.ns-volume-wave').style.opacity = enabled ? '1' : '.15';
    };
    actions.prepend(toggle);
    sync();
    toggle.addEventListener('click', () => {
      enabled = !enabled;
      savePreference('localStorage', 'nishino-sfx', enabled ? 'on' : 'off');
      if (!enabled) stopLoading();
      sync();
      if (enabled) { unlock(); play('click', true) }
    });
  }
  const hoverTargets = '.desktop-nav a,.mobile-nav a,.filter-btn,.faq-aside a,.studio-row,.route-tile,.project-card,.client-card,.proof-chips span,.mini-tags span,.footer-links a,.management-card,.management-contact-card,.role-panel,.sfx-card,.sfx-preview-button,.nishino-explore-card';
  document.addEventListener('pointerover', event => {
    if (!entered || loader && !loader.classList.contains('ns-loader-hidden')) return;
    if (event.pointerType && event.pointerType !== 'mouse' && event.pointerType !== 'pen') return;
    if (!(event.target instanceof Element)) return;
    const target = event.target.closest(hoverTargets);
    if (!target || target.contains(event.relatedTarget)) return;
    play('hover');
  }, {passive: true});
  document.addEventListener('click', event => {
    if (!entered || loader && !loader.classList.contains('ns-loader-hidden')) return;
    if (!(event.target instanceof Element) || event.target.closest('.ns-sound-toggle,[data-sfx-preview],[disabled],[aria-disabled="true"]')) return;
    play('click');
  }, {capture: true});
  document.querySelectorAll('[data-sfx-preview]').forEach(button => {
    button.addEventListener('click', () => {
      if (!enabled) {
        const toggle = document.querySelector('.ns-sound-toggle');
        if (toggle) { toggle.focus(); toggle.title = 'Enable SOUND ON to hear previews' }
        return;
      }
      unlock();
      const type = button.dataset.sfxPreview;
      const result = play(type, true);
      if (!result) return;
      button.classList.add('is-playing');
      setTimeout(() => button.classList.remove('is-playing'), type === 'loading' ? 1550 : 300);
    });
  });
  const finish = () => {
    if (!loader || finishing) return;
    finishing = true;
    if (percent) percent.textContent = '100%';
    if (fill) fill.style.width = '100%';
    loader.classList.add('ns-loader-hidden');
    document.body.classList.remove('ns-loading-active');
    stopLoading();
    setTimeout(() => loader.remove(), 360);
  };
  const start = () => {
    if (opening) return;
    opening = true;
    entered = true;
    savePreference('sessionStorage', 'nishino-entered', 'yes');
    loader.dataset.stage = 'loading';
    document.body.classList.add('ns-loading-active');
    if (hint) hint.textContent = 'INITIALIZING THE EXPERIENCE';
    const instance = reducedMotion ? null : play('loading');
    const duration = reducedMotion ? 180 : enabled ? 1540 : 520;
    const started = performance.now();
    if (instance) instance.addEventListener('ended', finish, {once: true});
    const animate = now => {
      if (finishing) return;
      const t = Math.min(1, (now - started) / duration);
      const eased = 1 - Math.pow(1 - t, 2.3);
      const value = Math.min(100, Math.round(eased * 100));
      if (percent) percent.textContent = value + '%';
      if (fill) fill.style.width = value + '%';
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
      enter.addEventListener('click', () => { play('click'); start() }, {once: true});
    }
  }
})();
