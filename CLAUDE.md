# 项目上下文

## 这是什么
单文件看板应用 `index.html`，用于追踪抖店客户注册进度。公司名"信拓"。

## 技术栈
- 纯前端：HTML + CSS + Vanilla JS，无框架
- 后端：Supabase REST API（fetch 直连，无 SDK）
- 部署：GitHub Pages

## 重要规则
1. 永远不要用 `transition: all` — 会导致组件跳动，只过渡具体属性
2. 数据映射必须包含 `user_id: r.user_id`
3. 编辑保存用 `refreshAll([oldStage, newStage])` 刷新两列
4. 同步时用 `c.user_id || currentUser` 保留原始归属
5. 管理员逻辑检查 `isAdmin`（全局变量）或 `document.body.is-admin` class
6. 弹窗用 `position:fixed` + `document.body` 挂载，避免被遮挡
7. 自定义下拉用 `mousedown` 捕获阶段关闭

## 关键全局变量
- `clients` — 客户数组
- `currentUser` — 登录手机号
- `isAdmin` — 是否管理员
- `window._viewingUser` — 管理员当前查看的用户（null=全部）
- `window._nicks` — 昵称映射 `{phone: nickname}`
- `window._adminUsers` — 用户列表 `[{phone, label}]`

## 当前功能和方向
- 登录页 + 手机号密码认证
- 管理员审批新用户 + 密码重置
- 每个用户独立数据（user_id 隔离）
- 管理员可查看所有用户数据、设置昵称、切换视图
- 归属用户编辑（管理员可指定客户归谁）
- Apple 风格 UI（白卡片弹窗、自定义下拉、骨架屏）

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

## Bug 修复记录（续）

17. **修改密码弹窗输入框风格不匹配** — 从 `form-input` 灰色方块改为底线风格
18. **权限管理弹窗标题和关闭按钮可滚动** — menu 容器移除 `overflow-y:auto`，列表独立滚动
19. **权限管理弹窗按钮样式丑** — 改为 Badge + `•••` 更多按钮 + 子菜单模式
