(() => {
  const files = [
    { name: 'CombatHitboxService.luau', label: '01 / SERVER COMBAT PIPELINE', title: 'Server-authoritative melee combat', summary: 'Server-owned five-hit and four-hit combo definitions, finite movement budgets, trusted-position corrections, fault-isolated hit windows and centralized PvP resolution. Ability attacks share the same combat state and resolver.', chips: ['Movement integrity', 'Bounded sweep and timing', 'Server-owned state', 'Measured combat CPU'], note: 'Use the versioned source manifest to review one consistent module set. Studio testing and benchmark output remain required.' },
    { name: 'AbilityRunner.luau', label: '02 / ABILITY ENGINE', title: 'Server-owned ability lifecycle', summary: 'Persistent per-player action ownership, shared combat locks, resource reservation, explicit cooldown commit, bounded callbacks, interruption cancellation, and damage through the centralized combat resolver.', chips: ['Shared combat state', 'Essence reservation', 'Token cancellation', 'Unified PvP rules'], note: 'See the complete server adapter, ability definitions and state tests below. Partial external side effects still need registered cleanup handlers.' },
    { name: 'InventoryService.luau', label: '03 / INVENTORY BACKEND', title: 'Versioned atomic inventory transactions', summary: 'Server-owned inventory sessions with atomic batches, version checks, bounded replay handling, strict item limits and immutable snapshots.', chips: ['Atomic batches', 'Replay guard', 'Version checks'], note: 'Session-only module. Wire persistence and an authoritative purchase flow into your game.' },
    { name: 'NPCTargetSelector.luau', label: '04 / NPC AI', title: 'Throttled target acquisition', summary: 'NPCs reuse valid targets between scans, enforce combat permissions, check visibility and use squared-distance comparisons.', chips: ['PvE permissions', 'Line-of-sight', 'Target cache'], note: 'This selects targets, not navigation routes. Pathfinding and NPC action scheduling remain separate responsibilities.' },
    { name: 'DeltaReplicator.luau', label: '05 / NETWORKING', title: 'Batched state replication', summary: 'Versioned, allowlisted state updates are batched at 10 Hz, with snapshot recovery for late-joining clients and delivery-error recovery.', chips: ['Versioned deltas', 'Snapshot resync', '10 Hz batching'], note: 'A companion client script publishes replicated values as Foallow_* local player attributes for UI use.' },
  ];


  const combatDependencies = [
    { name: 'CombatConfig.luau', title: 'Weapon Profiles', purpose: 'Server-controlled M1 chains, G heavy attacks and timing definitions' },
    { name: 'CombatMovementGuard.luau', title: 'Movement Recovery Service', purpose: 'Continuous sampling, trusted-position corrections and server-authorized displacement' },
    { name: 'CombatMovementBudget.luau', title: 'Finite Movement Budgets', purpose: 'Finite movement tolerance and direction-limited impulses, with server recovery' },
    { name: 'CombatMovementTrustTests.server.luau', title: 'Trusted-Position Integration Test', purpose: 'Studio test for invalid teleport, restoration of trusted position and quarantine expiry' },
    { name: 'CombatMovementBudgetTests.luau', title: 'Movement Budget Regression Suite', purpose: 'Sustained speed abuse, failed teleport, impulse exhaustion and normal movement tests' },
    { name: 'CombatState.luau', title: 'Action State', purpose: 'Combo sequencing, guard meter, status locks, interrupts and cooldowns' },
    { name: 'CombatPolicy.luau', title: 'PvP Permission Checks', purpose: 'Safe, Yellow, Red and Dark zones, opt-in, teams and NPC factions' },
    { name: 'CombatResolver.luau', title: 'Damage Resolution', purpose: 'Shared block, parry, clash, guardbreak and damage pipeline' },
    { name: 'CombatZoneConsequences.luau', title: 'Zone Consequences', purpose: 'Server-owned PvP flags and configurable zone penalties' },
    { name: 'CombatServer.server.luau', title: 'Server Entry Point', purpose: 'Only approved remote actions enter the combat server' },
    { name: 'CombatClientInput.client.luau', title: 'Soul Seas Input Mapping', purpose: 'M1 light combo, M2 parry, G heavy attack and F held guard' },
    { name: 'CombatTimeline.luau', title: 'Hit-window State Machine', purpose: 'A single-use window with bounded marker timing, fallback deadlines and closure' },
    { name: 'CombatWindowScheduler.luau', title: 'Bounded Window Sampling', purpose: 'Immediate scan, monotonic elapsed-time remainder, bounded final scan and one catch-up sample per Heartbeat' },
    { name: 'CombatWindowSchedulerTests.luau', title: 'Sampling Edge-Case Tests', purpose: 'Regression tests for jitter, late frames, one final scan and bounded catch-up' },
    { name: 'CombatSweepPlanner.luau', title: 'Bounded Sweep Planner', purpose: 'Rotation and displacement-based interpolation with explicit rejection of unsupported fast motion' },
    { name: 'CombatSweepPlannerTests.luau', title: 'Sweep Geometry Tests', purpose: 'Translation, rotation, overlong steps and invalid sweep configuration' },
    { name: 'CombatRequestDiagnosticsTests.server.luau', title: 'Rejection Counter Tests', purpose: 'Isolated Studio tests that verify each invalid request is counted once' },
    { name: 'CombatHurtboxIndex.luau', title: 'Indexed Targets', purpose: 'Tracks one queryable root per character and rebuilds the filter only when membership changes' },
    { name: 'CombatSmokeTests.luau', title: 'State & Fallback Tests', purpose: 'Checks combo ordering, timeout fallback, marker single-use, interrupts, guard and NPC permission' },
    { name: 'CombatRegressionTests.server.luau', title: 'Combat Regression Tests', purpose: 'Studio assertions for movement rejection, teleport authorization, parry, guardbreak and damage modifiers' },
    { name: 'CombatLoadProfiler.server.luau', title: 'Combat Pipeline Load Profiler', purpose: '1/5/10/20 real NPC attack contexts, p95 scan, context CPU and full-frame combat CPU timing with separate damage and contact metrics' },
    { name: 'CombatPvPIntegrationTests.server.luau', title: 'Two-player PvP Checks', purpose: 'Real resolver tests for hit, block, parry, clash, guardbreak, safe-zone rejection and separate two-sided flags' },
    { name: 'CombatLiveE2E.server.luau', title: 'Live Client/Server Combat Harness', purpose: 'Opt-in Studio test creates an NPC target and verifies accepted remote inputs, hitbox resolution and cleanup' },
    { name: 'CombatLiveE2E.client.luau', title: 'Actual Client Input Probe', purpose: 'Sends Light, Parry, GuardStart, GuardKeepAlive, GuardEnd and Heavy through the real RemoteEvent' },
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
      <div class="proof-architecture-head"><span>SERVER PIPELINE / SOURCE AND VERIFICATION FILES</span><h4>One combat flow. Shared rules.</h4><p>Client request → trusted movement and state authorization → marker or timed fallback → indexed hit detection → engagement flagging → shared defense and damage resolution.</p></div>
      <div class="proof-architecture-flow"><span>REQUEST</span><i>→</i><span>VALIDATE</span><i>→</i><span>HIT WINDOW</span><i>→</i><span>RESOLVE</span><i>→</i><span>REPLICATE</span></div>
      <div class="proof-dependencies">${combatDependencies.map(entry => `<details class="proof-dependency" data-combat-source="${entry.name}"><summary><span>${entry.title}<small>${entry.purpose}</small></span><b>VIEW SOURCE ＋</b></summary><div class="proof-dependency-code"><div class="proof-dependency-controls"><a href="assets/code/${entry.name}" download>Download .luau ↗</a><button type="button" data-copy-source="${entry.name}" disabled>Copy source</button></div><pre aria-label="${entry.name} source"><code>Expand to load source</code></pre></div></details>`).join('')}</div><p class="proof-code-note"><a href="assets/code/COMBAT-SETUP.md" download>Download the complete integration and test guide ↗</a> · <a href="assets/code/COMBAT-V29-VERIFICATION.md" download>V29 technical review and Studio test plan ↗</a> · <a href="assets/code/COMBAT-V29-MANIFEST.md" download>Canonical source-file manifest ↗</a></p>
    </section>
  `;

  const holder = document.getElementById('proofCodeGallery');
  if (!holder) return;
  holder.insertAdjacentHTML('beforebegin', '<div class="proof-canonical-banner"><span>CODE RELEASE / V29</span><strong>One synchronized source set</strong><p>All files in this release share a versioned manifest. Review the complete server and client call path, then validate its behavior in Roblox Studio.</p><a href="assets/code/COMBAT-V29-MANIFEST.md" download>Download source manifest ↗</a></div>');

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
      ${index === 0 ? combatArchitecture : index === 1 ? abilityArchitecture : index === 4 ? '<p class="proof-code-note"><a href="assets/code/DeltaReplicatorClient.client.luau" download>Download companion client receiver ↗</a> · <a href="assets/code/NETWORKING-SETUP.md" download>Integration guide ↗</a></p>' : index === 2 ? '<p class="proof-code-note"><a href="assets/code/InventoryConsistencyTests.server.luau" download>Download inventory regression checks ↗</a></p>' : ''}
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
