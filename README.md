# 抖店注册追踪 — 代码文档

## 项目概述

单文件看板应用（`index.html`），用于追踪抖店（抖音商店）客户注册进度。采用 Apple 设计风格，支持桌面端和移动端。

**文件**: `D:\demo\index.html`

---

## 数据模型

```javascript
client = {
  id: "c_xxx",              // 唯一ID (genId)
  name: "张三",              // 客户姓名
  licenseType: "单个体",     // 执照类型
  cardType: "一类",          // 银行卡类型
  advanceAmount: "30",      // 预付金额
  notes: "备注",            // 备注
  stage: 2,                 // 当前阶段 (0-4)
  createdAt: 1700000000000, // 审核日期 (时间戳)
  stageTimestamps: {        // 进入各阶段的时间戳
    0: 1700000000000,
    1: 1700000001000,
    2: 1700000002000,
  }
}
```

**存储**: `localStorage`  
- `doudian_clients` — 客户数据
- `doudian_trash` — 回收站数据

---

## 5 个阶段

| ID | Key | 标签 | 颜色 |
|---|---|---|---|
| 0 | `review` | 资料名单 | `#FF9500` 橙 |
| 1 | `signed` | 已签字 | `#3B82F6` 蓝 |
| 2 | `licensed` | 已出证 | `#34C759` 绿 |
| 3 | `qr_done` | 已扫码 | `#AF52DE` 紫 |
| 4 | `done` | 已完结 | `#8E8E93` 灰 |

---

## 核心功能

### 看板 (Kanban)
- **桌面端**: 5 列横向平铺，列内卡片纵向排列
- **移动端**: 列纵向堆叠，卡片横向滑动（scroll-snap）
- **拖拽**: HTML5 Drag & Drop，拖动卡片到其他列推进阶段
- **拖拽影像**: Apple 胶囊形毛玻璃浮层

### 客户管理
- **新增**: 弹窗表单，自动填入当天审核日期
- **编辑**: 点击卡片编辑，支持修改所有字段
- **删除**: 软删除到回收站，支持撤销恢复
- **搜索**: 按姓名实时过滤
- **筛选**: 统计标签栏点击切换阶段视图

### 出证复制 (核心功能)
- **批量复制**: 已出证列头「复制」按钮，按审核日期排序
- **单条复制**: 卡片底部绿色复制栏，点击复制一行
- **格式**: `7.3 张三 单个体 一类 已出`（自带电子执照时不显示"已出"）
- **排序**: 按 `createdAt`（审核日期）升序，同日按进入已出证时间排序

### 预付结算
- **复制**: 已扫码列头「结算」按钮
- **格式**: `张三 预支30 未收` / `张三 🈚️预支 未收`

### 已完结
- **复制**: 卡片底部显示「张三完结 7月完结3套」
- **排序**: 按完成时间降序排列

### 日期选择器
- **桌面端**: 自定义弹窗，向上展开，纯数字选项
- **移动端**: 原生 `<select>`（iOS 滚轮）
- **默认值**: 新增时默认当天日期

---

## 函数清单

### 数据层
| 函数 | 说明 |
|---|---|
| `loadClients()` | 从 localStorage 加载 |
| `saveClients(arr)` | 保存到 localStorage |
| `loadTrash()` | 加载回收站 |
| `saveTrash(arr)` | 保存回收站 |
| `genId()` | 生成唯一ID `c_xxx` |
| `refreshAll()` | 刷新统计+看板 |

### 日期工具
| 函数 | 说明 |
|---|---|
| `formatReviewDate(ts)` | 时间戳 → "M.D" 格式 |
| `parseReviewDate(str)` | "M.D" → 时间戳 |
| `formatTime(ts)` | 时间戳 → "刚刚/n分钟前/M/D HH:MM" |

### 弹窗
| 函数 | 说明 |
|---|---|
| `openAddModal()` | 新增客户弹窗 |
| `openEditModal(id)` | 编辑客户弹窗 |
| `renderModal(opts)` | 渲染弹窗表单 |
| `closeModal()` | 关闭弹窗（淡出动画） |
| `confirmDialog(msg, cb)` | 确认对话框 |
| `toggleHelp()` | 快捷键帮助面板 |

### 客户操作
| 函数 | 说明 |
|---|---|
| `moveClient(id, stage)` | 移动客户到指定阶段 |
| `deleteClient(id)` | 软删除客户 |
| `restoreFromTrash(id)` | 从回收站恢复 |
| `clearTrash()` | 清空回收站 |

### 复制
| 函数 | 说明 |
|---|---|
| `copyToClipboard(text, msg)` | 通用复制（Clipboard API + fallback） |
| `fallbackCopy(text, msg)` | 移动端兼容的 fallback 复制 |
| `copyOneText(text)` | 单条复制 |
| `copyIssueText()` | 批量复制已出证 |
| `copyAdvanceList()` | 批量复制预付名单 |

### 渲染
| 函数 | 说明 |
|---|---|
| `renderKanban()` | 渲染看板（含滚动位置保存/恢复） |
| `renderCard(c)` | 渲染单个卡片 |
| `renderStats()` | 渲染统计标签栏 |

### 拖拽
| 函数 | 说明 |
|---|---|
| `handleDragStart(e)` | 拖拽开始（创建自定义拖拽影像） |
| `handleDragEnd(e)` | 拖拽结束 |
| `handleDragOver(e)` | 拖拽经过列 |
| `handleDragLeave(e)` | 拖拽离开列 |
| `handleDrop(e)` | 放置 |
| `handleCardClick(id)` | 卡片点击（编辑） |

### 回收站
| 函数 | 说明 |
|---|---|
| `openTrash()` | 打开回收站弹窗 |
| `closeTrash()` | 关闭回收站 |

### 日期选择器
| 函数 | 说明 |
|---|---|
| `dpToggle(btn)` | 桌面端日期选择弹窗 |

### 其他
| 函数 | 说明 |
|---|---|
| `setFilter(stageId)` | 阶段筛选 |
| `exportData()` | 导出 CSV |
| `toast(msg, type, undo)` | Toast 通知 |
| `escAttr(s)` / `escHtml(s)` | XSS 防护 |

---

## CSS 设计系统

### 颜色体系（Apple 风格）
- **蓝色**: `#0071E3` — 主色调（按钮、选中态）
- **文字色**: 基于透明度 `rgba(0,0,0,0.85/0.55/0.28)` — Apple 做法
- **填充色**: `rgba(0,0,0,0.06/0.04/0.02)` — 细微背景
- **毛玻璃**: 5 级材质（UltraThin → UltraThick）

### 间距
| 变量 | 值 | 用途 |
|---|---|---|
| `--page-padding` | 40px | 页面左右边距 |
| `--content-gap` | 20px | 列间距 |
| `--btn-height` | 34px | 桌面按钮高度 |
| `--touch-target` | 44px | 移动端最小触控 |

### 圆角
| 变量 | 值 | 用途 |
|---|---|---|
| `--radius-sm` | 8px | 小元素 |
| `--radius-md` | 12px | 输入框、弹窗选项 |
| `--radius-lg` | 18px | 卡片 |
| `--radius-xl` | 22px | 列、Modal |
| `--radius-pill` | 980px | 胶囊按钮、统计标签 |

### 动画曲线
| 变量 | 用途 |
|---|---|
| `--ease-apple` | 常规过渡（0.25, 0.1, 0.25, 1） |
| `--spring-smooth` | 弹窗出入（0.22, 0.61, 0.36, 1） |

### 响应式断点
| 断点 | 设备 | 布局 |
|---|---|---|
| >1260px | 桌面 | 5列平铺 |
| 1024px | 平板 | 列收窄 |
| 768px | 手机 | 纵向堆叠，底部Sheet |
| 400px | 小手机 | 极限紧凑 |

---

## 重要 Bug 修复记录

1. **已出证排序**: `renderKanban` 中同日排序的 timestamp tiebreaker 被错误放在 `if(ad2 !== bd2)` 内 → 移到外面
2. **复制不可用**: `navigator.clipboard` 需要安全上下文，移动端 fallback 用 `execCommand('copy')` + 可见 textarea
3. **撤销按钮**: `undoCallback.toString()` 丢失闭包变量 `clientId` → 改用字符串拼接
4. **编辑后滚动重置**: 保存弹窗前后记住/恢复 `window.scrollY`
5. **键盘顶页面**: iOS 键盘弹起时 `position: fixed` body → 恢复滚动位置
6. **▼ 箭头飞回**: `.form-select` 的 `transition: all` 导致 `background-position` 动画 → 改为只过渡 `border-color/box-shadow/background-color`

---

## 复制格式速查

```
已出证:  {日期} {姓名} {执照类型} {银行卡类型} 已出
        例: 7.3 苏辉鑫 单个体 二类 已出

自带执照: {日期} {姓名} {自带电子执照} {银行卡类型}
        例: 7.5 李四 自带电子执照 一类

预付:   {姓名} 预支{金额} 未收
        例: 张三 预支30 未收

完结:   {姓名}完结 {月}月完结{套数}套
        例: 张三完结 7月完结3套
```
