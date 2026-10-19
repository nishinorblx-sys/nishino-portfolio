(() => {
  const files = [
    { name: 'CombatHitboxService.luau', label: '01 / SERVER COMBAT PIPELINE', title: 'Server-authoritative melee combat', summary: 'Server-owned combos and hit windows with marker fallback, indexed target queries, centralized guard/parry/clash resolution, and PvP zone policy. Ability attacks share the same combat state and resolver.', chips: ['Marker fallback', 'Shared action state', 'Central damage rules', 'Server RemoteEvent'], note: 'Explore every combat dependency below, including the server entry point and test harness.' },
    { name: 'AbilityRunner.luau', label: '02 / ABILITY ENGINE', title: 'Server-owned ability lifecycle', summary: 'Persistent per-player action ownership, shared combat locks, resource reservation, explicit cooldown commit, bounded callbacks, interruption cancellation, and damage through the centralized combat resolver.', chips: ['Shared combat state', 'Essence reservation', 'Token cancellation', 'Unified PvP rules'], note: 'See the complete server adapter, ability definitions and state tests below. Partial external side effects still need registered cleanup handlers.' },
    { name: 'InventoryService.luau', label: '03 / INVENTORY BACKEND', title: 'Constant-time item transactions', summary: 'Server-owned session inventories with item allowlists, stack limits, transaction checks, immutable snapshots and version numbers.', chips: ['Item lookup', 'Stack limits', 'Immutable snapshot'], note: 'Session-only module. Wire persistence and an authoritative purchase flow into your game.' },
    { name: 'NPCTargetSelector.luau', label: '04 / NPC AI', title: 'Throttled target acquisition', summary: 'NPCs reuse their current target between scans, compare squared distances and avoid per-frame player searches.', chips: ['0.45s refresh', 'Target cache', 'Squared distance'], note: 'This chooses a candidate, not a navigation path. Integrate with pathfinding and line-of-sight rules.' },
    { name: 'DeltaReplicator.luau', label: '05 / NETWORKING', title: 'Batched state replication', summary: 'Only changed, allowlisted values are sent in a 10 Hz server-side batch. Repeated values never generate packets.', chips: ['Dirty fields', '10 Hz batching', 'Server-owned state'], note: 'Client must listen to FoallowStateDelta and obtain a full initial snapshot when ready.' },
  ];


  const combatDependencies = [
    { name: 'CombatConfig.luau', title: 'Weapon Profiles', purpose: 'Server-controlled M1 chains, M2 attacks and timing definitions' },
    { name: 'CombatState.luau', title: 'Action State', purpose: 'Combo sequencing, guard meter, status locks, interrupts and cooldowns' },
    { name: 'CombatPolicy.luau', title: 'PvP Permission Checks', purpose: 'Safe, Yellow, Red and Dark zones, opt-in, teams and NPC factions' },
    { name: 'CombatResolver.luau', title: 'Damage Resolution', purpose: 'Shared block, parry, clash, guardbreak and damage pipeline' },
    { name: 'CombatZoneConsequences.luau', title: 'Zone Consequences', purpose: 'Server-owned PvP flags and configurable zone penalties' },
    { name: 'CombatServer.server.luau', title: 'Server Entry Point', purpose: 'Only approved remote actions enter the combat server' },
    { name: 'CombatTimeline.luau', title: 'Hit-window State Machine', purpose: 'A single-use window with bounded marker timing, fallback deadlines and closure' },
    { name: 'CombatHurtboxIndex.luau', title: 'Indexed Targets', purpose: 'Tracks one queryable root per character and rebuilds the filter only when membership changes' },
    { name: 'CombatSmokeTests.luau', title: 'State & Fallback Tests', purpose: 'Checks combo ordering, timeout fallback, marker single-use, interrupts, guard and NPC permission' },
  ];

  const abilityDependencies = [
    { name: 'CombatState.luau', title: 'Shared Action Authority', purpose: 'Rejects simultaneous attacks, guards and abilities; owns status locks, Essence and tokens' },
    { name: 'CombatResolver.luau', title: 'Shared Damage Rules', purpose: 'Abilities use the same PvP, parry, clash, guardbreak and damage pipeline as weapons' },
    { name: 'AbilityDefinitions.luau', title: 'Server Ability Definitions', purpose: 'EmberStrike and Focus examples showing commit, delayed hit windows and explicit completion' },
    { name: 'AbilityServer.server.luau', title: 'Ability RemoteEvent Gateway', purpose: 'Allowlisted ability names, bounded input, player setup and server-only registration' },
    { name: 'AbilityStateTests.luau', title: 'Ability Action-State Tests', purpose: 'Checks resource reservation, cross-system locks, recovery, interrupts and hit windows' },
    { name: 'AbilityIntegrationTests.server.luau', title: 'Studio Integration Tests', purpose: 'Runs activation, action exclusion, and pre/post-commit failure tests with a real Studio player' },
  ];

  const abilityArchitecture = `
    <section class="proof-architecture" aria-label="Ability system architecture">
      <div class="proof-architecture-head"><span>SERVER LIFECYCLE / SIX SUPPORTING FILES</span><h4>Abilities cannot bypass combat.</h4><p>Client request → shared action lock and Essence reservation → registered ability callback → explicit commit → timed validated effects → completion or cancellation → recovery.</p></div>
      <div class="proof-architecture-flow"><span>AUTHORIZE</span><i>→</i><span>RESERVE</span><i>→</i><span>COMMIT</span><i>→</i><span>EXECUTE</span><i>→</i><span>CLEANUP</span></div>
      <div class="proof-dependencies">${abilityDependencies.map(entry => `<details class="proof-dependency" data-combat-source="${entry.name}"><summary><span>${entry.title}<small>${entry.purpose}</small></span><b>VIEW SOURCE ＋</b></summary><div class="proof-dependency-code"><div class="proof-dependency-controls"><a href="assets/code/${entry.name}" download>Download .luau ↗</a><button type="button" data-copy-source="${entry.name}" disabled>Copy source</button></div><pre aria-label="${entry.name} source"><code>Expand to load source</code></pre></div></details>`).join('')}</div><p class="proof-code-note"><a href="assets/code/ABILITY-SETUP.md" download>Download ability integration and failure-policy guide ↗</a></p>
    </section>
  `;

  const combatArchitecture = `
    <section class="proof-architecture" aria-label="Combat system architecture">
      <div class="proof-architecture-head"><span>SERVER PIPELINE / NINE SUPPORTING FILES</span><h4>One combat flow. Shared rules.</h4><p>Client request → validated weapon and combo → animation marker or timed fallback → indexed hit detection → shared PvP and defense rules → damage resolution.</p></div>
      <div class="proof-architecture-flow"><span>REQUEST</span><i>→</i><span>VALIDATE</span><i>→</i><span>HIT WINDOW</span><i>→</i><span>RESOLVE</span><i>→</i><span>REPLICATE</span></div>
      <div class="proof-dependencies">${combatDependencies.map(entry => `<details class="proof-dependency" data-combat-source="${entry.name}"><summary><span>${entry.title}<small>${entry.purpose}</small></span><b>VIEW SOURCE ＋</b></summary><div class="proof-dependency-code"><div class="proof-dependency-controls"><a href="assets/code/${entry.name}" download>Download .luau ↗</a><button type="button" data-copy-source="${entry.name}" disabled>Copy source</button></div><pre aria-label="${entry.name} source"><code>Expand to load source</code></pre></div></details>`).join('')}</div><p class="proof-code-note"><a href="assets/code/COMBAT-SETUP.md" download>Download the complete integration and test guide ↗</a> · <a href="assets/code/EVALUATOR-RESPONSE.md" download>Read the code review response ↗</a></p>
    </section>
  `;

  const holder = document.getElementById('proofCodeGallery');
  if (!holder) return;

  const escapeHtml = text => text.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;').replace(/'/g, '&#39;');
  const tokenPattern = /("(?:\\.|[^"\\])*"|'(?:\\.|[^'\\])*')|\b(local|function|return|if|then|else|elseif|end|for|in|do|while|break|not|and|or|nil|true|false|continue|type|assert|repeat|until)\b|\b(\d+(?:\.\d+)?)\b/g;

  const renderLine = (line, index) => {
    let output = '';
    let previous = 0;
    tokenPattern.lastIndex = 0;
    let token;
    while ((token = tokenPattern.exec(line)) !== null) {
      output += escapeHtml(line.slice(previous, token.index));
      const tone = token[1] ? 'string' : token[2] ? 'keyword' : 'number';
      output += `<span class="proof-syntax-${tone}">${escapeHtml(token[0])}</span>`;
      previous = tokenPattern.lastIndex;
    }
    output += escapeHtml(line.slice(previous));
    return `<span class="proof-code-line"><span class="proof-line-number" aria-hidden="true">${index + 1}</span><span class="proof-line-source">${output || ' '}</span></span>`;
  };

  holder.innerHTML = files.map((entry, index) => `
    <article class="proof-code-item" data-code-file="${entry.name}" id="proof-sample-${index + 1}">
      <div class="proof-code-heading"><span class="proof-code-kicker">${entry.label}</span><span class="proof-code-state"><span class="proof-code-state-dot"></span> LUAU / MODULESCRIPT</span></div>
      <div class="proof-code-intro"><div><h3>${entry.title}</h3><p>${entry.summary}</p></div><span class="proof-code-glyph">${String(index + 1).padStart(2,'0')}</span></div>
      <div class="proof-code-chips">${entry.chips.map(chip => `<span>${chip}</span>`).join('')}</div>
      <div class="proof-editor"><div class="proof-editor-bar"><div class="proof-editor-circles"><i></i><i></i><i></i></div><span>assets/code/${entry.name}</span><span class="proof-editor-language">Luau</span></div><div class="proof-editor-scroller"><pre aria-label="Code sample for ${entry.title}"><code class="proof-code-lines">Loading source...</code></pre></div></div>
      <div class="proof-code-actions"><button type="button" class="proof-code-button" data-action="expand" disabled>View full source</button><button type="button" class="proof-code-button" data-action="copy" disabled>Copy code</button><a class="proof-code-link" href="assets/code/${entry.name}" download>Download .luau ↗</a></div>
      <p class="proof-code-note">${entry.note}</p>
      ${index === 0 ? combatArchitecture : index === 1 ? abilityArchitecture : ''}
    </article>
  `).join('');

  holder.querySelectorAll('.proof-code-item').forEach(async (card, index) => {
    const file = files[index];
    const pre = card.querySelector('pre');
    const code = card.querySelector('code');
    const expand = card.querySelector('[data-action="expand"]');
    const copy = card.querySelector('[data-action="copy"]');
    let text;
    try {
      const response = await fetch(`assets/code/${file.name}`);
      if (!response.ok) throw new Error('Source unavailable');
      text = (await response.text()).replace(/\r\n?/g, '\n');
    } catch {
      code.textContent = 'Source could not be loaded. Use Download .luau to access the file.';
      return;
    }
    const lines = text.trimEnd().split('\n');
    let expanded = false;
    const draw = () => {
      const visible = expanded ? lines : lines.slice(0, 24);
      code.innerHTML = visible.map(renderLine).join('');
      pre.dataset.expanded = String(expanded);
      expand.textContent = expanded ? 'Collapse source' : `View all ${lines.length} lines`;
      expand.setAttribute('aria-expanded', String(expanded));
    };
    draw();
    expand.disabled = false;
    copy.disabled = false;
    expand.addEventListener('click', () => {
      expanded = !expanded;
      draw();
    });
    copy.addEventListener('click', async () => {
      try {
        await navigator.clipboard.writeText(text);
        copy.textContent = 'Copied';
        setTimeout(() => { copy.textContent = 'Copy code' }, 1500);
      } catch {
        copy.textContent = 'Use download';
      }
    });
  });
  holder.querySelectorAll('.proof-dependency').forEach(panel => {
    panel.addEventListener('toggle', async () => {
      if (!panel.open || panel.dataset.loaded === 'true') return;
      panel.dataset.loaded = 'true';
      const name = panel.dataset.combatSource;
      const code = panel.querySelector('code');
      const copy = panel.querySelector('[data-copy-source]');
      try {
        const response = await fetch(`assets/code/${name}`);
        if (!response.ok) throw new Error('Source unavailable');
        const source = (await response.text()).replace(/\r\n?/g, '\n');
        code.innerHTML = source.trimEnd().split('\n').map(renderLine).join('');
        copy.disabled = false;
        copy.addEventListener('click', async () => {
          try {
            await navigator.clipboard.writeText(source);
            copy.textContent = 'Copied';
            setTimeout(() => { copy.textContent = 'Copy source'; }, 1400);
          } catch {
            copy.textContent = 'Use download';
          }
        });
      } catch {
        code.textContent = 'Source unavailable. Download the module to view it.';
        panel.dataset.loaded = 'false';
      }
    });
  });
})();
