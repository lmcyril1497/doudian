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
| 后端 | Supabase REST API（数据操作） + Supabase JS SDK v2（认证） |
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

## 权限体系（v2.0）

| 级别 | 标识 | 权限 |
|------|------|------|
| 主账号 (SUPER_ADMIN) | 橙标 "主账号" | 权限管理（设/撤管理员、删除用户）、用户审批、管理全部客户 |
| 管理员 (admin) | 紫标 "管理员" | 用户审批、设置昵称、管理全部客户 |
| 普通用户 (user) | 无标签 | 修改昵称、管理自己的客户 |

### 主账号
- 判断方式：数据库 `role === 'owner'`，代码中通过 `isSuperAdmin` 全局变量控制
- 登录时设置 `isSuperAdmin`，刷新后从 localStorage `dou_super` 恢复
- 用户菜单显示"权限管理"入口 → `showRolePanel()`

### 权限管理面板
- 从 `authBtn` 弹出的浮层菜单，列出已审批用户（排除主账号自己）
- 每个用户：头像 + 昵称/邮箱 + 角色 Badge（管理员蓝色 / 普通用户灰色）+ `•••` 更多按钮
- `•••` 点击弹出子菜单：设为管理员/取消管理员 + 删除用户
- 子菜单超出屏幕时自动翻转到左侧
- 角色切换/删除操作采用 inline DOM 更新，不重建整个弹窗，无闪烁
- 删除直接执行（`applyDelete()`），无确认弹窗

---

## 功能清单

### 客户管理
- 新增/编辑/删除客户
- 拖拽卡片切换阶段
- 搜索客户姓名
- 阶段筛选（统计标签栏）
- 卡片显示：姓名、标签、复制栏、日期、归属人
- 预付金额上限 200
- 执照类型可自定义输入（弹窗内输入框）
- 日期选择器双模式：桌面弹窗式 / 移动端原生滚轮
- 已扫码列汇总点 toggle（绿/黄圆点，控制是否参与汇总）

### 出证复制
- **单列复制**：已出证列头右侧 `复制` 按钮
- **汇总复制**：管理员在"全部"视图中，列头右侧 `汇总复制` 按钮（绿），按用户分组复制已出证数据
- 格式：`7.3 姓名 执照类型 卡类型 已出`（自带电子执照省略"已出"）
- **全用户可用**

### 预付结算
- **单列复制**：已扫码列头右侧 `结算` 按钮（紫色）
- **汇总复制**：管理员"全部"视图中，列头右侧 `汇总结算` 按钮（橙），按用户分组
- 格式：`姓名 预支XX 未收` / `姓名 🈚️预支 未收`
- **全用户可用**

### 已完结
- 卡片显示：`张三完结 7月完结3套`
- 完结复制格式：`姓名完结 X月完结N套`（按完成时间排序算套数，只算当月）
- 按完成时间降序排列

### 用户系统
- 邮箱 + 密码登录（邮箱前缀 + 域名下拉，8个域名选项：@qq.com、@163.com、@126.com、@sina.com、@foxmail.com、@gmail.com、@outlook.com、@hotmail.com）
- 密码由 Supabase Auth 管理，客户端不存储密码哈希
- 密码显示切换（眼睛图标 toggle）
- 首次登录自动注册（status=`pending`）
- 已拒绝账号重新注册时自动恢复为 pending 状态
- 管理员审批后 **自动登录**（8秒轮询）
- 心跳检测：每 5 秒检测用户是否被删除/禁用，被删后自动退出
- 退出登录：重试3次 syncToCloud，失败则确认弹窗，清空所有本地状态

### 管理员功能
- 用户审批 + 拒绝（通过/拒绝按钮，拒绝=改 status=rejected）
- 密码重置（重置为 123456，失败时提示在 Supabase Dashboard 手动操作）
- 设置昵称（管理员设所有用户 + 普通用户设自己）
- 数据总览（"全部"视图）
- 管理员筛选下拉 → 切换查看不同用户数据
- 首页标签统计栏下方独立一行 `全部 ▾` 按钮

### 回收站
- 右上角回收站图标
- 删除的客户数据保留在本地 trash 中，可恢复
- Toast 撤销：删除后5秒内可撤销
- 云端数据通过 syncToCloud 同步

### 数据同步
- **无本地缓存**（v2.0）：数据完全依赖云端同步
- 登录时从云端拉取 → 数据不通过 localStorage 传递
- 操作后即时 syncToCloud
- 每个操作保留原始 user_id，不覆盖
- 全部视图自动过滤已删除用户的客户数据

### 移动端适配
- Apple 风格底部 Sheet（`max-height: 65vh`）
- 横杠拖拽关闭（>180px → 自动滑出消失 + Apple 缓动）
- 弹窗背景虚化随拖拽渐变
- 锁定 body 滚动（弹窗打开时 `overflow: hidden`）
- 统计标签栏不换行横向滚动
- 管理员筛选按钮 `width: 58px`（固定大小，文字截断）

### UI 组件
- 自定义下拉选择器（`mousedown` 捕获阶段关闭，`position:fixed` + `document.body` 挂载）
- 日期选择器：桌面弹窗式（`dpToggle()`）/ 移动端原生滚轮（`<select>`）
- 执照类型自定义输入（弹窗内输入框，可输入非预设值）
- 搜索：桌面端输入框 / 移动端展开式
- 快捷键：Ctrl+K 搜索、Esc 关闭、? 帮助
- Toast 通知：成功/错误/信息，支持撤销按钮
- 确认弹窗（退出登录等危险操作）
- 胶囊视图切换（FLIP 动画，`localStorage('dou_compact')` 持久化）
- 汇总点 toggle（已扫码列绿/黄圆点，`overrideSummarize` + 4am 规则）

---

## 关键全局变量

| 变量 | 说明 |
|------|------|
| `clients` | 客户数组 |
| `currentUser` | 当前登录手机号 |
| `isAdmin` | 是否管理员 |
| `isSuperAdmin` | 是否主账号（role=owner） |
| `window._viewingUser` | 管理员当前查看的用户（null=全部） |
| `window._nicks` | 昵称映射 `{phone: nickname}` |
| `window._adminUsers` | 用户列表 `[{phone, label}]` |
| `activeFilter` | 当前阶段筛选（null=全部） |

---

## CSS 设计系统

| 属性 | 值 |
|------|-----|
| 主色 | `#667eea` → `#764ba2`（紫蓝渐变） |
| 文字 | `rgba(0,0,0,0.85)` / `0.55` |
| 背景 | `#f5f5f7` |
| 卡片 | `#fff` + `box-shadow: 0 4px 24px rgba(0,0,0,.12)` |
| 圆角 | 按钮/标签 `980px`，卡片 `18px`，弹窗 `14px` |
| 动画 | `cubic-bezier(0.25, 0.1, 0.25, 1)` |
| 布局列 | 5列 >1260px，纵向堆叠 <768px |

### 紧凑行布局（Compact Mode）
| 元素 | CSS 类 | 宽度 | 对齐 |
|------|--------|------|------|
| 日期 | `.cc-date` | 28px 固定 | 居中 |
| 姓名 | `.cc-name` | 44px 固定 | 居中 |
| 执照类型 | `.cc-info` | 64px 固定 | 居中 |
| 备注 | `.cc-notes` | 44px 固定 | 左对齐 |
| 复制/状态 | `.cc-status` | auto | margin-left:auto 推到最右 |
| 删除按钮 | `.cc-del` | 20px | 默认隐藏，双击显示 |

---

## 重要函数

### 数据层
`saveClients()`, `syncToCloud()`, `sbFetch()`, `sbHead()`, `mapClient()`

### 认证/用户
`handleLogin()`, `handleRegister()`, `doLogout()`, `startApprovalPoll()`, `cancelApprovalPoll()`, `refreshSession()`, `showAuthModal()`, `showResetPwd()`, `togglePassVis()`

### 管理员
`showAdminPanel()`, `approveUser()`, `rejectUser()`, `resetUserPwd()`, `showRolePanel()`, `showRoleMenu()`, `applyRoleChange()`, `applyDelete()`, `showNicknameModal()`, `saveNicknames()`, `showMyNickModal()`

### 客户操作
`openAddModal()`, `openEditModal()`, `renderModal()`, `deleteClient()`, `moveClient()`, `renderKanban()`, `renderCard()`, `updateCardContent()`

### 复制
`copyToClipboard()`, `fallbackCopy()`, `copyIssueText()`, `copyAdvanceList()`, `copyAllClients()`, `copyAllAdvance()`, `copyOneText()`

### 移动端
`openModal()`, `closeModal()`（锁定/解锁 body 滚动）、拖拽关闭（行 1671-1690）

### UI 组件
`toggleCompactView()`, `toggleHelp()`, `toggleSearch()`, `closeSearch()`, `toggleAdminFilter()`, `closeAdminFilter()`, `switchToUserView()`, `dpToggle()`, `getNick()`, `formatReviewDate()`, `parseReviewDate()`, `escHtml()`, `escAttr()`, `createPopup()`, `closeOnOutside()`, `confirmDialog()`, `toast()`

### 单击/双击区分
`handleCardClick()` — 用 280ms 延迟区分单击/双击
- 单击：延迟后打开编辑弹窗
- 双击（280ms 内第二次点击）：取消延迟，显示 ✕ 删除按钮

---

## 开发注意事项

1. **编辑 index.html 不要用 `edit_file` 或 PowerShell**：中文和特殊字符会损坏。用 Node.js 脚本文件（`D:\demo\fix_xxx.js`）+ `node D:\demo\fix_xxx.js` 执行
2. **`\u0022`** = 双引号，`\u0027` = 单引号 — 在 JS 字符串中使用 Unicode 转义避免嵌套引号问题
3. **密码由 Supabase Auth 管理**：客户端不存储密码哈希，用 SDK 的 `signInWithPassword` / `updateUser`
4. **数据加载**：init 代码中直接 fetch，无独立 `loadClients()` 函数。`saveClients()` 只调 `syncToCloud()`
5. **全部视图数据过滤**：switchToUserView 和 init 加载时过滤 `_adminUsers` 中不存在的 user_id
6. **弹窗**：`openModal()` 锁定 body，`closeModal()` 恢复 + 清理所有浮层（`.dp-popup`, `.cs-dropdown`, `.user-menu` 等）
7. **紧凑行布局**：cc-info 用 `flex:0 1 64px`（固定列宽+允许收缩），防止有备注时 ✕ 被挤出卡片
8. **紧凑行居中**：`.card-compact-row .cc-info` 和 `.card-compact-row .cc-name` 统一 `text-align:center`（Excel 风格）
9. **预付金额上限**：`Math.min(200, v)`，line 2450
10. **审批轮询间隔**：8秒（`setInterval(..., 8000)`），非5秒
11. **主账号判断**：通过数据库 `role === 'owner'` 判断，代码中不存在 `SUPER_ADMIN` 常量
12. **汇总点规则**：已扫码列绿/黄圆点，绿=可汇总（>4am 或 `overrideSummarize=true`），黄=今日不可汇总
13. **退出同步**：重试3次 `syncToCloud()`，失败才弹确认窗

---

## 部署

1. 推送代码到 GitHub → Pages 自动部署
2. Supabase 云端数据库，RLS 已禁用
3. 本地测试：`python -m http.server 8080`