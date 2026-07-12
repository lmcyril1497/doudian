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

## 权限体系（v2.0）

| 级别 | 标识 | 权限 |
|------|------|------|
| 主账号 (SUPER_ADMIN) | 橙标 "主账号" | 权限管理（设/撤管理员、删除用户）、用户审批、管理全部客户 |
| 管理员 (admin) | 紫标 "管理员" | 用户审批、设置昵称、管理全部客户 |
| 普通用户 (user) | 无标签 | 修改昵称、管理自己的客户 |

### 主账号
- 硬编码：`const SUPER_ADMIN = '18211383968'`（行 1159）
- 登录时设置 `isSuperAdmin`，刷新后从 init 代码恢复
- 用户菜单显示"权限管理"入口 → `showRolePanel()`

### 权限管理面板
- 下拉菜单风格，从 `authBtn` 弹出
- 列出已审批用户（排除主账号自己）
- 每个用户：昵称/手机号 + 管理员标签 + 设为/取消管理员 + 删除
- 删除确认：内联"确认删除？[是][否]"（不弹模态窗）

---

## 功能清单

### 客户管理
- 新增/编辑/删除客户
- 拖拽卡片切换阶段
- 搜索客户姓名
- 阶段筛选（统计标签栏）
- 卡片显示：姓名、标签、复制栏、日期、归属人

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

### 用户系统
- 手机号 + 密码登录
- 密码存储：`btoa(btoa(btoa(phone:password:xt_doudian_2024)))`（3x btoa + salt）
- 移动端全兼容（纯 JS btoa，无 `crypto.subtle` 依赖）
- 首次登录自动注册（status=`pending`）
- 管理员审批后 **自动登录**（5秒轮询）
- 心跳检测：每 5 秒检测用户是否被删除，被删后自动退出
- 退出登录清空所有本地状态

### 管理员功能
- 用户审批 + 拒绝（通过/拒绝按钮，拒绝=删除用户+清看板数据）
- 密码重置（重置为 123456）
- 设置昵称（管理员设所有用户 + 普通用户设自己）
- 数据总览（"全部"视图）
- 管理员筛选下拉 → 切换查看不同用户数据
- 首页标签统计栏下方独立一行 `全部 ▾` 按钮

### 回收站
- 右上角回收站图标
- 删除的客户数据保留在本地 trash 中，可恢复
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

---

## 关键全局变量

| 变量 | 说明 |
|------|------|
| `clients` | 客户数组 |
| `currentUser` | 当前登录手机号 |
| `isAdmin` | 是否管理员 |
| `isSuperAdmin` | 是否主账号 |
| `window._viewingUser` | 管理员当前查看的用户（null=全部） |
| `window._nicks` | 昵称映射 `{phone: nickname}` |
| `window._adminUsers` | 用户列表 `[{phone, label}]` |
| `SUPER_ADMIN` | 主账号常量 `'18211383968'` |
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

---

## 重要函数

### 数据层
`loadClients()`, `saveClients()`, `syncToCloud()`, `sbFetch()`, `sbHead()`, `mapClient()`

### 认证/用户
`handleLogin()`, `doLogout()`, `startApprovalPoll()`, `hashPassword()`, `showAuthModal()`

### 管理员
`showAdminPanel()`, `approveUser()`, `rejectUser()`, `resetUserPwd()`, `showRolePanel()`, `toggleRole()`, `deleteUser()`, `confirmDelete()`

### 客户操作
`openAddModal()`, `openEditModal()`, `deleteClient()`, `moveClient()`, `renderKanban()`, `renderCard()`

### 复制
`copyToClipboard()`, `copyIssueText()`, `copyAdvanceList()`, `copyAllClients()`, `copyAllAdvance()`

### 移动端
`openModal()`, `closeModal()`（锁定/解锁 body 滚动）、拖拽关闭（行 1244-1265）

---

## 开发注意事项

1. **编辑 index.html 不要用 `edit_file` 或 PowerShell**：中文和特殊字符会损坏。用 Node.js 脚本文件（`D:\demo\fix_xxx.js`）+ `node D:\demo\fix_xxx.js` 执行
2. **`\u0022`** = 双引号，`\u0027` = 单引号 — 在 JS 字符串中使用 Unicode 转义避免嵌套引号问题
3. **密码哈希**：纯 JS 实现，无 `crypto.subtle` 依赖。格式：`3x btoa(phone:password:xt_doudian_2024)`
4. **本地缓存已禁用**：`loadClients()` 返回 `[]`，`saveClients()` 只调 `syncToCloud()`
5. **全部视图数据过滤**：switchToUserView 和 init 加载时过滤 `_adminUsers` 中不存在的 user_id
6. **弹窗**：`openModal()` 锁定 body，`closeModal()` 恢复 + 清理所有浮层

---

## 部署

1. 推送代码到 GitHub → Pages 自动部署
2. Supabase 云端数据库，RLS 已禁用
3. 本地测试：`python -m http.server 8080`