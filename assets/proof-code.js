(() => {
  const files = [
    { name: 'CombatHitboxService.luau', label: '01 / COMBAT ENGINE', title: 'Server-authoritative hitboxes', summary: 'Attack definitions and cooldowns stay on the server. One bounded overlap query, unique humanoid hits and clean player-state teardown.', chips: ['Spatial query', 'Hit deduplication', 'Server validation'], note: 'No client-supplied damage. Limited candidate parts and targets per attack.' },
    { name: 'AbilityRunner.luau', label: '02 / ABILITY ENGINE', title: 'Protected ability execution', summary: 'A reusable execution gate handles cooldowns, re-entrancy and isolated callback failures without spinning background loops.', chips: ['Cooldown map', 'Protected calls', 'No polling'], note: 'Register abilities on the server; call Execute only after validating your input RemoteEvent.' },
    { name: 'InventoryService.luau', label: '03 / INVENTORY BACKEND', title: 'Constant-time item transactions', summary: 'Server-owned session inventories with item allowlists, stack limits, transaction checks, immutable snapshots and version numbers.', chips: ['Item lookup', 'Stack limits', 'Immutable snapshot'], note: 'Session-only module. Wire persistence and an authoritative purchase flow into your game.' },
    { name: 'NPCTargetSelector.luau', label: '04 / NPC AI', title: 'Throttled target acquisition', summary: 'NPCs reuse their current target between scans, compare squared distances and avoid per-frame player searches.', chips: ['0.45s refresh', 'Target cache', 'Squared distance'], note: 'This chooses a candidate, not a navigation path. Integrate with pathfinding and line-of-sight rules.' },
    { name: 'DeltaReplicator.luau', label: '05 / NETWORKING', title: 'Batched state replication', summary: 'Only changed, allowlisted values are sent in a 10 Hz server-side batch. Repeated values never generate packets.', chips: ['Dirty fields', '10 Hz batching', 'Server-owned state'], note: 'Client must listen to FoallowStateDelta and obtain a full initial snapshot when ready.' },
  ];

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
})();
