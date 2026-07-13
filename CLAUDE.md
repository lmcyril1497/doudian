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
