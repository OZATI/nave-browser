// Nave Browser - Controlador da Barra Lateral de Guias (Vertical Tabs)
let currentFilter = '';
let currentView = 'tabs'; // 'tabs' | 'hub'

// Elementos DOM
const tabSearch = document.getElementById('tabSearch');
const tabsList = document.getElementById('tabsList');
const pinnedGrid = document.getElementById('pinnedGrid');
const pinnedSection = document.getElementById('pinnedSection');
const tabsCountBadge = document.getElementById('tabsCountBadge');
const btnNewTabHeader = document.getElementById('btnNewTabHeader');
const btnToggleTabs = document.getElementById('btnToggleTabs');
const btnToggleHub = document.getElementById('btnToggleHub');
const tabsContainer = document.getElementById('tabsContainer');
const hubContainer = document.getElementById('hubContainer');
const btnCleanDuplicates = document.getElementById('btnCleanDuplicates');

// 1. Renderização das Guias
async function renderTabs() {
  try {
    const tabs = await chrome.tabs.query({ currentWindow: true });
    if (!tabs) return;

    tabsCountBadge.textContent = tabs.length;

    const pinnedTabs = tabs.filter(t => t.pinned);
    const normalTabs = tabs.filter(t => {
      if (t.pinned) return false;
      if (!currentFilter) return true;
      const q = currentFilter.toLowerCase();
      const title = (t.title || '').toLowerCase();
      const url = (t.url || '').toLowerCase();
      return title.includes(q) || url.includes(q);
    });

    // Renderizar Pinned Tabs
    if (pinnedTabs.length > 0) {
      pinnedSection.style.display = 'flex';
      pinnedGrid.innerHTML = pinnedTabs.map(tab => `
        <div class="pinned-item ${tab.active ? 'active' : ''}" data-tab-id="${tab.id}" title="${escapeHtml(tab.title)}">
          <img class="pinned-favicon" src="${getFaviconUrl(tab)}" alt="" onerror="this.src='icons/nave-16.png'" />
        </div>
      `).join('');
    } else {
      pinnedSection.style.display = 'none';
    }

    // Renderizar Normal Tabs
    if (normalTabs.length === 0) {
      tabsList.innerHTML = `
        <div style="text-align: center; padding: 24px 12px; color: var(--text-dim); font-size: 0.78rem;">
          ${currentFilter ? 'Nenhuma guia encontrada para o filtro.' : 'Nenhuma guia aberta.'}
        </div>
      `;
      return;
    }

    tabsList.innerHTML = normalTabs.map(tab => {
      const displayUrl = formatDisplayUrl(tab.url);
      const isAudible = tab.audible;
      const isMuted = tab.mutedInfo && tab.mutedInfo.muted;

      return `
        <div class="tab-item ${tab.active ? 'active' : ''}" 
             data-tab-id="${tab.id}" 
             data-window-id="${tab.windowId}" 
             data-index="${tab.index}" 
             draggable="true">
          <img class="tab-favicon" src="${getFaviconUrl(tab)}" alt="" onerror="this.src='icons/nave-16.png'" />
          <div class="tab-info">
            <span class="tab-title" title="${escapeHtml(tab.title)}">${escapeHtml(tab.title || 'Nova Guia')}</span>
            ${displayUrl ? `<span class="tab-url-hint">${escapeHtml(displayUrl)}</span>` : ''}
          </div>
          <div class="tab-actions">
            ${isAudible || isMuted ? `
              <button class="audio-btn" data-action="audio" data-tab-id="${tab.id}" title="${isMuted ? 'Desmutar guia' : 'Silenciar guia'}">
                ${isMuted ? '🔇' : '🔊'}
              </button>
            ` : ''}
            <button class="btn-close-tab" data-action="close" data-tab-id="${tab.id}" title="Fechar guia (Ctrl+W)">×</button>
          </div>
        </div>
      `;
    }).join('');

    setupDragAndDrop();
  } catch (err) {
    console.error('Erro ao renderizar guias:', err);
  }
}

function getFaviconUrl(tab) {
  if (tab.favIconUrl && !tab.favIconUrl.startsWith('chrome://')) {
    return tab.favIconUrl;
  }
  return 'icons/nave-16.png';
}

function formatDisplayUrl(rawUrl) {
  if (!rawUrl) return '';
  try {
    const parsed = new URL(rawUrl);
    if (parsed.protocol === 'chrome:' || parsed.protocol === 'chrome-extension:') return '';
    return parsed.hostname.replace(/^www\./, '');
  } catch {
    return '';
  }
}

function escapeHtml(str) {
  if (!str) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;');
}

// 2. Ações de Clique em Abas
document.addEventListener('click', async (e) => {
  // Ação de Fechar
  const closeBtn = e.target.closest('[data-action="close"]');
  if (closeBtn) {
    e.stopPropagation();
    const tabId = parseInt(closeBtn.dataset.tabId, 10);
    if (tabId) await chrome.tabs.remove(tabId);
    return;
  }

  // Ação de Áudio (Silenciar/Desmutar)
  const audioBtn = e.target.closest('[data-action="audio"]');
  if (audioBtn) {
    e.stopPropagation();
    const tabId = parseInt(audioBtn.dataset.tabId, 10);
    const tab = await chrome.tabs.get(tabId);
    if (tab) {
      await chrome.tabs.update(tabId, { muted: !tab.mutedInfo.muted });
    }
    return;
  }

  // Clicar em Guia Normal
  const tabItem = e.target.closest('.tab-item');
  if (tabItem) {
    const tabId = parseInt(tabItem.dataset.tabId, 10);
    if (tabId) {
      await chrome.tabs.update(tabId, { active: true });
    }
    return;
  }

  // Clicar em Guia Fixada
  const pinnedItem = e.target.closest('.pinned-item');
  if (pinnedItem) {
    const tabId = parseInt(pinnedItem.dataset.tabId, 10);
    if (tabId) {
      await chrome.tabs.update(tabId, { active: true });
    }
    return;
  }
});

// Clique com botão do meio (roda) fecha a aba
document.addEventListener('auxclick', async (e) => {
  if (e.button === 1) { // Middle click
    const item = e.target.closest('.tab-item, .pinned-item');
    if (item && item.dataset.tabId) {
      e.preventDefault();
      await chrome.tabs.remove(parseInt(item.dataset.tabId, 10));
    }
  }
});

// 3. Nova Guia (+)
btnNewTabHeader.addEventListener('click', () => {
  chrome.tabs.create({});
});

// 4. Limpar Duplicadas
btnCleanDuplicates.addEventListener('click', async () => {
  const tabs = await chrome.tabs.query({ currentWindow: true });
  const seenUrls = new Set();
  const toRemove = [];

  for (const tab of tabs) {
    if (!tab.url || tab.url.startsWith('chrome://newtab') || tab.pinned) continue;
    if (seenUrls.has(tab.url)) {
      toRemove.push(tab.id);
    } else {
      seenUrls.add(tab.url);
    }
  }

  if (toRemove.length > 0) {
    await chrome.tabs.remove(toRemove);
  }
});

// 5. Filtro / Pesquisa
tabSearch.addEventListener('input', (e) => {
  currentFilter = e.target.value.trim();
  renderTabs();
});

// Atalho Escape para limpar busca
tabSearch.addEventListener('keydown', (e) => {
  if (e.key === 'Escape') {
    tabSearch.value = '';
    currentFilter = '';
    renderTabs();
  }
});

// 6. Alternar Guias / Hub de Produtividade
btnToggleTabs.addEventListener('click', () => {
  currentView = 'tabs';
  btnToggleTabs.classList.add('active');
  btnToggleHub.classList.remove('active');
  tabsContainer.style.display = 'flex';
  hubContainer.style.display = 'none';
});

btnToggleHub.addEventListener('click', () => {
  currentView = 'hub';
  btnToggleHub.classList.add('active');
  btnToggleTabs.classList.remove('active');
  tabsContainer.style.display = 'none';
  hubContainer.style.display = 'flex';
});

// 7. Drag & Drop Reordering
let draggedTabId = null;

function setupDragAndDrop() {
  const items = tabsList.querySelectorAll('.tab-item');
  items.forEach(item => {
    item.addEventListener('dragstart', (e) => {
      draggedTabId = parseInt(item.dataset.tabId, 10);
      item.classList.add('dragging');
      e.dataTransfer.effectAllowed = 'move';
      e.dataTransfer.setData('text/plain', item.dataset.tabId);
    });

    item.addEventListener('dragend', () => {
      item.classList.remove('dragging');
      items.forEach(el => el.classList.remove('drag-over'));
      draggedTabId = null;
    });

    item.addEventListener('dragover', (e) => {
      e.preventDefault();
      e.dataTransfer.dropEffect = 'move';
      item.classList.add('drag-over');
    });

    item.addEventListener('dragleave', () => {
      item.classList.remove('drag-over');
    });

    item.addEventListener('drop', async (e) => {
      e.preventDefault();
      item.classList.remove('drag-over');
      const targetIndex = parseInt(item.dataset.index, 10);
      if (draggedTabId !== null) {
        await chrome.tabs.move(draggedTabId, { index: targetIndex });
        renderTabs();
      }
    });
  });
}

// 8. Bloco de Notas Local (Hub)
const quickNotes = document.getElementById('quickNotes');
const noteCharCount = document.getElementById('noteCharCount');
if (quickNotes) {
  quickNotes.value = localStorage.getItem('nave_side_notes') || '';
  if (noteCharCount) noteCharCount.textContent = quickNotes.value.length + ' carac.';

  quickNotes.addEventListener('input', () => {
    localStorage.setItem('nave_side_notes', quickNotes.value);
    if (noteCharCount) noteCharCount.textContent = quickNotes.value.length + ' carac.';
  });
}

// 9. Event Listeners Reativos do Chromium (Zero Delay)
chrome.tabs.onCreated.addListener(renderTabs);
chrome.tabs.onRemoved.addListener(renderTabs);
chrome.tabs.onUpdated.addListener((tabId, changeInfo) => {
  if (changeInfo.title || changeInfo.favIconUrl || changeInfo.status || changeInfo.audible !== undefined || changeInfo.mutedInfo) {
    renderTabs();
  }
});
chrome.tabs.onActivated.addListener(renderTabs);
chrome.tabs.onMoved.addListener(renderTabs);

// Iniciar renderização imediata
renderTabs();
