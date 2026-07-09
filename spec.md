# 抖店注册进度追踪面板 — 需求规格

## 业务流程（5 阶段看板）

| # | 列名 | 含义 |
|---|------|------|
| 0 | 资料名单 | 收集客户资料（身份证、银行卡信息） |
| 1 | 审核名单 | 资料发到群里，等待审核 |
| 2 | 已出证 | 审核通过 → 客户签字 → 营业执照下来 |
| 3 | 已扫码 | 老板安排扫抖音二维码，联系客户扫码完成 |
| 4 | 已完结 | 全部完成 |

## 客户字段

| 字段 | 类型 | 说明 |
|------|------|------|
| 姓名 | 文本 | 必填 |
| 当前阶段 | 下拉 | 0-4 |
| 执照类型 | 下拉 | 单个体 / 单个体➕备案 / 单个独➕备案 / 自带电子执照 |
| 银行卡类型 | 下拉 | 一类 / 二类 |
| 出证日期 | 文本 | 推进到"已出证"时自动填当天（如 7.7），可手动改 |
| 预付金额 | 文本 | 留空=无预支 |
| 备注 | 文本 | 可选 |

## 交互逻辑

- **点击卡片** → 弹出编辑弹窗（Glass 风格 Modal）
- **拖拽卡片到另一列** → 推进到对应阶段（静默，不弹提示）
- **hover 卡片右上角** → 显示删除按钮 ✕，点击直接删除（无确认弹窗）
- **列头 📋 复制按钮**（已出证列）→ 一键复制该列全部出证文本
- **列头 💰 预付按钮**（已扫码列）/ Header 预付名单按钮 → 复制已扫码列全部预付文本

## 可复制文本格式

### 出证文本（已出证列）

```
7.7 章足青 单个体 一类 已出
7.3 王天浩 自带电子执照 一类
```

- 执照类型含"自带" → 不加"已出"
- 其余 → 结尾加"已出"
- 每张卡片上显示绿色可复制条，点击单条复制该行

### 预付文本（已扫码列）

```
钟俊森 预支30 未收
陆欣妍 🈚️预支 未收
```

- 有预付金额 → `姓名 预支X 未收`
- 无预付 → `姓名 🈚️预支 未收`

## UI 要求

- Apple 风格：玻璃质感（backdrop-filter blur）、大圆角、柔和阴影
- 5 列自适应屏幕宽度（`flex: 1`），不横向滚动
- 按钮隐藏时 `pointer-events: none`，防误触
- localStorage 持久化，刷新不丢数据
- 顶部统计条可点击筛选某阶段
- 搜索框按姓名搜索
- 导出 CSV 功能
- 首次打开自动填充 8 条演示数据

## 技术栈

- 单文件 HTML（CSS + JS 内联）
- 无框架，原生 JavaScript
- 数据存 localStorage
- 旧 9 阶段数据自动迁移（仅一次）

---

# 当前代码

`D:\demo\index.html` ：

```html
<!DOCTYPE html>
<html lang="zh-CN">
<head>
<meta charset="UTF-8">
<meta name="viewport" content="width=device-width, initial-scale=1.0">
<title>抖店注册 · 进度追踪</title>
<style>
/* ============================================================
   APPLE-STYLE DESIGN SYSTEM
   ============================================================ */
:root {
  --blue: #007AFF;
  --blue-hover: #0062CC;
  --blue-light: rgba(0,122,255,0.12);
  --green: #34C759;
  --green-light: rgba(52,199,89,0.12);
  --orange: #FF9500;
  --orange-light: rgba(255,149,0,0.12);
  --red: #FF3B30;
  --red-light: rgba(255,59,48,0.12);
  --purple: #AF52DE;
  --purple-light: rgba(175,82,222,0.12);
  --teal: #5AC8FA;
  --teal-light: rgba(90,200,250,0.12);
  --indigo: #5856D6;
  --indigo-light: rgba(88,86,214,0.12);
  --gray-100: #F5F5F7;
  --gray-200: #E8E8ED;
  --gray-300: #D2D2D7;
  --gray-400: #AEAEB2;
  --gray-500: #8E8E93;
  --gray-600: #636366;
  --gray-700: #48484A;
  --gray-800: #363639;
  --gray-900: #1D1D1F;
  --glass-bg: rgba(255,255,255,0.72);
  --glass-bg-strong: rgba(255,255,255,0.85);
  --glass-border: rgba(255,255,255,0.6);
  --glass-shadow: 0 8px 32px rgba(0,0,0,0.06), 0 2px 8px rgba(0,0,0,0.04);
  --glass-shadow-hover: 0 16px 48px rgba(0,0,0,0.10), 0 4px 16px rgba(0,0,0,0.06);
  --card-radius: 12px;
  --column-radius: 16px;
  --transition-fast: 0.18s cubic-bezier(0.25, 0.1, 0.25, 1);
  --transition-smooth: 0.32s cubic-bezier(0.25, 0.1, 0.25, 1);
  --transition-spring: 0.45s cubic-bezier(0.22, 0.61, 0.36, 1);
}
*, *::before, *::after { box-sizing: border-box; margin: 0; padding: 0; }
html {
  font-family: -apple-system, BlinkMacSystemFont, "SF Pro Display", "SF Pro Text",
    "Helvetica Neue", "PingFang SC", "Noto Sans SC", sans-serif;
  font-size: 14px;
  -webkit-font-smoothing: antialiased;
  -moz-osx-font-smoothing: grayscale;
  letter-spacing: -0.01em;
}
body {
  min-height: 100vh;
  background: #F2F2F7;
  background-image:
    radial-gradient(ellipse 80% 60% at 20% 20%, rgba(0,122,255,0.06) 0%, transparent 60%),
    radial-gradient(ellipse 60% 50% at 80% 60%, rgba(175,82,222,0.05) 0%, transparent 60%),
    radial-gradient(ellipse 50% 40% at 50% 100%, rgba(255,149,0,0.04) 0%, transparent 60%);
  overflow: hidden;
  color: var(--gray-900);
  user-select: none;
  -webkit-user-select: none;
}
.bg-orb {
  position: fixed; border-radius: 50%; filter: blur(120px);
  pointer-events: none; z-index: 0; opacity: 0.5;
}
.bg-orb--1 { width: 600px; height: 600px; background: rgba(0,122,255,0.12); top: -200px; left: -150px; }
.bg-orb--2 { width: 500px; height: 500px; background: rgba(175,82,222,0.10); bottom: -200px; right: -150px; }
.bg-orb--3 { width: 400px; height: 400px; background: rgba(255,149,0,0.08); top: 40%; left: 50%; }

.app { position: relative; z-index: 1; display: flex; flex-direction: column; height: 100vh; }

/* Header */
.header {
  display: flex; align-items: center; justify-content: space-between;
  padding: 10px 20px; gap: 16px; flex-shrink: 0; z-index: 10;
}
.header-left { display: flex; align-items: center; gap: 10px; }
.header-logo {
  width: 32px; height: 32px;
  background: linear-gradient(135deg, var(--blue), #5856D6);
  border-radius: 9px;
  display: flex; align-items: center; justify-content: center;
  color: #fff; font-size: 15px;
  box-shadow: 0 3px 10px rgba(0,122,255,0.3);
}
.header-title { font-size: 18px; font-weight: 700; color: var(--gray-900); letter-spacing: -0.02em; }
.header-right { display: flex; align-items: center; gap: 12px; }

/* Search */
.search-input {
  width: 200px; height: 32px; padding: 0 14px 0 34px;
  background: rgba(255,255,255,0.6); backdrop-filter: blur(12px);
  border: 1px solid rgba(0,0,0,0.08); border-radius: 9px;
  font-size: 13px; font-family: inherit; color: var(--gray-900); outline: none;
  transition: all var(--transition-smooth);
}
.search-input:focus {
  background: rgba(255,255,255,0.9); width: 240px;
  border-color: rgba(0,122,255,0.3); box-shadow: 0 0 0 3px rgba(0,122,255,0.1);
}

/* Buttons */
.btn {
  display: inline-flex; align-items: center; gap: 5px;
  height: 32px; padding: 0 14px; border: none; border-radius: 9px;
  font-size: 13px; font-weight: 590; font-family: inherit;
  cursor: pointer; transition: all var(--transition-smooth);
  letter-spacing: -0.01em; white-space: nowrap;
}
.btn:active { transform: scale(0.96); }
.btn--primary { background: var(--blue); color: #fff; box-shadow: 0 2px 8px rgba(0,122,255,0.25); }
.btn--primary:hover { background: var(--blue-hover); box-shadow: 0 4px 16px rgba(0,122,255,0.35); }
.btn--ghost {
  background: rgba(255,255,255,0.55); backdrop-filter: blur(12px);
  border: 1px solid rgba(0,0,0,0.06); color: var(--gray-700);
}
.btn--ghost:hover { background: rgba(255,255,255,0.8); }

/* Stats Strip */
.stats-strip { display: flex; gap: 8px; padding: 0 20px 8px; overflow-x: auto; flex-shrink: 0; }
.stat-pill {
  display: flex; align-items: center; gap: 6px; padding: 5px 12px;
  background: var(--glass-bg); backdrop-filter: blur(16px);
  border: 1px solid var(--glass-border); border-radius: 10px;
  font-size: 12px; font-weight: 550; color: var(--gray-700);
  white-space: nowrap; flex-shrink: 0; cursor: pointer;
  box-shadow: 0 2px 8px rgba(0,0,0,0.03);
  transition: all var(--transition-smooth);
}
.stat-pill:hover { box-shadow: var(--glass-shadow-hover); transform: translateY(-1px); }
.stat-pill--active { background: rgba(0,122,255,0.1); border-color: rgba(0,122,255,0.25); color: var(--blue); }
.stat-dot { width: 8px; height: 8px; border-radius: 50%; flex-shrink: 0; }
.stat-count { font-size: 16px; font-weight: 700; min-width: 20px; text-align: center; }

/* Kanban */
.kanban {
  flex: 1; display: flex; gap: 10px; padding: 0 20px 16px;
  overflow: hidden; scroll-behavior: smooth;
}

/* Column */
.column {
  flex: 1; min-width: 200px; max-width: 100%;
  display: flex; flex-direction: column;
  background: rgba(255,255,255,0.45); backdrop-filter: blur(24px);
  border: 1px solid rgba(255,255,255,0.7); border-radius: var(--column-radius);
  box-shadow: 0 4px 24px rgba(0,0,0,0.04), inset 0 1px 0 rgba(255,255,255,0.6);
  transition: all var(--transition-smooth); overflow: hidden;
}
.column--drag-over {
  background: rgba(0,122,255,0.06); border-color: rgba(0,122,255,0.3);
  box-shadow: 0 0 0 3px rgba(0,122,255,0.08), 0 4px 24px rgba(0,0,0,0.04);
}
.column-header { display: flex; align-items: center; justify-content: space-between; padding: 10px 12px 8px; flex-shrink: 0; }
.column-icon { width: 26px; height: 26px; border-radius: 7px; display: flex; align-items: center; justify-content: center; font-size: 13px; }
.column-title { font-size: 12px; font-weight: 640; color: var(--gray-800); }
.column-count { font-size: 11px; font-weight: 600; padding: 1px 7px; border-radius: 8px; background: rgba(0,0,0,0.05); color: var(--gray-500); }
.column-cards { flex: 1; overflow-y: auto; padding: 2px 10px 10px; display: flex; flex-direction: column; gap: 7px; }
.column-drop-hint {
  text-align: center; padding: 20px 8px; color: var(--gray-400);
  font-size: 12px; font-weight: 500; border: 2px dashed rgba(0,0,0,0.06);
  border-radius: 10px; margin: 2px 0;
}

/* Card */
.card {
  background: rgba(255,255,255,0.8); backdrop-filter: blur(8px);
  border: 1px solid rgba(0,0,0,0.06); border-radius: 10px;
  padding: 10px; cursor: grab; position: relative;
  box-shadow: 0 1px 4px rgba(0,0,0,0.04);
  transition: all var(--transition-smooth);
  animation: card-in 0.35s cubic-bezier(0.22, 0.61, 0.36, 1);
}
@keyframes card-in { from { opacity: 0; transform: translateY(12px) scale(0.96); } to { opacity: 1; transform: translateY(0) scale(1); } }
.card:hover { box-shadow: 0 8px 24px rgba(0,0,0,0.08); transform: translateY(-2px); border-color: rgba(0,0,0,0.1); }
.card:active { cursor: grabbing; transform: scale(0.98); }
.card--dragging { opacity: 0.5; transform: scale(0.95); }
.card-name { font-size: 13px; font-weight: 620; color: var(--gray-900); margin-bottom: 2px; }
.card-meta { display: flex; flex-wrap: wrap; gap: 4px; margin-bottom: 5px; }
.card-tag { font-size: 10px; font-weight: 550; padding: 2px 6px; border-radius: 5px; display: inline-flex; align-items: center; gap: 2px; }
.card-tag--bank { background: rgba(52,199,89,0.1); color: #248A3D; }
.card-tag--id   { background: rgba(0,122,255,0.08); color: #0056B3; }
.card-tag--note { background: rgba(255,149,0,0.1); color: #C45500; }
.card-actions {
  position: absolute; top: 6px; right: 6px; display: flex; gap: 3px;
  opacity: 0; pointer-events: none; transition: opacity var(--transition-fast);
}
.card:hover .card-actions { opacity: 1; pointer-events: auto; }
.card-action {
  height: 22px; width: 22px; display: flex; align-items: center; justify-content: center;
  border: none; border-radius: 6px; font-size: 11px; font-weight: 550;
  cursor: pointer; transition: all var(--transition-fast);
  color: var(--gray-500); background: transparent; flex-shrink: 0;
}
.card-action:hover { background: rgba(0,0,0,0.06); color: var(--gray-900); }
.card-action--delete { color: var(--red); }
.card-action--delete:hover { background: var(--red-light); }
.card-time { font-size: 10px; color: var(--gray-400); font-weight: 500; margin-top: 3px; }

/* Copy Bar */
.card-copy-bar {
  display: flex; align-items: center; justify-content: space-between;
  padding: 6px 10px; margin: 6px 0 2px;
  background: rgba(52,199,89,0.08); border: 1px solid rgba(52,199,89,0.2);
  border-radius: 8px; cursor: pointer; transition: all var(--transition-fast); gap: 6px;
}
.card-copy-bar:hover { background: rgba(52,199,89,0.15); border-color: rgba(52,199,89,0.35); }
.card-copy-text { font-size: 11px; font-weight: 550; color: #1D1D1F; white-space: nowrap; overflow: hidden; text-overflow: ellipsis; }
.card-copy-icon { font-size: 13px; flex-shrink: 0; opacity: 0.6; }
.card-copy-bar:hover .card-copy-icon { opacity: 1; }

/* Modal */
.modal-overlay {
  position: fixed; inset: 0; background: rgba(0,0,0,0.3);
  backdrop-filter: blur(6px); z-index: 100;
  display: flex; align-items: center; justify-content: center;
  animation: fade-in 0.2s ease;
}
@keyframes fade-in { from { opacity: 0; } to { opacity: 1; } }
.modal {
  background: rgba(255,255,255,0.92); backdrop-filter: blur(32px);
  border: 1px solid rgba(255,255,255,0.8); border-radius: 24px;
  width: 520px; max-width: 94vw; max-height: 88vh;
  box-shadow: 0 24px 80px rgba(0,0,0,0.18);
  display: flex; flex-direction: column; overflow: hidden;
  animation: modal-in 0.35s cubic-bezier(0.22, 0.61, 0.36, 1);
}
@keyframes modal-in { from { opacity: 0; transform: translateY(24px) scale(0.94); } to { opacity: 1; transform: translateY(0) scale(1); } }
.modal-header { display: flex; align-items: center; justify-content: space-between; padding: 20px 24px 0; flex-shrink: 0; }
.modal-title { font-size: 18px; font-weight: 680; color: var(--gray-900); }
.modal-close {
  width: 30px; height: 30px; border: none; border-radius: 50%;
  background: rgba(0,0,0,0.05); color: var(--gray-500);
  font-size: 16px; cursor: pointer; display: flex; align-items: center; justify-content: center;
}
.modal-body { padding: 20px 24px; overflow-y: auto; flex: 1; display: flex; flex-direction: column; gap: 16px; }
.modal-footer { padding: 16px 24px; display: flex; gap: 10px; justify-content: flex-end; border-top: 1px solid rgba(0,0,0,0.05); flex-shrink: 0; }

/* Form */
.form-group { display: flex; flex-direction: column; gap: 5px; }
.form-label { font-size: 12px; font-weight: 600; color: var(--gray-600); text-transform: uppercase; letter-spacing: 0.02em; }
.form-input, .form-select, .form-textarea {
  height: 40px; padding: 0 14px; background: rgba(0,0,0,0.02);
  border: 1px solid rgba(0,0,0,0.1); border-radius: 10px;
  font-size: 14px; font-family: inherit; color: var(--gray-900); outline: none;
  transition: all var(--transition-fast);
}
.form-select { cursor: pointer; appearance: none; padding-right: 36px; }
.form-input:focus, .form-select:focus {
  border-color: rgba(0,122,255,0.35); box-shadow: 0 0 0 3px rgba(0,122,255,0.08);
  background: rgba(255,255,255,0.8);
}
.form-row { display: grid; grid-template-columns: 1fr 1fr; gap: 12px; }

/* Toast */
.toast-container { position: fixed; top: 24px; right: 24px; z-index: 200; display: flex; flex-direction: column; gap: 8px; }
.toast {
  padding: 12px 20px; background: rgba(255,255,255,0.92); backdrop-filter: blur(24px);
  border: 1px solid rgba(0,0,0,0.08); border-radius: 14px;
  font-size: 13px; font-weight: 550; color: var(--gray-900);
  box-shadow: 0 8px 32px rgba(0,0,0,0.10);
  animation: toast-in 0.4s cubic-bezier(0.22, 0.61, 0.36, 1);
  display: flex; align-items: center; gap: 8px; min-width: 240px;
}
@keyframes toast-in { from { opacity: 0; transform: translateX(40px); } to { opacity: 1; transform: translateX(0); } }
.toast--success { border-left: 3px solid var(--green); }
.toast--info { border-left: 3px solid var(--blue); }

@media (max-width: 768px) {
  .kanban { overflow-x: auto; }
  .column { flex: 0 0 260px; min-width: 260px; }
  .form-row { grid-template-columns: 1fr; }
}
</style>
</head>
<body>
<div class="bg-orb bg-orb--1"></div>
<div class="bg-orb bg-orb--2"></div>
<div class="bg-orb bg-orb--3"></div>

<div class="app">
  <header class="header">
    <div class="header-left">
      <div class="header-logo">抖</div>
      <div class="header-title">抖店注册追踪</div>
    </div>
    <div class="header-right">
      <div class="search-wrap">
        <input type="text" class="search-input" id="searchInput" placeholder="搜索客户姓名…">
      </div>
      <button class="btn btn--icon" onclick="exportData()" title="导出">⬇</button>
      <button class="btn btn--ghost" onclick="copyAdvanceList()">💰 预付名单</button>
      <button class="btn btn--primary" onclick="openAddModal()">+ 新增客户</button>
    </div>
  </header>
  <div class="stats-strip" id="statsStrip"></div>
  <div class="kanban" id="kanban"></div>
</div>

<div id="modalContainer"></div>
<div class="toast-container" id="toastContainer"></div>

<script>
const STAGES = [
  { id: 0, key: 'collect',  label: '资料名单', icon: '📋', color: '#007AFF', bg: 'rgba(0,122,255,0.08)' },
  { id: 1, key: 'review',   label: '审核名单', icon: '🔍', color: '#FF9500', bg: 'rgba(255,149,0,0.08)' },
  { id: 2, key: 'licensed', label: '已出证',   icon: '🏢', color: '#34C759', bg: 'rgba(52,199,89,0.08)' },
  { id: 3, key: 'qr_done',  label: '已扫码',   icon: '📱', color: '#AF52DE', bg: 'rgba(175,82,222,0.08)' },
  { id: 4, key: 'done',     label: '已完结',   icon: '🎉', color: '#8E8E93', bg: 'rgba(142,142,147,0.08)' },
];

const STORAGE_KEY = 'doudian_clients';
function loadClients() { try { return JSON.parse(localStorage.getItem(STORAGE_KEY)) || []; } catch { return []; } }
function saveClients(c) { localStorage.setItem(STORAGE_KEY, JSON.stringify(c)); }

let clients = loadClients();
let activeFilter = null, searchQuery = '', draggedClientId = null, dragHappened = false;

function genId() { return 'c_' + Date.now().toString(36) + '_' + Math.random().toString(36).slice(2, 8); }
function formatTime(ts) { /* ... relative time formatting ... */ }
function stageCount(id) { return clients.filter(c => c.stage === id).length; }
function totalCount() { return clients.length; }

function toast(msg, type) { /* ... glass toast notification ... */ }

// ── Modal ──
function openAddModal() { /* renders modal form, saves new client */ }
function openEditModal(clientId) { /* renders modal with existing data, saves edits */ }
function renderModal({ title, client, onSave }) { /* generates modal HTML with form fields */ }
function closeModal() { document.getElementById('modalContainer').innerHTML = ''; }

// ── Actions ──
function moveClient(clientId, toStage) {
  // Updates stage, auto-sets issueDate when moved to stage 2 (已出证)
  // No toast notification
}
function deleteClient(clientId) {
  // Direct delete, no confirmation dialog
  clients = clients.filter(c => c.id !== clientId);
  saveClients(clients); refreshAll();
}

// ── Copy ──
function copyOneText(text) { navigator.clipboard.writeText(text); }
function copyIssueText() {
  // Collects all stage-2 clients, formats: "7.7 张三 单个体 一类 已出"
  // If licenseType includes "自带", omits "已出"
}
function copyAdvanceList() {
  // Collects all stage-3 clients, formats: "张三 预支30 未收" or "李四 🈚️预支 未收"
}

// ── Export ──
function exportData() { /* exports CSV via Blob download */ }

// ── Filter ──
function setFilter(stageId) { activeFilter = (activeFilter === stageId) ? null : stageId; refreshAll(); }

// ── Render ──
function renderStats() { /* renders stat pills with counts */ }
function renderKanban() {
  // Renders columns with drag/drop handlers
  // Stage 2 column header gets "📋 复制" button
  // Stage 3 column header gets "💰 预付" button
}
function renderCard(c) {
  // Renders card with tags (license type, card type, advance, notes)
  // Stage 2 cards get green copyable text bar
  // Card has only delete button (✕) in top-right corner
  // Click → edit, Drag → move stage
}

// ── Drag & Drop ──
function handleDragStart(e) { /* ... */ }
function handleDragEnd(e) { dragHappened = true; /* ... */ }
function handleCardClick(id) { if (!dragHappened) openEditModal(id); }
function handleDragOver(e) { /* ... */ }
function handleDrop(e) { moveClient(clientId, stageId); }

function refreshAll() { renderStats(); renderKanban(); }

// ── Init ──
// Migration (9-stage → 5-stage) runs once via localStorage flag
// Demo data (8 clients) fills if clients array is empty
refreshAll();
</script>
</body>
</html>
```
