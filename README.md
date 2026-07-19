# 信拓 · 抖店 — 客户注册进度追踪系统

## 项目概述

单文件 Web 应用（`index.html`），用于追踪抖店客户注册进度。支持多人协作、云端同步、管理员审批。Apple 风格 UI 设计。

**域名**: https://lmcyril1497.github.io/doudian/  
**本地测试**: `http://localhost:8080/index.html`

---

## 技术栈

| 层级 | 技术 |
|------|------|
| 前端 | HTML + CSS + Vanilla JS（无框架） |
| 后端 | Supabase REST API（直连，无 SDK） |
| 数据库 | Supabase PostgreSQL |
| 部署 | GitHub Pages |
| 图标 | 内嵌 SVG（Lucide 风格） |

---

## 数据模型

### clients 表（客户数据）
```
id, user_id, name, licenseType, cardType, advanceAmount, notes, stage, createdAt, stageTimestamps
```

### users 表（用户账号）
```
phone, password_hash, status, role, nickname, reset_requested
```

### 5 个阶段
| 0 | 资料名单 | 1 | 已签字 | 2 | 已出证 | 3 | 已扫码 | 4 | 已完结 |

---

## 功能清单

### 客户管理
- 新增/编辑/删除客户
- 拖拽卡片切换阶段
- 搜索客户姓名
- 阶段筛选（统计标签栏）
- 卡片显示：姓名、标签、复制栏、日期、归属人

### 出证复制
- 批量复制：已出证列头按钮，按审核日期排序
- 单条复制：卡片内绿色复制栏
- 格式：`7.3 苏辉鑫 单个体 二类 已出`
- 自带电子执照省略"已出"后缀

### 预付结算
- 已扫码列头"结算"按钮
- 格式：`张三 预支30 未收` / `张三 🈚️预支 未收`

### 已完结
- 卡片显示：`张三完结 7月完结3套`
- 按完成时间降序排列

### 用户系统
- 手机号 + 密码登录
- 首次登录自动注册（待审批）
- 管理员审批新用户
- 每个用户独立数据（user_id 隔离）
- 退出登录清空本地数据

### 管理员功能
- 用户审批（通过/拒绝）
- 密码重置（用户申请 → 管理员重置为 123456）
- 设置昵称（为每个手机号设置显示名）
- 数据总览（查看所有用户的客户统计）
- 归属用户（编辑时指定客户归属谁）
- 全部/用户切换（筛选查看不同用户的数据）

### 数据同步
- 登录时自动上传本地数据到云端
- 保存/编辑/删除/拖拽即时同步
- 刷新页面拉取最新云端数据
- 每个操作保留原始 user_id，不覆盖

### UI/UX
- Apple 风格登录页
- 骨架屏加载动画
- 毛玻璃导航栏
- 白卡片弹窗 + 弹出菜单
- 浮动标签输入框（登录页）
- 自定义下拉选择器
- 日期滚轮选择器
- 移动端自适应（底部 Sheet、横向卡片滚动）
- 搜索图标按钮（手机端）
- 退出确认对话框

---

## CSS 设计系统

### 颜色
- 主色：`#667eea` → `#764ba2`（紫蓝渐变）
- 文字：`rgba(0,0,0,0.85)` / `0.55` / `0.28`
- 背景：`#f5f5f7`
- 卡片：`#fff` + `box-shadow: 0 4px 24px rgba(0,0,0,.12)`

### 圆角
- 按钮/标签：`980px`（胶囊）
- 卡片：`18px`
- 弹窗：`14px`
- 输入框：`10px`

### 动画
- `cubic-bezier(0.25, 0.1, 0.25, 1)` — Apple 缓动
- `cubic-bezier(0.22, 0.61, 0.36, 1)` — Spring 弹性

### 响应式
| 断点 | 布局 |
|------|------|
| >1260px | 5 列平铺 |
| 1024px | 列收窄 |
| 768px | 纵向堆叠，底部 Sheet |
| 400px | 紧凑 |

---

## Bug 修复记录

1. **已出证同日排序错乱** — `stageTimestamps[2]` tiebreaker 放在 `if(ad2 !== bd2)` 内，移到外面
2. **复制功能在 http 下失败** — 添加 fallback `execCommand('copy')` + 可见 textarea
3. **撤销删除不生效** — `undoCallback.toString()` 丢失闭包变量，改用字符串拼接 `clientId`
4. **编辑后页面滚动重置** — 保存前后记住/恢复 `window.scrollY`
5. **iOS 键盘顶飞页面** — 局部 `position:fixed` body，关闭后恢复 `scrollTo`
6. **▼ 箭头飞回** — `.form-select` `transition:all` 导致 `background-position` 动画，改为只过渡特定属性
7. **组件跳动** — 卡片 `transition:all` 导致全部重绘，改为只过渡 `box-shadow` + `transform`
8. **刷新全量重建卡片** — 添加 targeted refresh（只重建变化的列），`updateCardContent` 原地更新
9. **Lucide CDN 被墙** — 全部改为内嵌 SVG
10. **管理员切换用户数据合并** — `syncToCloud` 使用原始 `c.user_id` 而非覆盖
11. **新增客户无标签不更新** — `updateCardContent` 新增创建 `card-meta` div 逻辑
12. **切换阶段旧列残留** — `refreshAll([oldStage, newStage])` 同时刷新两列
13. **登录页缓存旧视图** — 登录时重置 `dou_view`，退出时清空
14. **搜索图标桌面端误显** — `.btn--search-toggle` 改用 `!important` + `max-width:768px`
15. **自定义下拉不关闭** — 改用 `mousedown` 捕获阶段 + `position:fixed` + `document.body` 挂载
16. **资料日期弹窗被遮挡** — CSS 冲突 `.dp-popup` 定位被覆盖，清除样式表定位

---

## 关键函数

### 数据层
`loadClients()`, `saveClients()`, `syncToCloud()`, `sbFetch()`, `sbHead()`, `loadLocalTrash()`, `saveTrash()`

### 渲染
`renderKanban(stageIds)`, `renderCard(c)`, `updateCardContent(card, c)`, `renderStats()`, `refreshAll(stageIds)`

### 登录/用户
`handleLogin()`, `showAuthModal()`, `showChangePassModal()`, `showResetPwd()`, `showNicknameModal()`, `saveNicknames()`

### 管理员
`showAdminPanel()`, `approveUser()`, `resetUserPwd()`, `initAdminSelect()`, `switchToUserView(phone)`

### 客户操作
`openAddModal()`, `openEditModal()`, `deleteClient()`, `moveClient()`, `renderModal()`

### 复制
`copyToClipboard()`, `fallbackCopy()`, `copyIssueText()`, `copyAdvanceList()`, `copyOneText()`

### 拖拽
`handleDragStart()`, `handleDrop()`, `handleCardClick()`

### 搜索
`toggleSearch()`, `closeSearch()`

### 工具
`dpToggle()`, `getNick()`, `formatReviewDate()`, `parseReviewDate()`, `escHtml()`, `escAttr()`

---

## 部署说明

1. 代码推送到 GitHub → GitHub Pages 自动部署
2. Supabase 云端数据库，无需维护
3. 本地双击 `启动抖店.bat` 或 `python -m http.server 8080`
4. 手机和电脑同 WiFi，访问 `http://电脑IP:8080/index.html`

## 数据备份

- 云端数据：Supabase 自动备份
- 本地导出：打开页面 → F12 Console → `sbFetch('clients','GET').then(d=>copy(JSON.stringify(d)))`

---

## 近期功能更新（2026-07-16）

### 权限管理弹窗重构
- 移除行内操作按钮，改为 Badge + `•••` 更多按钮
- 角色 Badge：管理员蓝色背景浅蓝字，普通用户灰色背景灰字
- `•••` 按钮点击后弹出子菜单（角色切换 + 删除），紧贴按钮右侧定位
- 子菜单超出屏幕时自动翻转
- 操作采用 inline DOM 更新，不重建弹窗，无闪烁
- 修改密码弹窗输入框改为底线风格，与修改昵称统一

### 新增函数
- `showRoleMenu(btn, phone, isAdminStr)` — 弹出角色操作子菜单
- `closeRoleActionMenu()` — 关闭子菜单并恢复按钮高亮
- `applyRoleChange(phone, makeAdmin)` — 内联更新角色（不重建弹窗）
- `applyDelete(phone)` — 内联删除用户行（不重建弹窗）

### Bug 修复
17. 修改密码弹窗输入框风格不匹配 — 改为底线风格
18. 权限管理弹窗标题和关闭按钮可滚动 — 列表独立滚动
19. 权限管理弹窗按钮样式优化 — Badge + `•••` 子菜单模式
