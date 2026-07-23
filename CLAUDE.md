# 项目上下文

## 这是什么
单文件看板应用 `index.html`，用于追踪抖店客户注册进度。公司名"信拓"。

## 技术栈
- 纯前端：HTML + CSS + Vanilla JS，无框架
- 后端：Supabase REST API（数据操作） + Supabase JS SDK v2（认证）
- 部署：GitHub Pages

## 重要规则
1. 永远不要用 `transition: all` — 会导致组件跳动，只过渡具体属性
2. 数据映射必须包含 `user_id: r.user_id`
3. 编辑保存用 `refreshAll([oldStage, newStage])` 刷新两列
4. 同步时用 `c.user_id || currentUser` 保留原始归属
5. 管理员逻辑检查 `isAdmin`（全局变量）或 `document.body.is-admin` class
6. 弹窗用 `position:fixed` + `document.body` 挂载，避免被遮挡
7. 自定义下拉用 `mousedown` 捕获阶段关闭
8. 主账号判断用 `role === 'owner'`，代码中不存在 `SUPER_ADMIN` 常量
9. 审批轮询间隔是 **8秒**（`setInterval(..., 8000)`），非5秒
10. 预付金额上限 **200**（`Math.min(200, v)`）
11. 密码由 Supabase Auth 管理，客户端不存储密码哈希
12. 退出同步重试3次，失败才确认弹窗

## 关键全局变量
- `clients` — 客户数组
- `currentUser` — 当前登录邮箱
- `isAdmin` — 是否管理员
- `isSuperAdmin` — 是否主账号（role=owner）
- `window._viewingUser` — 管理员当前查看的用户（null=全部）
- `window._nicks` — 昵称映射 `{phone: nickname}`
- `window._adminUsers` — 用户列表 `[{phone, label}]`
- `activeFilter` — 当前阶段筛选（null=全部）
- `searchQuery` — 搜索关键词
- `window._compactView` — 胶囊视图状态

## 当前功能和方向
- 登录页 + 邮箱密码认证（邮箱前缀 + 域名下拉）
- 管理员审批新用户 + 密码重置
- 每个用户独立数据（user_id 隔离）
- 管理员可查看所有用户数据、设置昵称、切换视图
- 归属用户编辑（管理员可指定客户归谁）
- Apple 风格 UI（白卡片弹窗、自定义下拉、骨架屏）
- 胶囊视图切换（FLIP 动画）
- 已完结复制文本（按时间排序算套数）
- 回收站 + 撤销删除

## 未来可做
- 批量导入导出
- 数据统计图表
- 真正的权限管理

## 近期新增功能（2026-07-16）

### 权限管理弹窗重构
- 移除行内按钮（设为管理员/删除），改为 Badge + `•••` 更多按钮
- 角色 Badge：管理员蓝色背景浅蓝字，普通用户灰色背景灰字
- `•••` 按钮点击后弹出子菜单（角色切换 + 删除），紧贴按钮右侧定位
- 子菜单超出屏幕时自动翻转到左侧
- 点击同一个 `•••` 关闭子菜单，点击其他 `•••` 切换高亮
- 角色切换/删除操作采用 inline DOM 更新，不重建整个弹窗，无闪烁
- 子菜单关闭逻辑：点击外部、滚动列表、点击同一按钮均正确关闭

### 修改密码弹窗样式优化
- 输入框从 `form-input` 灰色方块改为底线风格（和修改昵称一致）
- 无边框、`border-bottom:1px solid rgba(0,0,0,.15)`、`padding:6px 0`
- 按钮文案从"确认"改为"保存"，统一风格

### 权限管理弹窗滚动修复
- 修复：menu 容器自身设置了 `overflow-y:auto`，导致标题和关闭按钮跟着滚动
- 修复：在用户列表外层添加独立滚动容器 `max-height:160px;overflow-y:auto`
- 标题和关闭按钮固定在滚动区域外

### 新增全局变量
- `_activeRoleBtn` — 记录当前高亮的 `•••` 按钮
- `showRoleMenu(btn, phone, isAdminStr)` — 弹出角色操作子菜单
- `closeRoleActionMenu()` — 关闭子菜单并恢复按钮高亮
- `applyRoleChange(phone, makeAdmin)` — 内联更新角色（不重建弹窗）
- `applyDelete(phone)` — 内联删除用户行（不重建弹窗）

## 近期新增功能（2026-07-17）

### 紧凑行居中对齐（Excel 风格）
- 已完结阶段的 `.cc-info`（执照类型）和 `.cc-name`（姓名）原本用 `.card-compact-row--done` 做居中
- 改为 `.card-compact-row` 选择器，让**所有阶段**的执照类型和姓名都居中
- CSS 规则：`.card-compact-row .cc-info { text-align:center; }` + `.card-compact-row .cc-name { text-align:center; }`

### cc-info 固定列宽
- `.compact-mode .cc-info` 从 `flex:1; max-width:80px` 改为 `flex:0 1 64px; min-width:0; width:64px`
- 目的：让 cc-info 成为固定宽度的列，`text-align:center` 在固定宽度内居中，所有行的执照类型位置对齐
- 防止 flex:1 导致有备注和无备注时 cc-info 宽度不同，居中位置不一致
- `flex:0 1` 允许在空间不够时收缩，防止 ✕ 被挤出卡片

### 移动端复制图标位置优化（计划中）
- 需要移除 `.compact-mode .cc-del` 的 `margin-left:auto`，让 `.cc-status`（复制图标）独占右边
- 移除 line 1055 的移动端 always-visible 覆盖
- 改为双击显示 ✕：修改 `handleCardClick` 用 280ms 延迟区分单击/双击

### 紧凑行布局关键 CSS
- `.cc-date` — 28px 固定，居中
- `.cc-name` — 44px 固定，居中
- `.cc-info` — 64px 固定，居中（flex:0 1 64px 允许收缩）
- `.cc-notes` — 44px 固定
- `.cc-status` — margin-left:auto 推到最右
- `.cc-del` — 默认隐藏，双击显示

## Bug 修复记录（续）

17. **修改密码弹窗输入框风格不匹配** — 从 `form-input` 灰色方块改为底线风格
18. **权限管理弹窗标题和关闭按钮可滚动** — menu 容器移除 `overflow-y:auto`，列表独立滚动
19. **权限管理弹窗按钮样式丑** — 改为 Badge + `•••` 更多按钮 + 子菜单模式
20. **紧凑行执照类型居中只对已完结生效** — 从 `.card-compact-row--done` 改为 `.card-compact-row`，所有阶段统一居中
21. **紧凑行执照类型位置不对齐** — cc-info 从 flex:1 改为固定 64px 列宽，所有行位置一致
22. **有备注的列 ✕ 被挤掉** — cc-info 改为 flex:0 1 64px 允许收缩，防止溢出裁剪
